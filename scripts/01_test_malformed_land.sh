#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 01 - Land Attack & Bogon/Malformed IP Check
# Target eBPF Kernel Defense:
#   - [Method 02] Bogon / Land Attack Dropped (STAT_DROPPED_BOGON)
#   - [Method 01] Malformed / Bad Header Dropped (STAT_DROPPED_MALFORMED)
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 01 (Land & Bogon Attack)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 01: Land Attack (Src IP == Dst IP) & Bogon Spoofing"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 02: Drop immediately (Bogon/Land Attack: Src == Dst)"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_BOGON"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục Land Attack & Bogon Spoofing (500 pps)..."
while true; do
    # 1. Land Attack (Spoof IP nguồn = IP đích)
    hping3 -c 20 -i u2000 -S -a "$TARGET_IP" -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
    # 2. Loopback Bogon (Spoof IP nguồn = 127.0.0.1 qua WAN)
    hping3 -c 20 -i u2000 -S -a 127.0.0.1 -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
    # 3. Zero IP Bogon (Spoof IP nguồn = 0.0.0.0)
    hping3 -c 20 -i u2000 -S -a 0.0.0.0 -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
done
