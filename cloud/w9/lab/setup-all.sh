#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  W9 Platform Setup: GitOps, Observability, Canary ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check prerequisites
for cmd in kubectl minikube helm; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}Error: $cmd is not installed. Please install it first.${NC}"
    exit 1
  fi
done

# Step 1: Start Minikube (if not already running)
if ! minikube status &> /dev/null; then
  echo -e "${BLUE}Starting Minikube...${NC}"
  minikube start --driver=docker --cpus=2 --memory=3072mb
else
  echo -e "${GREEN}Minikube is already running.${NC}"
fi

# Step 2: Install ArgoCD
echo -e "${BLUE}Installing ArgoCD...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Install Argo Rollouts
echo -e "${BLUE}Installing Argo Rollouts...${NC}"
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Step 4: Install Prometheus & Grafana via Helm
echo -e "${BLUE}Installing Prometheus & Grafana stack...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false

# Step 5: Wait for core components to be ready
echo -e "${BLUE}Waiting for ArgoCD controller to be ready...${NC}"
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

echo -e "${BLUE}Waiting for Argo Rollouts controller to be ready...${NC}"
kubectl rollout status deployment/argo-rollouts -n argo-rollouts --timeout=120s

# Step 6: Deploy ArgoCD Application
echo -e "${BLUE}Applying GitOps Application...${NC}"
kubectl apply -f ../day-a/argocd-app.yaml

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}  Setup Complete! W9 Stack is initializing.   ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "To access components:"
echo -e "1. ArgoCD Dashboard:     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo -e "   (Password can be retrieved using: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo -e "2. Grafana Dashboard:    kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80"
echo -e "   (Default login: admin / prom-operator)"
echo -e "3. Argo Rollouts UI:     kubectl argo rollouts dashboard"
echo -e "4. Run Load Test:        TARGET_URL=http://\$(minikube ip):30080 k6 run k6-load-test.js"
