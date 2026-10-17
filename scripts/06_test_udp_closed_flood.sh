#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 06 - UDP Closed Port Flood (Junk UDP Attack)
# Target eBPF Kernel Defense:
#   - [Method 07] UDP Closed Port Dropped (STAT_DROPPED_UDP_JUNK)
#   - Drops non-listening UDP ports at XDP to prevent kernel ICMP port unreachable floods
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
CLOSED_UDP_PORT="${2:-54321}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 06 (UDP Closed Flood)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 06: UDP Closed Port Flood"
echo "[*] Target: ${TARGET_IP}:${CLOSED_UDP_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 07: Drop UDP packets destined to closed ports before stack"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_UDP_JUNK"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục UDP flood vào cổng đóng ${CLOSED_UDP_PORT}..."
while true; do
    hping3 -c 50 -i u1000 --udp -p "$CLOSED_UDP_PORT" -d 64 "$TARGET_IP" 2>/dev/null || true
done
