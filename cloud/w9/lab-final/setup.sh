#!/bin/bash
# ============================================================
# setup.sh — W9 Lab Final: Ship Smartly
# Cài đặt tự động: ArgoCD + Prometheus + Argo Rollouts + App
# Chạy: chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}${BOLD}━━ $1 ━━${NC}"; }

echo -e "${BOLD}"
cat << 'EOF'
  W9 Lab Final — Ship Smartly
  GitOps + Observability + Canary Auto-Abort
EOF
echo -e "${NC}"

# ── Step 0: Check Prerequisites ─────────────────────────────
step "0. Kiểm tra prerequisites"

command -v kubectl >/dev/null || err "kubectl chưa cài. Cài tại: https://kubernetes.io/docs/tasks/tools/"
command -v helm    >/dev/null || err "helm chưa cài.    Cài tại: https://helm.sh/docs/intro/install/"
command -v docker  >/dev/null || err "docker chưa cài.  Cài tại: https://docs.docker.com/get-docker/"
log "kubectl, helm, docker: OK"

# Check minikube running
if ! kubectl get nodes &>/dev/null; then
  warn "Cluster chưa sẵn sàng. Khởi động minikube:"
  echo "  minikube start -p w9 --cpus=4 --memory=6g"
  exit 1
fi
log "Kubernetes cluster: OK ($(kubectl get nodes --no-headers | wc -l) node)"

# ── Step 1: Install ArgoCD ──────────────────────────────────
step "1. Cài ArgoCD"

if kubectl get deployment argocd-server -n argocd &>/dev/null; then
  log "ArgoCD đã được cài đặt, bỏ qua cài"
else
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply --server-side -n argocd \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  log "ArgoCD đang cài..."
  kubectl wait --for=condition=available deployment/argocd-server \
    -n argocd --timeout=180s
  log "ArgoCD: Ready"
fi

# ── Step 2: Install kubectl-argo-rollouts plugin ────────────
step "2. Cài kubectl-argo-rollouts plugin"

if kubectl argo rollouts version &>/dev/null 2>&1; then
  log "kubectl-argo-rollouts: đã cài"
else
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  curl -sLo /tmp/kubectl-argo-rollouts \
    "https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-${OS}-amd64"
  chmod +x /tmp/kubectl-argo-rollouts
  sudo mv /tmp/kubectl-argo-rollouts /usr/local/bin/
  log "kubectl-argo-rollouts: cài xong"
fi

# ── Step 3: Build Flask image ───────────────────────────────
step "3. Build Flask API image"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if docker images | grep -q "w9-api"; then
  log "Image w9-api:1 đã tồn tại"
else
  docker build -t w9-api:1 "${SCRIPT_DIR}/app/"
  log "Build image: OK"
fi

# Load vào minikube nếu đang dùng minikube
if command -v minikube &>/dev/null; then
  # Clean asterisk and whitespace from minikube profile output
  PROFILE=$(minikube profile 2>/dev/null | tr -d '*' | xargs || echo "w9")
  if [ -z "${PROFILE}" ] || [ "${PROFILE}" = "minikube" ]; then
    PROFILE="w9"
  fi
  warn "Loading image vào minikube profile: ${PROFILE}"
  minikube image load w9-api:1 -p "${PROFILE}"
  log "Image loaded vào minikube"
fi

# ── Step 4: Apply Root App (App-of-Apps) ────────────────────
step "4. Apply ArgoCD Root Application"

warn "Hãy cập nhật repoURL trong argocd/root.yaml và argocd/apps/*.yaml trước!"
warn "Thay <YOUR_USERNAME>/<YOUR_REPO> bằng repo GitHub thật của bạn"
echo ""
read -p "Đã cập nhật repoURL chưa? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  warn "Chưa cập nhật repoURL. Dừng tại đây."
  echo "Sau khi cập nhật, chạy: kubectl apply -f argocd/root.yaml"
  exit 0
fi

kubectl apply -f "${SCRIPT_DIR}/argocd/root.yaml"
log "Root Application đã apply — ArgoCD đang tự deploy mọi thứ..."

# ── Step 5: Wait & Summary ──────────────────────────────────
step "5. Đợi Prometheus stack ready"

warn "Prometheus stack cần ~3-5 phút để cài xong..."
kubectl wait --for=condition=available deployment/kube-prometheus-stack-grafana \
  -n monitoring --timeout=300s 2>/dev/null || warn "Timeout — kiểm tra: kubectl get pods -n monitoring"

# ── Step 6: Get Access Info ─────────────────────────────────
step "6. Thông tin truy cập"

MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "<CLUSTER_IP>")
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  🚀 W9 Lab Final — Thông tin truy cập${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Frontend Dashboard${NC}"
echo -e "  http://${MINIKUBE_IP}:30090"
echo ""
echo -e "  ${BOLD}Backend API (stable)${NC}"
echo -e "  http://${MINIKUBE_IP}:30080"
echo ""
echo -e "  ${BOLD}Backend API (canary)${NC}"
echo -e "  http://${MINIKUBE_IP}:30081"
echo ""
echo -e "  ${BOLD}ArgoCD UI${NC}"
echo -e "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo -e "  https://localhost:8080  admin / ${ARGOCD_PASS}"
echo ""
echo -e "  ${BOLD}Prometheus${NC}"
echo -e "  kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090"
echo -e "  http://localhost:9090"
echo ""
echo -e "  ${BOLD}Grafana${NC}"
echo -e "  kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80"
echo -e "  http://localhost:3000  admin / admin123"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Bước tiếp theo:${NC}"
echo "  1. Chạy load test:  k6 run k6-load-test.js"
echo "  2. Watch rollout:   kubectl argo rollouts get rollout backend -n demo --watch"
echo "  3. Test canary:     Đổi VERSION=v2 & ERROR_RATE=0.2 trong rollout.yaml → git push"
echo ""
