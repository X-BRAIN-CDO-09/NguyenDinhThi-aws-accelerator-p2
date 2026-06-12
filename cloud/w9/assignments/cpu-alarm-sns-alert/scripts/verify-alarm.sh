#!/bin/bash
# ============================================================
# verify-alarm.sh — Kiểm tra trạng thái toàn bộ lab
# Chạy script này trên máy LOCAL (cần AWS CLI đã cấu hình)
# ============================================================

set -e

REGION=${AWS_REGION:-"ap-southeast-1"}
PROJECT="w9-cpu-alarm-lab"
ALARM_NAME="${PROJECT}-cpu-high"
TOPIC_NAME="${PROJECT}-cpu-alerts"

echo "========================================================"
echo "  W9 Lab — Verify CloudWatch + SNS Setup"
echo "  Region: ${REGION}"
echo "========================================================"
echo ""

# 1. Kiểm tra SNS Topic
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  SNS Topic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SNS_ARN=$(aws sns list-topics \
    --region ${REGION} \
    --query "Topics[?contains(TopicArn, '${TOPIC_NAME}')].TopicArn" \
    --output text 2>/dev/null)

if [ -n "${SNS_ARN}" ]; then
    echo "  ✅ SNS Topic tồn tại: ${SNS_ARN}"
else
    echo "  ❌ SNS Topic KHÔNG TÌM THẤY"
fi

# 2. Kiểm tra Email Subscription
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  SNS Subscription"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -n "${SNS_ARN}" ]; then
    aws sns list-subscriptions-by-topic \
        --region ${REGION} \
        --topic-arn "${SNS_ARN}" \
        --query "Subscriptions[*].{Protocol:Protocol,Endpoint:Endpoint,Status:SubscriptionArn}" \
        --output table 2>/dev/null
fi

# 3. Kiểm tra CloudWatch Alarm
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  CloudWatch Alarm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ALARM_STATE=$(aws cloudwatch describe-alarms \
    --region ${REGION} \
    --alarm-names "${ALARM_NAME}" \
    --query "MetricAlarms[0].StateValue" \
    --output text 2>/dev/null)

ALARM_THRESHOLD=$(aws cloudwatch describe-alarms \
    --region ${REGION} \
    --alarm-names "${ALARM_NAME}" \
    --query "MetricAlarms[0].Threshold" \
    --output text 2>/dev/null)

ALARM_PERIOD=$(aws cloudwatch describe-alarms \
    --region ${REGION} \
    --alarm-names "${ALARM_NAME}" \
    --query "MetricAlarms[0].Period" \
    --output text 2>/dev/null)

if [ "${ALARM_STATE}" != "None" ] && [ -n "${ALARM_STATE}" ]; then
    case ${ALARM_STATE} in
        "OK")
            echo "  ✅ Alarm State: OK (CPU bình thường)"
            ;;
        "ALARM")
            echo "  🔥 Alarm State: ALARM (CPU đang cao — email đã gửi!)"
            ;;
        "INSUFFICIENT_DATA")
            echo "  ⏳ Alarm State: INSUFFICIENT_DATA (chờ metric data...)"
            ;;
    esac
    echo "  📊 Threshold: ${ALARM_THRESHOLD}%"
    echo "  ⏱️  Period: ${ALARM_PERIOD}s ($(( ALARM_PERIOD / 60 )) phút)"
else
    echo "  ❌ Alarm KHÔNG TÌM THẤY"
fi

# 4. Kiểm tra EC2 Instance
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  EC2 Instance"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws ec2 describe-instances \
    --region ${REGION} \
    --filters "Name=tag:Project,Values=${PROJECT}" \
              "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,PublicIP:PublicIpAddress,Monitoring:Monitoring.State}" \
    --output table 2>/dev/null

echo ""
echo "========================================================"
echo "  Xem thêm trên AWS Console:"
echo "  CloudWatch → https://console.aws.amazon.com/cloudwatch"
echo "  EC2        → https://console.aws.amazon.com/ec2"
echo "========================================================"
