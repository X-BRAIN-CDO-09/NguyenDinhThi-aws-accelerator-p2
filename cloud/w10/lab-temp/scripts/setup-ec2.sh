#!/bin/bash
# ==============================================================================
# Setup Script for AWS EC2 (Ubuntu 22.04) — W10 Security Lab
# Installs: Docker · Kind · kubectl · Helm · Cosign
# Creates:  Kind cluster "security-lab" + ArgoCD
# ==============================================================================
set -euo pipefail

echo "============================================================"
echo " W10 Security Lab — EC2 Bootstrap Script"
echo "============================================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. System packages
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 1. Updating system packages ==="
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    jq \
    unzip

# ─────────────────────────────────────────────────────────────────────────────
# 2. Docker Engine
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 2. Installing Docker Engine ==="
if ! command -v docker &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. You may need to log out and back in for group changes."
else
    echo "✅ Docker already installed."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Kind — Kubernetes in Docker
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 3. Installing Kind v0.22.0 ==="
if ! command -v kind &> /dev/null; then
    KIND_VERSION="v0.22.0"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "✅ Kind installed."
else
    echo "✅ Kind already installed: $(kind version)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. kubectl
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 4. Installing kubectl ==="
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "✅ kubectl installed."
else
    echo "✅ kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Helm
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 5. Installing Helm ==="
if ! command -v helm &> /dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "✅ Helm installed."
else
    echo "✅ Helm already installed: $(helm version --short)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. Cosign (for image signing verification)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 6. Installing Cosign ==="
if ! command -v cosign &> /dev/null; then
    COSIGN_VERSION="v2.2.3"
    curl -Lo cosign https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64
    chmod +x cosign
    sudo mv cosign /usr/local/bin/cosign
    echo "✅ Cosign installed."
else
    echo "✅ Cosign already installed: $(cosign version)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. Create Kind cluster with port mappings
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 7. Creating Kind cluster 'security-lab' ==="
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: security-lab
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
  - containerPort: 30443
    hostPort: 8443
    protocol: TCP
EOF

kind delete cluster --name security-lab 2>/dev/null || true
sg docker -c "kind create cluster --name security-lab --config kind-config.yaml"

# Set up kubeconfig for ubuntu user
mkdir -p $HOME/.kube
sg docker -c "kind get kubeconfig --name security-lab" > $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "✅ Kind cluster created."

# ─────────────────────────────────────────────────────────────────────────────
# 8. Install ArgoCD
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 8. Installing ArgoCD v2.10.4 ==="
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.4/manifests/install.yaml

echo "=== Patching ArgoCD service → NodePort 30443 ==="
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443, "protocol": "TCP", "name": "https"}]}}'

echo "=== Waiting for ArgoCD to become ready (up to 5min) ==="
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

# ─────────────────────────────────────────────────────────────────────────────
# 9. Create demo namespace
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== 9. Creating demo namespace ==="
kubectl create namespace demo 2>/dev/null || true
kubectl label namespace demo project=w10-security-lab 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────────────────────
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode)

EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<EC2-PUBLIC-IP>")

echo ""
echo "============================================================"
echo " SETUP COMPLETED SUCCESSFULLY!"
echo "============================================================"
echo ""
echo "ArgoCD UI:"
echo "  URL:      https://${EC2_IP}:8443"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo "Next steps:"
echo "  1. Add ArgoCD repo credentials for your GitHub repo"
echo "  2. Apply the root app: kubectl apply -f argocd/root.yaml -n argocd"
echo "  3. Create aws-credentials secret (for ESO):"
echo "     kubectl create secret generic aws-credentials \\"
echo "       --from-literal=access-key-id=YOUR_KEY \\"
echo "       --from-literal=secret-access-key=YOUR_SECRET \\"
echo "       -n demo"
echo "============================================================"
