#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 03 - IP Fragmentation Attack (Teardrop / Frag Flood)
# Target eBPF Kernel Defense:
#   - [Method 03] Fragmented Packet Dropped (STAT_DROPPED_FRAGMENTED)
#   - Catches IP_MF=1 (More Fragments) or Fragment Offset > 0
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 03 (IP Fragmentation)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 03: IP Fragmentation & Tiny Fragment Attack"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 03: Drop all IP fragments (MF=1 or Offset>0) at Inbound WAN"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_FRAGMENTED"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang phát liên tục các gói tin mang cờ phân mảnh IP (hping3 -f)..."
while true; do
    # 1. TCP SYN mang cờ MF=1 / Offset>0
    hping3 -c 25 -i u2000 -S -f -p "$TARGET_PORT" -d 120 "$TARGET_IP" 2>/dev/null || true
    # 2. UDP mang cờ phân mảnh
    hping3 -c 25 -i u2000 --udp -f -p 53 -d 200 "$TARGET_IP" 2>/dev/null || true
done
