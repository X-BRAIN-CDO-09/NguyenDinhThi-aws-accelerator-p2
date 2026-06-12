#!/bin/bash
# =====================================================================
#  generate-memory-load.sh — Tạo tải bộ nhớ để test mem_used_percent
#  Chạy trực tiếp trên EC2 sau khi lab đã apply và agent đang chạy
#  Usage: ./generate-memory-load.sh [duration_seconds] [memory_percent]
#
#  Ví dụ:
#    ./generate-memory-load.sh           # Mặc định: 120s, 70% RAM
#    ./generate-memory-load.sh 180 80   # 180s, 80% RAM
# =====================================================================
set -euo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DURATION=${1:-120}
MEM_PERCENT=${2:-70}

echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  W9 Session 02 — Memory Load Generator"
echo "  Mục đích: Làm tăng mem_used_percent trong CloudWatch"
echo "============================================================"
echo -e "${NC}"

# Kiểm tra stress-ng đã cài chưa
if ! command -v stress-ng &> /dev/null; then
  echo -e "${YELLOW}⚠️  stress-ng chưa cài. Đang cài đặt...${NC}"
  sudo dnf install -y stress-ng
fi

# Lấy thông tin RAM hiện tại
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAIL_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
USED_MEM=$((TOTAL_MEM - AVAIL_MEM))
USED_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

echo -e "${BOLD}📊 Thông tin RAM hiện tại:${NC}"
echo "  Total:     $(( TOTAL_MEM / 1024 )) MB"
echo "  Used:      $(( USED_MEM / 1024 )) MB (${USED_PERCENT}%)"
echo "  Available: $(( AVAIL_MEM / 1024 )) MB"
echo ""
echo -e "${BOLD}⚡ Bắt đầu tạo tải bộ nhớ:${NC}"
echo "  Workers:  2 processes"
echo "  Target:   ${MEM_PERCENT}% of RAM"
echo "  Duration: ${DURATION} seconds"
echo ""
echo -e "${YELLOW}⏱️  Đợi ~2 phút sau khi hoàn thành để CloudWatch Agent gửi metrics.${NC}"
echo ""

# Chạy stress-ng
stress-ng --vm 2 --vm-bytes "${MEM_PERCENT}%" --timeout "${DURATION}s" --metrics-brief

echo ""
echo -e "${GREEN}✅ Memory load test hoàn thành!${NC}"
echo ""
echo "Bước tiếp theo:"
echo "  1. Đợi ~2 phút"
echo "  2. Mở CloudWatch Dashboard → quan sát mem_used_percent"
echo "  3. Metric nên hiển thị mức tăng đột biến trong khoảng ${DURATION}s vừa rồi"
