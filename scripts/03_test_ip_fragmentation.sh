#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 03 - IP Fragmentation Attack (Teardrop / Frag Flood)
# Target eBPF Kernel Defense:
#   - [Method 03] Fragmented Packet Dropped (STAT_DROPPED_FRAGMENTED)
#   - Catches IP_MF=1 (More Fragments) or Fragment Offset > 0
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"
COUNT="${3:-100}"

echo "======================================================================"
echo "[*] TEST 03: IP Fragmentation & Tiny Fragment Attack"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 03: Drop all IP fragments (MF=1 or Offset>0) at Inbound WAN"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_FRAGMENTED"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] 1. Phát gói tin TCP SYN kèm cờ phân mảnh IP (hping3 -f)..."
hping3 -c "$COUNT" -i u10000 -S -f -p "$TARGET_PORT" -d 120 "$TARGET_IP" || true

echo ""
echo "[>] 2. Phát gói tin UDP kèm cờ phân mảnh IP..."
hping3 -c "$COUNT" -i u10000 --udp -f -p 53 -d 200 "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 03. Kiểm tra counter:"
echo "    sudo ./build/aegis-fw stats | grep -i 'Fragmented'"
