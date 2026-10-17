#!/usr/bin/env bash
# ==============================================================================
# Aegis-KernelFW: Kernel Monitor Utility
# Run this directly on the Kernel Firewall Node (172.30.0.101 / VM 101)
# ==============================================================================
set -euo pipefail

MODE="${1:-stats}"

AEGIS_BIN="./build/aegis-fw"
if [ ! -f "$AEGIS_BIN" ] && [ -f "/opt/aegis-fw/aegis-fw" ]; then
    AEGIS_BIN="/opt/aegis-fw/aegis-fw"
fi

show_help() {
    echo "======================================================================"
    echo " 🛡️  Aegis-KernelFW Live Monitoring Helper"
    echo "======================================================================"
    echo "Usage: sudo bash monitor_kernel.sh [MODE]"
    echo ""
    echo "Available Modes:"
    echo "  stats       (Mặc định) Hiển thị bảng thống kê tổng số gói tin & drop rate"
    echo "  live        Bật chế độ xem thời gian thực (Live Dashboard - 1s refresh)"
    echo "  autoban     Xem danh sách các IP đang bị phạt Auto-Ban trong eBPF Map"
    echo "  bpftool     Dump trực tiếp dữ liệu thô từ BPF Per-CPU Map (map_stats)"
    echo "  xdp         Kiểm tra trạng thái card mạng gắn XDP hook (xdp-loader / ip link)"
    echo "  dmesg       Theo dõi log kernel liên quan đến eBPF/XDP"
    echo "======================================================================"
}

case "$MODE" in
    stats)
        echo "[*] Đang đọc thống kê từ eBPF Kernel Firewall..."
        if [ -x "$AEGIS_BIN" ]; then
            sudo "$AEGIS_BIN" stats
        else
            echo "[!] Không tìm thấy $AEGIS_BIN. Thử đọc qua bpftool..."
            sudo bpftool map dump name map_stats || echo "bpftool map_stats not found."
        fi
        ;;

    live)
        echo "[*] Khởi chạy Live Telemetry Dashboard (Nhấn Ctrl+C để thoát)..."
        if [ -x "$AEGIS_BIN" ]; then
            sudo "$AEGIS_BIN" stats --live
        else
            watch -n 1 'sudo bpftool map dump name map_stats'
        fi
        ;;

    autoban)
        echo "[*] Danh sách IP đang bị khóa động (Dynamic Auto-Ban Map):"
        if [ -x "$AEGIS_BIN" ]; then
            sudo "$AEGIS_BIN" map dump map_dynamic_ban || true
        else
            sudo bpftool map dump name map_dynamic_ban || true
        fi
        ;;

    bpftool)
        echo "[*] Dump toàn bộ map_stats qua bpftool:"
        sudo bpftool map dump name map_stats
        ;;

    xdp)
        echo "[*] Kiểm tra trạng thái XDP Interface:"
        ip link show | grep -E 'xdp|UP|LOWER_UP' || true
        if command -v xdp-loader &>/dev/null; then
            echo ""
            echo "[*] xdp-loader status:"
            sudo xdp-loader status || true
        fi
        ;;

    dmesg)
        echo "[*] Theo dõi log kernel (dmesg -w | grep -i bpf):"
        sudo dmesg -w | grep -i --color=auto -E 'bpf|xdp|aegis'
        ;;

    *)
        show_help
        exit 1
        ;;
esac
