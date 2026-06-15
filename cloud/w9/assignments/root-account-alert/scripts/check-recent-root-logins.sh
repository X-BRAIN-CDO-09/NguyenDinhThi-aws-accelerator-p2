#!/bin/bash
# ============================================================
# check-recent-root-logins.sh
# Tìm kiếm các sự kiện Root account login gần đây
# trong CloudTrail và CloudWatch Logs
# ============================================================

set -e

REGION="${1:-ap-southeast-1}"
LOG_GROUP="${2:-/aws/cloudtrail/root-login-alert}"
HOURS="${3:-24}"

echo ""
echo "============================================="
echo " Check Recent Root Account Logins"
echo " Region: $REGION | Log Group: $LOG_GROUP"
echo " Looking back: ${HOURS} hours"
echo "============================================="

# Tính start time (Unix milliseconds)
START_TIME=$(date -d "-${HOURS} hours" +%s000 2>/dev/null || \
             python3 -c "import time; print(int((time.time() - ${HOURS}*3600) * 1000))")

echo ""
echo "[1] Tìm kiếm trong CloudTrail Event History (last 90 days)..."
aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=Username,AttributeValue=root \
  --start-time "$(date -d "-${HOURS} hours" --iso-8601=seconds 2>/dev/null || date -v-${HOURS}H -u +%Y-%m-%dT%H:%M:%SZ)" \
  --query 'Events[].{Time:EventTime,Name:EventName,Source:EventSource,IP:CloudTrailEvent}' \
  --output table 2>/dev/null || echo "  Không có sự kiện root login gần đây hoặc lỗi CLI."

echo ""
echo "[2] Tìm kiếm trong CloudWatch Logs..."
aws logs filter-log-events \
  --region "$REGION" \
  --log-group-name "$LOG_GROUP" \
  --start-time "$START_TIME" \
  --filter-pattern '{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }' \
  --query 'events[].{timestamp:timestamp,message:message}' \
  --output json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('  Không tìm thấy Root login events trong CW Logs')
else:
    import datetime
    for e in data[:10]:
        ts = datetime.datetime.fromtimestamp(e['timestamp']/1000)
        msg = json.loads(e['message'])
        print(f\"  [{ts}] Event: {msg.get('eventName','?')} | User: {msg.get('userIdentity',{}).get('type','?')} | IP: {msg.get('sourceIPAddress','?')}\")
" 2>/dev/null || echo "  Không tìm thấy hoặc Log Group chưa có data."

echo ""
echo "============================================="
echo " Xong! Nếu không thấy event nào = BÌNH THƯỜNG"
echo " (Root account chưa được dùng gần đây)"
echo "============================================="
