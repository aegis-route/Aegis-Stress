#!/usr/bin/env bash
# ==============================================================================
#  🛡️  AEGIS-STRESS: BỘ CÔNG CỤ KIỂM THỬ XÂM NHẬP VÀ ĐÁNH GIÁ TƯỜNG LỬA HẠT NHÂN
#  Chạy trên Attacker VM (Kali Linux: 172.30.0.202) -> Target Gateway (172.30.0.101)
# ==============================================================================
set -euo pipefail

TARGET_IP="${TARGET_IP:-172.30.0.101}"
TARGET_PORT="${TARGET_PORT:-80}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "  █████╗ ███████╗ ██████╗ ██╗███████╗    ███████╗████████╗██████╗ ███████╗███████╗███████╗"
    echo " ██╔══██╗██╔════╝██╔════╝ ██║██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝"
    echo " ███████║█████╗  ██║  ███╗██║███████╗    ███████╗   ██║   ██████╔╝█████╗  ███████╗███████╗"
    echo " ██╔══██║██╔══╝  ██║   ██║██║╚════██║    ╚════██║   ██║   ██╔══██╗██╔══╝  ╚════██║╚════██║"
    echo " ██║  ██║███████╗╚██████╔╝██║███████║    ███████║   ██║   ██║  ██║███████╗███████║███████║"
    echo " ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}  Hệ thống kiểm nghiệm khả năng phòng thủ Kernel Firewall (eBPF/XDP)${NC}"
    echo -e "${MAGENTA}  Target Gateway: ${BOLD}${TARGET_IP}${NC}${MAGENTA} | Target Ingress Port: ${BOLD}${TARGET_PORT}${NC}"
    echo "=========================================================================================="
}

check_dependencies() {
    if ! command -v hping3 &>/dev/null; then
        echo -e "${RED}[!] Cảnh báo: hping3 chưa được cài đặt.${NC}"
        echo -e "[*] Đang cài đặt hping3 qua apt..."
        sudo apt-get update -qq && sudo apt-get install -y hping3
    fi
}

run_test() {
    local test_num="$1"
    banner
    case "$test_num" in
        1)
            bash "${SCRIPT_DIR}/scripts/01_test_malformed_land.sh" "$TARGET_IP" "$TARGET_PORT" 50
            ;;
        2)
            bash "${SCRIPT_DIR}/scripts/02_test_tcp_invalid_flags.sh" "$TARGET_IP" "$TARGET_PORT" 50
            ;;
        3)
            bash "${SCRIPT_DIR}/scripts/03_test_ip_fragmentation.sh" "$TARGET_IP" "$TARGET_PORT" 100
            ;;
        4)
            bash "${SCRIPT_DIR}/scripts/04_test_syn_flood.sh" "$TARGET_IP" "$TARGET_PORT" 10
            ;;
        5)
            bash "${SCRIPT_DIR}/scripts/05_test_out_of_state_ack.sh" "$TARGET_IP" 9999 150
            ;;
        6)
            bash "${SCRIPT_DIR}/scripts/06_test_udp_closed_flood.sh" "$TARGET_IP" 54321 200
            ;;
        7)
            bash "${SCRIPT_DIR}/scripts/07_test_icmp_flood.sh" "$TARGET_IP" 200
            ;;
        8)
            bash "${SCRIPT_DIR}/scripts/08_test_tcp_zero_window.sh" "$TARGET_IP" "$TARGET_PORT" 100
            ;;
        all)
            echo -e "${YELLOW}[*] Bắt đầu chuỗi kiểm thử toàn diện (Run All 8 Attack Vectors)...${NC}"
            for i in {1..8}; do
                echo -e "\n${BOLD}${CYAN}>>> CHẠY TEST 0${i}...${NC}"
                run_test "$i"
                sleep 2
            done
            echo -e "\n${GREEN}${BOLD}[✓] ĐÃ HOÀN TẤT TOÀN BỘ 8 BÀI TEST TẤN CÔNG THỬ NGHIỆM.${NC}"
            ;;
    esac
    echo ""
    read -p "Nhấn [Enter] để quay lại menu chính..." || true
}

interactive_menu() {
    while true; do
        banner
        echo -e "${BOLD}CHỌN KỊCH BẢN TẤN CÔNG ĐỂ THEO DÕI LOG/STATS TRÊN KERNEL FIREWALL:${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} Land Attack & Bogon IP Attack      ${MAGENTA}---> Monitor: [Method 02] STAT_DROPPED_BOGON${NC}"
        echo -e "  ${GREEN}2.${NC} Invalid TCP Flags (Null, Xmas, ...) ${MAGENTA}---> Monitor: [Method 04] STAT_DROPPED_TCP_FLAGS${NC}"
        echo -e "  ${GREEN}3.${NC} IP Fragmentation (MF=1, Offset>0)   ${MAGENTA}---> Monitor: [Method 03] STAT_DROPPED_FRAGMENTED${NC}"
        echo -e "  ${GREEN}4.${NC} High-PPS TCP SYN Flood & Auto-Ban   ${MAGENTA}---> Monitor: [Method 05 & 10] SYN & BAN${NC}"
        echo -e "  ${GREEN}5.${NC} Out-of-State ACK to Closed Port    ${MAGENTA}---> Monitor: [Method 06] STAT_DROPPED_OUT_OF_STATE${NC}"
        echo -e "  ${GREEN}6.${NC} UDP Closed Port Flood               ${MAGENTA}---> Monitor: [Method 07] STAT_DROPPED_UDP_JUNK${NC}"
        echo -e "  ${GREEN}7.${NC} ICMP Ping Flood & High-rate Echo    ${MAGENTA}---> Monitor: [Method 08] STAT_DROPPED_ICMP_FLOOD${NC}"
        echo -e "  ${GREEN}8.${NC} TCP Zero-Window (Sockstress)        ${MAGENTA}---> Monitor: [Method 13] STAT_DROPPED_TCP_ANOMALY${NC}"
        echo ""
        echo -e "  ${YELLOW}9.${NC} ${BOLD}CHẠY TẤT CẢ 8 TEST LIÊN TIẾP (FULL BENCHMARK)${NC}"
        echo -e "  ${CYAN}C.${NC} Đổi Target IP / Cổng (Hiện tại: ${TARGET_IP}:${TARGET_PORT})"
        echo -e "  ${RED}0.${NC} Thoát"
        echo ""
        read -p "Nhập lựa chọn của bạn [0-9, C]: " choice

        case "$choice" in
            1|2|3|4|5|6|7|8)
                run_test "$choice"
                ;;
            9)
                run_test "all"
                ;;
            [cC])
                echo ""
                read -p "Nhập Target IP mới (mặc định: 172.30.0.101): " new_ip
                read -p "Nhập Target Port mới (mặc định: 80): " new_port
                [ -n "$new_ip" ] && TARGET_IP="$new_ip"
                [ -n "$new_port" ] && TARGET_PORT="$new_port"
                ;;
            0|[qQ])
                echo -e "\n${GREEN}[✓] Tạm biệt!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}[!] Lựa chọn không hợp lệ.${NC}"
                sleep 1
                ;;
        esac
    done
}

# CLI Argument handling
check_dependencies

if [ $# -gt 0 ]; then
    case "$1" in
        --all)
            run_test "all"
            ;;
        --test)
            run_test "$2"
            ;;
        *)
            TARGET_IP="$1"
            [ $# -gt 1 ] && TARGET_PORT="$2"
            interactive_menu
            ;;
    esac
else
    interactive_menu
fi
