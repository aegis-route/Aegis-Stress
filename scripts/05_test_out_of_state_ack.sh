#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 05 - Out-of-State TCP ACK / RST Flood
# Target eBPF Kernel Defense:
#   - [Method 06] TCP Out-of-State Dropped (STAT_DROPPED_OUT_OF_STATE)
#   - Prevents CPU socket exhaustion caused by Linux kernel generating RST replies
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
CLOSED_PORT="${2:-9999}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 05 (Out-of-State ACK)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 05: Out-of-State ACK Flood (Gói ACK gửi vào cổng đóng ${CLOSED_PORT})"
echo "[*] Target: ${TARGET_IP}:${CLOSED_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 06: Drop unsolicited ACK packets without valid conntrack session"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_OUT_OF_STATE"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục Out-of-State ACK flood vào cổng đóng ${CLOSED_PORT}..."
while true; do
    hping3 -c 50 -i u1000 -A -p "$CLOSED_PORT" "$TARGET_IP" 2>/dev/null || true
done
