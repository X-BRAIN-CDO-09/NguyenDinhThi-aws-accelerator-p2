#!/bin/bash
# =====================================================================
#  verify-agent.sh — Kiểm tra trạng thái CloudWatch Agent trên EC2
#  Chạy trực tiếp trên EC2 sau khi lab đã được apply
#  Usage: ./verify-agent.sh
# =====================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "============================================================"
echo "  W9 Session 02 — CloudWatch Agent Verification"
echo "  $(date)"
echo "============================================================"
echo -e "${NC}"

# ── 1. Agent Process Status ──────────────────────────────────────
echo -e "${BOLD}[1/5] CloudWatch Agent Process Status${NC}"
echo "─────────────────────────────────────────"
STATUS=$(/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status 2>&1 || true)
echo "$STATUS"

if echo "$STATUS" | grep -q '"status": "running"'; then
  echo -e "${GREEN}✅ CloudWatch Agent is RUNNING${NC}"
else
  echo -e "${RED}❌ CloudWatch Agent is NOT running${NC}"
  echo -e "${YELLOW}Try: sudo systemctl start amazon-cloudwatch-agent${NC}"
fi

echo ""

# ── 2. Systemd Service Status ─────────────────────────────────────
echo -e "${BOLD}[2/5] Systemd Service Status${NC}"
echo "─────────────────────────────────────────"
systemctl status amazon-cloudwatch-agent --no-pager --lines=5 || true

echo ""

# ── 3. Config File Check ──────────────────────────────────────────
echo -e "${BOLD}[3/5] Agent Config (active config)${NC}"
echo "─────────────────────────────────────────"
CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
if [ -f "$CONFIG_PATH" ]; then
  echo -e "${GREEN}✅ Config file found at: $CONFIG_PATH${NC}"
  echo "Namespace configured:"
  grep -o '"namespace".*' "$CONFIG_PATH" | head -3 || echo "(embedded in merged config)"
else
  echo -e "${YELLOW}⚠️  Config file not at default path — checking merged config...${NC}"
  MERGED="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml"
  [ -f "$MERGED" ] && echo "Found: $MERGED" || echo "No config found."
fi

echo ""

# ── 4. Agent Logs ─────────────────────────────────────────────────
echo -e "${BOLD}[4/5] Recent Agent Logs (last 15 lines)${NC}"
echo "─────────────────────────────────────────"
LOG_FILE="/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
if [ -f "$LOG_FILE" ]; then
  tail -15 "$LOG_FILE"
else
  echo -e "${YELLOW}⚠️  Log file not found at: $LOG_FILE${NC}"
fi

echo ""

# ── 5. Instance Metadata ──────────────────────────────────────────
echo -e "${BOLD}[5/5] Instance Information${NC}"
echo "─────────────────────────────────────────"
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || echo "")

if [ -n "$TOKEN" ]; then
  INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
  INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown")
  REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "unknown")

  echo "  Instance ID:   $INSTANCE_ID"
  echo "  Instance Type: $INSTANCE_TYPE"
  echo "  Region:        $REGION"
  echo ""
  echo -e "${CYAN}📊 CloudWatch Metrics URL:${NC}"
  echo "  https://$REGION.console.aws.amazon.com/cloudwatch/home?region=$REGION#metricsV2:namespace=W9Lab/CustomMetrics"
fi

echo ""
echo -e "${BOLD}${GREEN}============================================================"
echo "  Verification complete!"
echo "  Wait ~2 minutes then check CloudWatch Console for metrics."
echo "============================================================${NC}"
