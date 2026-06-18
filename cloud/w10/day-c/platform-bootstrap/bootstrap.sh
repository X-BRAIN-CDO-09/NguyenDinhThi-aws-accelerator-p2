#!/usr/bin/env bash
set -euo pipefail

# W10 Platform Bootstrap: apply security hardening stack in order
# Usage: ./bootstrap.sh
# Prereqs: kubectl configured, helm installed, cluster running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAY_A="${SCRIPT_DIR}/../../day-a"
DAY_B="${SCRIPT_DIR}/../../day-b"

echo "=== W10 Platform Bootstrap ==="
echo ""

# --- Step 1: Install Gatekeeper ---
echo "[1/6] Installing OPA Gatekeeper..."
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts --force-update
helm upgrade --install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system --create-namespace \
  --set replicas=1 \
  --wait --timeout=3m
echo "      Gatekeeper ready"

# --- Step 2: Apply RBAC ---
echo "[2/6] Applying RBAC (developer / sre / viewer / ci-deployer)..."
kubectl apply -f "${DAY_A}/rbac/developer-role.yaml"
kubectl apply -f "${DAY_A}/rbac/sre-clusterrole.yaml"
kubectl apply -f "${DAY_A}/rbac/viewer-clusterrole.yaml"
kubectl apply -f "${DAY_A}/rbac/serviceaccount-ci.yaml"
echo "      RBAC applied"

# --- Step 3: Apply Gatekeeper Policies ---
echo "[3/6] Applying Gatekeeper ConstraintTemplates..."
kubectl apply -f "${DAY_A}/policies/ct-no-root.yaml"
kubectl apply -f "${DAY_A}/policies/ct-required-labels.yaml"
# Wait for CRDs to register before applying Constraints
echo "      Waiting 10s for ConstraintTemplate CRDs to register..."
sleep 10
kubectl apply -f "${DAY_A}/policies/c-no-root.yaml"
kubectl apply -f "${DAY_A}/policies/c-required-labels.yaml"
kubectl apply -f "${DAY_A}/policies/validating-admission-policy.yaml"
echo "      Policies applied"

# --- Step 4: Install External Secrets Operator ---
echo "[4/6] Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set installCRDs=true \
  --wait --timeout=3m
kubectl apply -f "${DAY_B}/eso/secretstore-aws.yaml"
kubectl apply -f "${DAY_B}/eso/externalsecret-db.yaml"
echo "      ESO + SecretStore + ExternalSecret applied"

# --- Step 5: Apply ResourceQuota + LimitRange ---
echo "[5/6] Applying ResourceQuota and LimitRange..."
kubectl apply -f "${SCRIPT_DIR}/resource-quota.yaml"
kubectl apply -f "${SCRIPT_DIR}/limit-range.yaml"
echo "      Quotas applied"

# --- Step 6: Verify ---
echo "[6/6] Verifying all components..."
echo ""
kubectl get pods -n gatekeeper-system
kubectl get pods -n external-secrets
kubectl get constrainttemplate
kubectl get externalsecret -n app
kubectl get resourcequota -n app
kubectl get limitrange -n app
echo ""
echo "=== Bootstrap complete ==="
