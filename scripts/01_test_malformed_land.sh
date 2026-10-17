#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 01 - Land Attack & Bogon/Malformed IP Check
# Target eBPF Kernel Defense:
#   - [Method 02] Bogon / Land Attack Dropped (STAT_DROPPED_BOGON)
#   - [Method 01] Malformed / Bad Header Dropped (STAT_DROPPED_MALFORMED)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"
COUNT="${3:-50}"

echo "======================================================================"
echo "[*] TEST 01: Land Attack (Src IP == Dst IP) & Bogon Spoofing"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 02: Drop immediately (Bogon/Land Attack: Src == Dst)"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_BOGON"
echo "======================================================================"

# Check if hping3 is available
if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed. Please install with: apt-get install -y hping3"
    exit 1
fi

echo "[>] 1. Phát gói tin Land Attack (Spoof IP nguồn = IP đích ${TARGET_IP})..."
hping3 -c "$COUNT" -i u10000 -S -a "$TARGET_IP" -p "$TARGET_PORT" "$TARGET_IP" || true

echo ""
echo "[>] 2. Phát gói tin Loopback Bogon Attack (Spoof IP nguồn = 127.0.0.1 qua WAN)..."
hping3 -c "$COUNT" -i u10000 -S -a 127.0.0.1 -p "$TARGET_PORT" "$TARGET_IP" || true

echo ""
echo "[>] 3. Phát gói tin Zero/Null IP Bogon (Spoof IP nguồn = 0.0.0.0)..."
hping3 -c "$COUNT" -i u10000 -S -a 0.0.0.0 -p "$TARGET_PORT" "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 01. Kiểm tra kernel firewall:"
echo "    sudo ./build/aegis-fw stats  hoặc  dmesg | tail -n 20"
