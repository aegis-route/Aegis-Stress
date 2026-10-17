#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 02 - Invalid TCP Flags & Port Scanning Anomalies
# Target eBPF Kernel Defense:
#   - [Method 04] Invalid TCP Flags Dropped (STAT_DROPPED_TCP_FLAGS)
#   - Detects: Null scan, Xmas scan, SYN-FIN, SYN-RST, FIN without ACK
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"
COUNT="${3:-50}"

echo "======================================================================"
echo "[*] TEST 02: Invalid TCP Flags & Anomalous Flag Combinations"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT} | Count per sub-test: ${COUNT}"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 04: Drop invalid TCP flag headers at XDP driver level"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_TCP_FLAGS"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] 1. Null Scan Attack (Không bật bất kỳ TCP flag nào - flags = 0)..."
hping3 -c "$COUNT" -i u10000 -p "$TARGET_PORT" --null "$TARGET_IP" || true

echo ""
echo "[>] 2. Xmas Scan Attack (Bật đồng thời FIN + URG + PSH)..."
hping3 -c "$COUNT" -i u10000 -p "$TARGET_PORT" --xmas "$TARGET_IP" || true

echo ""
echo "[>] 3. Bất thường SYN + FIN (Vừa mở kết nối vừa đóng kết nối cùng lúc)..."
hping3 -c "$COUNT" -i u10000 -p "$TARGET_PORT" -S -F "$TARGET_IP" || true

echo ""
echo "[>] 4. Bất thường SYN + RST (Vừa yêu cầu kết nối vừa Reset kết nối)..."
hping3 -c "$COUNT" -i u10000 -p "$TARGET_PORT" -S -R "$TARGET_IP" || true

echo ""
echo "[>] 5. FIN đơn lẻ không có ACK (Vi phạm giao thức TCP State)..."
hping3 -c "$COUNT" -i u10000 -p "$TARGET_PORT" -F "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 02. Đếm số lượng gói bị drop:"
echo "    sudo ./build/aegis-fw stats | grep -i 'TCP Flags'"
