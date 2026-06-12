#!/bin/bash
# ============================================================
# stress-cpu.sh — Giả lập CPU cao để trigger CloudWatch Alarm
# Chạy script này TRÊN EC2 sau khi SSH vào
# ============================================================
set -e

echo "========================================================"
echo "  W9 Lab — CPU Stress Test (Trigger CloudWatch Alarm)"
echo "========================================================"
echo ""

# Kiểm tra stress-ng đã cài chưa
if ! command -v stress-ng &> /dev/null; then
    echo "📦 Cài stress-ng..."
    sudo dnf install -y stress-ng 2>/dev/null || \
    sudo apt-get install -y stress-ng 2>/dev/null || \
    sudo yum install -y stress-ng 2>/dev/null
fi

CPU_CORES=$(nproc)
DURATION=360  # 6 phút (> 5 phút để chắc chắn trigger)

echo "🖥️  Số CPU cores: ${CPU_CORES}"
echo "⏱️  Thời gian stress: ${DURATION} giây (${DURATION}/60 phút)"
echo "🎯  Mục tiêu: CPU > 80% trong 5 phút liên tiếp"
echo ""
echo "📊  Theo dõi trên AWS Console:"
echo "    CloudWatch → Alarms → w9-cpu-alarm-lab-cpu-high"
echo ""
echo "⏳  Bắt đầu sau 3 giây..."
sleep 3

echo ""
echo "💥 Running stress-ng on ${CPU_CORES} CPUs..."
echo "   [Press Ctrl+C để dừng sớm]"
echo ""

stress-ng --cpu ${CPU_CORES} \
          --timeout ${DURATION}s \
          --metrics-brief \
          --verbose

echo ""
echo "✅ Stress test hoàn tất!"
echo ""
echo "📬 Kiểm tra email — bạn nên nhận được alert trong vài phút"
echo "   Alarm state: CloudWatch → Alarms → w9-cpu-alarm-lab-cpu-high"
