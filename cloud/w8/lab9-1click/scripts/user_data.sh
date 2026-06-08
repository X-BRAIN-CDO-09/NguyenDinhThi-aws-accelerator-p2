#!/bin/bash
# ==============================================================================
# LAB CD9 - Bootstrap Script (User Data)
# Dung Kind thay Minikube vi on dinh hon tren Ubuntu 22.04
# ==============================================================================
# KHONG dung set -e o day de script khong thoat dot ngot
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== [1/8] Cap nhat he thong ==="
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "=== [2/8] Cai dat Docker Engine ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

echo "=== [3/8] Cai dat kubectl ==="
KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/$${KUBECTL_VER}/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

echo "=== [4/8] Cai dat Kind ==="
KIND_VER="v0.23.0"
curl -Lo /usr/local/bin/kind \
  "https://kind.sigs.k8s.io/dl/$${KIND_VER}/kind-linux-amd64"
chmod +x /usr/local/bin/kind

echo "=== [5/8] Tao Kind Cluster voi NodePort 30080 ==="
cat > /tmp/kind-config.yaml <<'KINDEOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    listenAddress: "0.0.0.0"
    protocol: TCP
KINDEOF

kind create cluster \
  --name=lab-cd9 \
  --config=/tmp/kind-config.yaml \
  --wait=120s

echo "=== [6/8] Copy kubeconfig sang ubuntu user ==="
mkdir -p /home/ubuntu/.kube
kind get kubeconfig --name=lab-cd9 > /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
# Cung cap cho root de proxy dung
cp /home/ubuntu/.kube/config /root/.kube/config 2>/dev/null || true

echo "=== [7/8] Doi K8s node san sang ==="
until kubectl --kubeconfig=/home/ubuntu/.kube/config get nodes 2>/dev/null | grep -q "Ready"; do
  echo "Waiting for Kind node to be Ready..."
  sleep 5
done
echo "Kind node is Ready!"

echo "=== [7.5/8] Cai dat Metrics Server cho HPA ==="
kubectl --kubeconfig=/home/ubuntu/.kube/config apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl --kubeconfig=/home/ubuntu/.kube/config patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "=== [8/8] Khoi dong kubectl proxy cho Terraform K8s Provider ==="
nohup kubectl \
  --kubeconfig=/home/ubuntu/.kube/config \
  proxy \
  --port=${proxy_port} \
  --address='0.0.0.0' \
  --accept-hosts='^.*$' \
  > /var/log/kubectl-proxy.log 2>&1 &

# Doi proxy that su bat len
for i in $(seq 1 12); do
  if curl -sf http://localhost:${proxy_port}/api/v1/namespaces > /dev/null 2>&1; then
    echo "Proxy is UP on port ${proxy_port}!"
    break
  fi
  echo "Waiting for proxy... ($i/12)"
  sleep 5
done

echo "=== BOOTSTRAP HOAN THANH ==="
touch /var/log/bootstrap_done