#!/usr/bin/env bash
set -euo pipefail

# W10 Lab Setup: bootstrap cluster with security stack
# Runs the full bootstrap from day-c, then applies Kyverno for image signing
# Usage: ./setup.sh
# Prereqs: kubectl configured, helm installed, AWS CLI configured

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W10_ROOT="${SCRIPT_DIR}/.."

echo "=== W10 Lab Setup ==="
echo "Cluster: $(kubectl config current-context)"
echo ""

# Create namespaces
echo "[0/5] Creating namespaces..."
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace app security-policy=enforced --overwrite

# Run full platform bootstrap (Gatekeeper + RBAC + ESO + Quotas)
echo "[1/5] Running platform bootstrap..."
bash "${W10_ROOT}/day-c/platform-bootstrap/bootstrap.sh"

# Install Kyverno for image signature verification
echo "[2/5] Installing Kyverno..."
helm repo add kyverno https://kyverno.github.io/kyverno --force-update
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno --create-namespace \
  --set replicaCount=1 \
  --wait --timeout=3m

# Apply image signing policy
echo "[3/5] Applying Kyverno image signing policy..."
kubectl apply -f "${W10_ROOT}/day-b/signing/kyverno-verify-images.yaml"

# Apply additional Gatekeeper constraints
echo "[4/5] Applying all Gatekeeper constraints..."
# Already done by bootstrap.sh — verify count
COUNT=$(kubectl get constraint --no-headers 2>/dev/null | wc -l)
echo "      Active constraints: ${COUNT}"

# Final verification
echo "[5/5] Verification..."
echo ""
echo "--- Gatekeeper ---"
kubectl get constrainttemplate
echo ""
echo "--- Constraints ---"
kubectl get constraint
echo ""
echo "--- ESO ---"
kubectl get externalsecret -n app
echo ""
echo "--- RBAC Roles ---"
kubectl get clusterrole developer sre viewer 2>/dev/null || \
kubectl get role developer -n app 2>/dev/null || true
echo ""
echo "--- Kyverno Policies ---"
kubectl get clusterpolicy
echo ""
echo "--- Quotas ---"
kubectl get resourcequota -n app
echo ""
echo "=== Setup complete. Run cleanup.sh to fix the 6 risks in the broken cluster. ==="
