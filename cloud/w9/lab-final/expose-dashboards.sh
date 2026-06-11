#!/usr/bin/env bash
# ============================================================
# expose-dashboards.sh — W9 Lab Final: Expose Dashboards
# Tự động port-forward các UI dịch vụ ra ngoài Internet trên EC2
# Chạy: chmod +x expose-dashboards.sh && ./expose-dashboards.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# 1. Dọn dẹp các tiến trình port-forward cũ
echo -e "${BLUE}Dọn dẹp các port-forward cũ đang chạy...${NC}"
killall kubectl 2>/dev/null || true
sleep 1

# 2. Khởi chạy các port-forward mới chạy ngầm
echo -e "${BLUE}Đang khởi chạy port-forward cho các dịch vụ...${NC}"
kubectl port-forward svc/frontend-service -n demo 30090:80 --address 0.0.0.0 >/dev/null 2>&1 &
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80 --address 0.0.0.0 >/dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 >/dev/null 2>&1 &
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090 --address 0.0.0.0 >/dev/null 2>&1 &
kubectl port-forward svc/kube-prometheus-stack-alertmanager -n monitoring 9093:9093 --address 0.0.0.0 >/dev/null 2>&1 &

sleep 2

# 3. Lấy thông tin Public IP và Mật khẩu ArgoCD
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com || curl -s ifconfig.me || echo "<EC2_PUBLIC_IP>")
# Xóa ký tự xuống dòng từ curl output
PUBLIC_IP=$(echo "${PUBLIC_IP}" | tr -d '\r\n ')

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")

# 4. Hiển thị bảng thông tin truy cập
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀  W9 Lab Final — Giao diện quản trị đã được expose!${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}1. Frontend Dashboard:${NC}"
echo -e "     http://${PUBLIC_IP}:30090"
echo ""
echo -e "  ${BOLD}2. Grafana Dashboard (SLO / Error Budget):${NC}"
echo -e "     http://${PUBLIC_IP}:3000"
echo -e "     Tài khoản: ${BLUE}admin${NC} | Mật khẩu: ${BLUE}admin123${NC}"
echo ""
echo -e "  ${BOLD}3. ArgoCD UI (GitOps):${NC}"
echo -e "     https://${PUBLIC_IP}:8080"
echo -e "     Tài khoản: ${BLUE}admin${NC} | Mật khẩu: ${BLUE}${ARGOCD_PASS}${NC}"
echo ""
echo -e "  ${BOLD}4. Prometheus UI (Alerts):${NC}"
echo -e "     http://${PUBLIC_IP}:9090"
echo ""
echo -e "  ${BOLD}5. AlertManager UI:${NC}"
echo -e "     http://${PUBLIC_IP}:9093"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Để dừng tất cả các port-forward ngầm này, hãy chạy lệnh: ${YELLOW}killall kubectl${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
