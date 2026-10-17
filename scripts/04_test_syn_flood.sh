#!/usr/bin/env bash
# ==============================================================================
# Aegis-Stress: Test 04 - High PPS TCP SYN Flood & Dynamic Auto-Ban
# Target eBPF Kernel Defense:
#   - [Method 05] TCP SYN Flood Dropped (STAT_DROPPED_SYN_FLOOD)
#   - [Method 10] Dynamic High-PPS Token Bucket Auto-Ban (STAT_DROPPED_DYNAMIC_BAN)
# ==============================================================================
set -euo pipefail

TARGET_IP="${1:-172.30.0.101}"
TARGET_PORT="${2:-80}"
DURATION_SEC="${3:-10}"

echo "======================================================================"
echo "[*] TEST 04: TCP SYN Flood & Dynamic Auto-Ban Trigger"
echo "[*] Target: ${TARGET_IP}:${TARGET_PORT} | Duration: ${DURATION_SEC} seconds"
echo "[!] Expected Kernel Firewall Reaction:"
echo "    -> Method 05: Drop excess SYN packets exceeding per-IP sliding window"
echo "    -> Method 10: Auto-ban source IP into BPF Hash Map (60s-300s quarantine)"
echo "    -> Counter to monitor on Kernel: STAT_DROPPED_SYN_FLOOD & STAT_DROPPED_DYNAMIC_BAN"
echo "======================================================================"

if ! command -v hping3 &>/dev/null; then
    echo "[!] Error: hping3 is not installed."
    exit 1
fi

echo "[>] 1. Phát sóng SYN Flood tốc độ cao trong ${DURATION_SEC} giây..."
timeout -s INT "${DURATION_SEC}s" hping3 --flood -S -p "$TARGET_PORT" "$TARGET_IP" || true

echo ""
echo "[>] 2. Phát sóng SYN Flood ngụy tạo IP ngẫu nhiên (--rand-source) trong 5 giây..."
timeout -s INT "5s" hping3 --flood -S --rand-source -p "$TARGET_PORT" "$TARGET_IP" || true

echo ""
echo "[✓] Hoàn tất Test 04. Kiểm tra danh sách IP bị Auto-Ban trên Kernel:"
echo "    sudo ./build/aegis-fw map dump map_dynamic_ban"
echo "    sudo ./build/aegis-fw stats"
