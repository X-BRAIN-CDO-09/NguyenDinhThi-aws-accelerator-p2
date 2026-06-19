#!/bin/bash
# ==========================================================
# Script: upload-sample-data.sh
# Mục đích: Upload sample data files lên S3 bucket để Macie scan
# Cách dùng: bash upload-sample-data.sh <BUCKET_NAME> <REGION>
# Ví dụ:     bash upload-sample-data.sh macie-lab-thi ap-southeast-1
# ==========================================================

BUCKET_NAME=${1:-"macie-sensitive-lab-bucket"}
REGION=${2:-"ap-southeast-1"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="$SCRIPT_DIR/../sample-data"

echo "📦 Uploading sample data to s3://$BUCKET_NAME/sensitive-samples/ ..."

aws s3 cp "$SAMPLE_DIR/fake-personal-info.txt" \
  "s3://$BUCKET_NAME/sensitive-samples/fake-personal-info.txt" \
  --region "$REGION"

aws s3 cp "$SAMPLE_DIR/fake-credit-cards.csv" \
  "s3://$BUCKET_NAME/sensitive-samples/fake-credit-cards.csv" \
  --region "$REGION"

echo ""
echo "✅ Upload hoàn thành! Kiểm tra bucket:"
aws s3 ls "s3://$BUCKET_NAME/sensitive-samples/" --region "$REGION"
echo ""
echo "👉 Bước tiếp theo: Vào AWS Console → Amazon Macie → Jobs → Create Job để bắt đầu scan bucket này."
