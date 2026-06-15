#!/bin/bash
# ============================================================
# verify-alert.sh — Kiểm tra trạng thái toàn bộ hệ thống
# Root Account Login Alert
# ============================================================
# Chạy script này từ local máy sau khi terraform apply
# Yêu cầu: AWS CLI đã cấu hình với quyền đọc CloudTrail, CW, SNS
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_NAME="${1:-w9-root-alert-lab}"
REGION="${2:-ap-southeast-1}"
LOG_GROUP="${3:-/aws/cloudtrail/root-login-alert}"
ALARM_NAME="${PROJECT_NAME}-root-login-detected"
TRAIL_NAME="${PROJECT_NAME}-trail"
TOPIC_NAME="${PROJECT_NAME}-root-account-alerts"

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Root Account Alert — Verification Script  ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# ─── 1. Kiểm tra CloudTrail Trail ───────────────────────────
echo -e "${CYAN}[1/5] CloudTrail Trail Status:${NC}"
TRAIL_STATUS=$(aws cloudtrail get-trail-status \
  --name "$TRAIL_NAME" \
  --region "$REGION" \
  --query 'IsLogging' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$TRAIL_STATUS" = "True" ]; then
  echo -e "  Trail '${TRAIL_NAME}': ${GREEN}LOGGING ✓${NC}"
else
  echo -e "  Trail '${TRAIL_NAME}': ${RED}NOT LOGGING or NOT FOUND ✗${NC}"
fi

# ─── 2. Kiểm tra CloudWatch Logs Group ──────────────────────
echo ""
echo -e "${CYAN}[2/5] CloudWatch Logs Group:${NC}"
LOG_EXISTS=$(aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP" \
  --region "$REGION" \
  --query 'length(logGroups)' \
  --output text 2>/dev/null || echo "0")

if [ "$LOG_EXISTS" -gt 0 ]; then
  echo -e "  Log Group '${LOG_GROUP}': ${GREEN}EXISTS ✓${NC}"
  # Kiểm tra có log stream nào chưa
  STREAM_COUNT=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --region "$REGION" \
    --query 'length(logStreams)' \
    --output text 2>/dev/null || echo "0")
  echo -e "  Log Streams: ${YELLOW}${STREAM_COUNT} streams${NC}"
else
  echo -e "  Log Group '${LOG_GROUP}': ${RED}NOT FOUND ✗${NC}"
fi

# ─── 3. Kiểm tra Metric Filter ──────────────────────────────
echo ""
echo -e "${CYAN}[3/5] CloudWatch Metric Filter:${NC}"
FILTER_COUNT=$(aws logs describe-metric-filters \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" \
  --query 'length(metricFilters)' \
  --output text 2>/dev/null || echo "0")

if [ "$FILTER_COUNT" -gt 0 ]; then
  FILTER_INFO=$(aws logs describe-metric-filters \
    --log-group-name "$LOG_GROUP" \
    --region "$REGION" \
    --query 'metricFilters[0].{Name:filterName,Pattern:filterPattern,Metric:metricTransformations[0].metricName}' \
    --output json 2>/dev/null)
  echo -e "  Metric Filter: ${GREEN}EXISTS ✓${NC}"
  echo -e "  ${YELLOW}${FILTER_INFO}${NC}"
else
  echo -e "  Metric Filter: ${RED}NOT FOUND ✗${NC}"
fi

# ─── 4. Kiểm tra CloudWatch Alarm ───────────────────────────
echo ""
echo -e "${CYAN}[4/5] CloudWatch Alarm Status:${NC}"
ALARM_STATE=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --region "$REGION" \
  --query 'MetricAlarms[0].StateValue' \
  --output text 2>/dev/null || echo "NOT_FOUND")

case "$ALARM_STATE" in
  OK)
    echo -e "  Alarm '${ALARM_NAME}': ${GREEN}OK (No root login detected) ✓${NC}"
    ;;
  ALARM)
    echo -e "  Alarm '${ALARM_NAME}': ${RED}⚠️  ALARM! Root login detected! ✗${NC}"
    ;;
  INSUFFICIENT_DATA)
    echo -e "  Alarm '${ALARM_NAME}': ${YELLOW}INSUFFICIENT_DATA (Waiting for first data point)${NC}"
    ;;
  *)
    echo -e "  Alarm '${ALARM_NAME}': ${RED}NOT_FOUND ✗${NC}"
    ;;
esac

# ─── 5. Kiểm tra SNS Topic ──────────────────────────────────
echo ""
echo -e "${CYAN}[5/5] SNS Topic & Subscription:${NC}"
TOPIC_ARN=$(aws sns list-topics \
  --region "$REGION" \
  --query "Topics[?contains(TopicArn, '${TOPIC_NAME}')].TopicArn | [0]" \
  --output text 2>/dev/null || echo "None")

if [ "$TOPIC_ARN" != "None" ] && [ -n "$TOPIC_ARN" ]; then
  echo -e "  SNS Topic: ${GREEN}${TOPIC_ARN} ✓${NC}"
  SUB_STATUS=$(aws sns list-subscriptions-by-topic \
    --topic-arn "$TOPIC_ARN" \
    --region "$REGION" \
    --query 'Subscriptions[0].SubscriptionArn' \
    --output text 2>/dev/null || echo "None")
  if [[ "$SUB_STATUS" == *"arn:aws:sns"* ]]; then
    echo -e "  Subscription: ${GREEN}CONFIRMED ✓${NC}"
  else
    echo -e "  Subscription: ${YELLOW}PENDING CONFIRMATION (Check email inbox!) ⚠️${NC}"
  fi
else
  echo -e "  SNS Topic: ${RED}NOT FOUND ✗${NC}"
fi

# ─── Summary ────────────────────────────────────────────────
echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}Verification complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Lưu ý:${NC}"
echo "  - CloudTrail có thể mất 5-15 phút để bắt đầu gửi log vào CW Logs"
echo "  - Alarm ở INSUFFICIENT_DATA là bình thường trước khi có data"
echo "  - Confirm email subscription trước khi test root login"
echo -e "${BLUE}=============================================${NC}"
echo ""
