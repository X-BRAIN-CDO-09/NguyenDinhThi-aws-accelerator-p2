#!/usr/bin/env bash
# ============================================================
# ec2-bootstrap.sh — W9 Lab Final: EC2 Bootstrap Script
# Cài đặt Docker, Kubectl, Helm, Minikube, k6 và khởi động Minikube
# Chạy: chmod +x ec2-bootstrap.sh && ./ec2-bootstrap.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}${BOLD}━━ $1 ━━${NC}"; }

step "1. Cập nhật hệ thống & Cài đặt Docker"
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

if ! command -v docker &> /dev/null; then
  log "Đang cài đặt Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  log "Docker đã cài đặt thành công."
else
  log "Docker đã được cài đặt."
fi

step "2. Cài đặt Kubectl & Helm"
if ! command -v kubectl &> /dev/null; then
  log "Đang cài đặt kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  log "kubectl đã được cài đặt."
fi

if ! command -v helm &> /dev/null; then
  log "Đang cài đặt Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  log "Helm đã được cài đặt."
fi

step "3. Cài đặt Minikube"
if ! command -v minikube &> /dev/null; then
  log "Đang cài đặt Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
else
  log "Minikube đã được cài đặt."
fi

step "4. Cài đặt k6 (cho Load Test)"
if ! command -v k6 &> /dev/null; then
  log "Đang tải và cài đặt k6 via deb package..."
  curl -LO https://github.com/grafana/k6/releases/download/v0.51.0/k6-v0.51.0-linux-amd64.deb
  sudo dpkg -i k6-v0.51.0-linux-amd64.deb
  rm k6-v0.51.0-linux-amd64.deb
  log "k6 đã cài đặt thành công."
else
  log "k6 đã được cài đặt."
fi

step "5. Khởi động Minikube"
# Sử dụng 2 cpus và 6GB RAM như cấu hình lab-final
log "Khởi chạy Minikube profile w9 với 2 cpus và 6g RAM..."
sg docker -c "minikube start -p w9 --driver=docker --cpus=2 --memory=6g"

log "Môi trường đã sẵn sàng!"
echo -e "Hãy chạy tiếp các lệnh sau:"
echo -e "  cd cloud/w9/lab-final"
echo -e "  docker build -t w9-api:1 app/"
echo -e "  minikube image load w9-api:1 -p w9"
echo -e "  ./setup.sh"
