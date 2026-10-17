#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 02 - Invalid TCP Flags & Port Scanning Anomalies
# Target eBPF Kernel Defense:
#   - [Method 04] Invalid TCP Flags Dropped (STAT_DROPPED_TCP_FLAGS)
#   - Detects: Null scan, Xmas scan, SYN-FIN, SYN-RST, FIN without ACK
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 02 (Invalid TCP Flags)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 02: Invalid TCP Flags & Anomalous Flag Combinations"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 04: Drop invalid TCP flag headers at XDP driver level"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_TCP_FLAGS"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang xoay vòng phát liên tục các loại cờ TCP dị tật (Null, Xmas, SYN-FIN, SYN-RST, FIN)..."
while true; do
    # 1. Null Scan (flags = 0)
    hping3 -c 20 -i u2000 -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
    # 2. Xmas Scan (FIN + URG + PSH)
    hping3 -c 20 -i u2000 -p "$TARGET_PORT" -F -P -U "$TARGET_IP" 2>/dev/null || true
    # 3. SYN + FIN
    hping3 -c 20 -i u2000 -p "$TARGET_PORT" -S -F "$TARGET_IP" 2>/dev/null || true
    # 4. SYN + RST
    hping3 -c 20 -i u2000 -p "$TARGET_PORT" -S -R "$TARGET_IP" 2>/dev/null || true
    # 5. Standalone FIN (no ACK)
    hping3 -c 20 -i u2000 -p "$TARGET_PORT" -F "$TARGET_IP" 2>/dev/null || true
done
