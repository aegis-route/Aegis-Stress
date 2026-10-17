#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 04 - High PPS TCP SYN Flood & Dynamic Auto-Ban
# Target eBPF Kernel Defense:
#   - [Method 05] TCP SYN Flood Dropped (STAT_DROPPED_SYN_FLOOD)
#   - [Method 10] Dynamic High-PPS Token Bucket Auto-Ban (STAT_DROPPED_DYNAMIC_BAN)
# Chạy liên tục không giới hạn thời gian (Nhấn Ctrl+C để dừng)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"

cleanup() {
    echo -e "\n[✓] Đã dừng Test 04 (SYN Flood & Auto-Ban)."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM

echo "======================================================================"
echo "[*] TEST 04: TCP SYN Flood & Dynamic Auto-Ban Trigger"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT}"
echo "[*] Chế độ: TỰ ĐỘNG LIÊN TỤC (Nhấn Ctrl+C để dừng bất kỳ lúc nào)"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 05: Drop excess SYN packets exceeding per-IP sliding window"
echo "    -> Method 10: Auto-ban source IP into BPF Hash Map (quarantine)"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_SYN_FLOOD & STAT_DROPPED_DYNAMIC_BAN"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] Đang xả SYN Flood tốc độ cao liên tục (hping3 --flood)..."
while true; do
    # Chạy đợt Direct SYN Flood
    timeout -s INT 5s hping3 --flood -S -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
    # Chạy đợt Random-Source SYN Flood
    timeout -s INT 5s hping3 --flood -S --rand-source -p "$TARGET_PORT" "$TARGET_IP" 2>/dev/null || true
done
