#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 08 - TCP Zero-Window & Sockstress Anomaly
# Target eBPF Kernel Defense:
#   - [Method 13] TCP Zero-Window / Anomaly Dropped (STAT_DROPPED_TCP_ANOMALY)
#   - Blocks attacks attempting to lock server TCP receive buffers (window size = 0)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"
COUNT="${3:-150}"

echo "======================================================================"
echo "[*] TEST 08: TCP Zero-Window Attack (Window size = 0)"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 13: Drop packets advertising 0 window size intended to freeze sockets"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_TCP_ANOMALY"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Phát gói tin TCP SYN kèm thông số Window Size = 0 (Sockstress)..."
hping3 -c "$COUNT" -i u5000 -S -p "$TARGET_PORT" --win 0 "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 08. Kiểm tra counter:"
echo "    sudo ./build/aegis-fw stats | grep -i 'Zero-Window'"
