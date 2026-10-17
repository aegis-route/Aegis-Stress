#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 06 - UDP Closed Port Flood (Junk UDP Attack)
# Target eBPF Kernel Defense:
#   - [Method 07] UDP Closed Port Dropped (STAT_DROPPED_UDP_JUNK)
#   - Drops non-listening UDP ports at XDP to prevent kernel ICMP port unreachable floods
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
CLOSED_UDP_PORT="${2:-54321}"
COUNT="${3:-300}"

echo "======================================================================"
echo "[*] TEST 06: UDP Closed Port Flood"
echo "[*] Target: ${TARGET_IP}:${CLOSED_UDP_PORT} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 07: Drop UDP packets destined to closed ports before stack"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_UDP_JUNK"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Phát gói tin UDP flood vào cổng đóng ${CLOSED_UDP_PORT}..."
hping3 -c "$COUNT" -i u5000 --udp -p "$CLOSED_UDP_PORT" -d 64 "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 06. Kiểm tra counter:"
echo "    sudo ./build/aegis-fw stats | grep -i 'UDP Closed'"
