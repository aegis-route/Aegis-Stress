#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 05 - Out-of-State TCP ACK / RST Flood
# Target eBPF Kernel Defense:
#   - [Method 06] TCP Out-of-State Dropped (STAT_DROPPED_OUT_OF_STATE)
#   - Prevents CPU socket exhaustion caused by Linux kernel generating RST replies
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
CLOSED_PORT="${2:-9999}"
COUNT="${3:-200}"

echo "======================================================================"
echo "[*] TEST 05: Out-of-State ACK Flood (Gói ACK đơn độc gửi vào cổng đóng)"
echo "[*] Target: ${TARGET_IP}:${CLOSED_PORT} | Count: ${COUNT} packets"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 06: Drop unsolicited ACK packets without valid conntrack session"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_OUT_OF_STATE"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Phát gói tin TCP ACK flood vào cổng đóng ${CLOSED_PORT}..."
hping3 -c "$COUNT" -i u5000 -A -p "$CLOSED_PORT" "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 05. Kiểm tra counter:"
echo "    sudo ./build/aegis-fw stats | grep -i 'Out-of-State'"
