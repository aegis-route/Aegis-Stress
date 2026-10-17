#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 07 - ICMP Ping Flood & High-Rate Echo Attack
# Target eBPF Kernel Defense:
#   - [Method 08] ICMP Ping Flood Dropped (STAT_DROPPED_ICMP_FLOOD)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
COUNT="${2:-300}"

echo "======================================================================"
echo "[*] TEST 07: ICMP Ping Flood & High-Rate Echo Request"
echo "[*] Target: ${TARGET_IP} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 08: Drop ICMP Echo flood exceeding sliding window limits"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_ICMP_FLOOD"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Phát gói tin ICMP Echo Request tốc độ cao (u2000 = 500 pps)..."
hping3 -c "$COUNT" -i u2000 --icmp "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 07. Kiểm tra counter:"
echo "    sudo ./build/aegis-fw stats | grep -i 'ICMP'"
