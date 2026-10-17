#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 07 - ICMP Ping Flood & High-Rate Echo Attack
# Target eBPF Kernel Defense:
#   - [Method 08] ICMP Ping Flood Dropped (STAT_DROPPED_ICMP_FLOOD)
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 07 (ICMP Ping Flood)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 07: ICMP Ping Flood & High-Rate Echo Request"
echo "[*] Target: ${TARGET_IP}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 08: Drop ICMP Echo flood exceeding sliding window limits"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_ICMP_FLOOD"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục ICMP Echo Request tốc độ cao (u1000 = 1000 pps)..."
while true; do
    hping3 -c 50 -i u1000 --icmp "$TARGET_IP" 2>/dev/null || true
done
