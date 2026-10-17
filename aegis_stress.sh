#!/usr/bin/env bash
# ==============================================================================
#  🛡️  AEGIS-STRESS: BỘ CÔNG CỤ TỰ ĐỘNG STRESS TEST TƯỜNG LỬA HẠT NHÂN (eBPF/XDP)
#  Chạy trên Attacker VM (Kali Linux: 172.30.0.202) -> Target Gateway (172.30.0.101)
#  Chế độ: TỰ ĐỘNG HOÀN TOÀN - KHÔNG GIỚI HẠN THỜI GIAN - BẤM CTRL+C ĐỂ HỦY
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

CURRENT_PID=""

cleanup_and_exit() {
    echo -e "\n${YELLOW}${BOLD}[!] Đã nhận tín hiệu Ctrl+C. Đang dừng toàn bộ tiến trình stress test...${NC}"
    if [ -n "$CURRENT_PID" ]; then
        kill "$CURRENT_PID" 2>/dev/null || true
    fi
    pkill -P $$ hping3 2>/dev/null || true
    killall hping3 2>/dev/null || true
    echo -e "${GREEN}[✓] Đã hủy và dọn dẹp sạch sẽ. Trở lại trạng thái an toàn.${NC}\n"
    exit 0
}

cleanup_current_test() {
    echo -e "\n${YELLOW}[!] Đã dừng bài test hiện tại (Ctrl+C).${NC}"
    if [ -n "$CURRENT_PID" ]; then
        kill "$CURRENT_PID" 2>/dev/null || true
    fi
    pkill -P $$ hping3 2>/dev/null || true
    killall hping3 2>/dev/null || true
    sleep 0.8
}

trap cleanup_and_exit INT TERM

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
    echo -e "${GREEN}  ⚡ Chế độ: TỰ ĐỘNG LIÊN TỤC (Non-stop Auto Stress - Ctrl+C để dừng)${NC}"
    echo -e "${MAGENTA}  Target Gateway: ${BOLD}${TARGET_IP}${NC}${MAGENTA} | Target Port: ${BOLD}${TARGET_PORT}${NC}"
    echo "=========================================================================================="
}

check_dependencies() {
    if ! command -v hping3 &>/dev/null; then
        echo -e "${RED}[!] Cảnh báo: hping3 chưa được cài đặt.${NC}"
        echo -e "[*] Đang cài đặt hping3 qua apt..."
        sudo apt-get update -qq && sudo apt-get install -y hping3
    fi
}

run_auto_continuous() {
    banner
    echo -e "${BOLD}${YELLOW}>>> BẮT ĐẦU CHẾ ĐỘ AUTO-CYCLE (XOAY VÒNG TỰ ĐỘNG LIÊN TỤC 8 VECTO TẤN CÔNG)${NC}"
    echo -e "${CYAN}    Tool sẽ tự động chuyển đổi giữa 8 kịch bản không ngừng nghỉ.${NC}"
    echo -e "${RED}${BOLD}    [!] KHÔNG CÓ THỜI GIAN GIỚI HẠN. KHI NÀO MUỐN DỪNG CHỈ CẦN NHẤN [Ctrl + C]!${NC}\n"

    local round=1
    while true; do
        echo -e "${BOLD}${MAGENTA}==================== [ VÒNG TẤN CÔNG THỨ $round ] ====================${NC}"

        # 1. Land & Bogon
        echo -e "${CYAN}[Round $round][1/8]${NC} Đang phát Land Attack & Bogon Spoofing... (Method 02: BOGON)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/01_test_malformed_land.sh" "$TARGET_IP" "$TARGET_PORT" 2>/dev/null || true

        # 2. Invalid TCP Flags
        echo -e "${CYAN}[Round $round][2/8]${NC} Đang phát Invalid TCP Flags (Null, Xmas, SYN-FIN)... (Method 04: TCP_FLAGS)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/02_test_tcp_invalid_flags.sh" "$TARGET_IP" "$TARGET_PORT" 2>/dev/null || true

        # 3. IP Fragmentation
        echo -e "${CYAN}[Round $round][3/8]${NC} Đang phát IP Fragmentation (MF=1 / Offset>0)... (Method 03: FRAGMENTED)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/03_test_ip_fragmentation.sh" "$TARGET_IP" "$TARGET_PORT" 2>/dev/null || true

        # 4. TCP SYN Flood
        echo -e "${CYAN}[Round $round][4/8]${NC} Đang xả High-PPS TCP SYN Flood & Auto-Ban... (Method 05 & 10: SYN_FLOOD & BAN)"
        timeout -s INT 8s bash "${SCRIPT_DIR}/scripts/04_test_syn_flood.sh" "$TARGET_IP" "$TARGET_PORT" 2>/dev/null || true

        # 5. Out-of-State ACK
        echo -e "${CYAN}[Round $round][5/8]${NC} Đang phát Out-of-State ACK vào closed port 9999... (Method 06: OUT_OF_STATE)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/05_test_out_of_state_ack.sh" "$TARGET_IP" 9999 2>/dev/null || true

        # 6. UDP Closed Port
        echo -e "${CYAN}[Round $round][6/8]${NC} Đang phát UDP Closed Port Flood 54321... (Method 07: UDP_JUNK)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/06_test_udp_closed_flood.sh" "$TARGET_IP" 54321 2>/dev/null || true

        # 7. ICMP Flood
        echo -e "${CYAN}[Round $round][7/8]${NC} Đang phát ICMP Ping Flood tốc độ cao... (Method 08: ICMP_FLOOD)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/07_test_icmp_flood.sh" "$TARGET_IP" 2>/dev/null || true

        # 8. TCP Zero-Window
        echo -e "${CYAN}[Round $round][8/8]${NC} Đang phát TCP Zero-Window (Sockstress)... (Method 13: TCP_ANOMALY)"
        timeout -s INT 6s bash "${SCRIPT_DIR}/scripts/08_test_tcp_zero_window.sh" "$TARGET_IP" "$TARGET_PORT" 2>/dev/null || true

        round=$((round + 1))
        echo -e "${GREEN}[✓] Đã hoàn thành 1 chu kỳ 8 bài test. Lặp lại chu kỳ tiếp theo ngay lập tức...${NC}\n"
        sleep 1
    done
}

run_single_test_continuous() {
    local test_num="$1"
    banner
    echo -e "${BOLD}${GREEN}>>> KHỞI CHẠY BÀI TEST 0${test_num} LIÊN TỤC (NON-STOP)${NC}"
    echo -e "${RED}${BOLD}>>> NHẤN [Ctrl + C] BẤT KỲ LÚC NÀO ĐỂ DỪNG LẠI.${NC}\n"

    trap cleanup_current_test INT TERM

    case "$test_num" in
        1) bash "${SCRIPT_DIR}/scripts/01_test_malformed_land.sh" "$TARGET_IP" "$TARGET_PORT" ;;
        2) bash "${SCRIPT_DIR}/scripts/02_test_tcp_invalid_flags.sh" "$TARGET_IP" "$TARGET_PORT" ;;
        3) bash "${SCRIPT_DIR}/scripts/03_test_ip_fragmentation.sh" "$TARGET_IP" "$TARGET_PORT" ;;
        4) bash "${SCRIPT_DIR}/scripts/04_test_syn_flood.sh" "$TARGET_IP" "$TARGET_PORT" ;;
        5) bash "${SCRIPT_DIR}/scripts/05_test_out_of_state_ack.sh" "$TARGET_IP" 9999 ;;
        6) bash "${SCRIPT_DIR}/scripts/06_test_udp_closed_flood.sh" "$TARGET_IP" 54321 ;;
        7) bash "${SCRIPT_DIR}/scripts/07_test_icmp_flood.sh" "$TARGET_IP" ;;
        8) bash "${SCRIPT_DIR}/scripts/08_test_tcp_zero_window.sh" "$TARGET_IP" "$TARGET_PORT" ;;
    esac

    trap cleanup_and_exit INT TERM
}

interactive_menu() {
    while true; do
        banner
        echo -e "${BOLD}CHỌN KỊCH BẢN TẤN CÔNG (TỰ ĐỘNG CHẠY LIÊN TỤC - BẤM CTRL+C ĐỂ DỪNG):${NC}\n"
        echo -e "  ${YELLOW}* [KHUYÊN DÙNG]${NC} ${BOLD}BẤM PHÍM 9 HOẶC A:${NC} ${CYAN}${BOLD}CHẠY AUTO TỰ ĐỘNG TOÀN BỘ 8 BÀI TEST LIÊN TỤC${NC}"
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
        echo -e "  ${CYAN}C.${NC} Đổi Target IP / Cổng (Hiện tại: ${TARGET_IP}:${TARGET_PORT})"
        echo -e "  ${RED}0.${NC} Thoát\n"
        read -p "Nhập lựa chọn của bạn [1-9, A, C, 0]: " choice

        case "$choice" in
            1|2|3|4|5|6|7|8)
                run_single_test_continuous "$choice"
                ;;
            9|[aA]|all|auto)
                run_auto_continuous
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
        --auto|--all|-a|all|auto)
            run_auto_continuous
            ;;
        1|2|3|4|5|6|7|8)
            run_single_test_continuous "$1"
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
