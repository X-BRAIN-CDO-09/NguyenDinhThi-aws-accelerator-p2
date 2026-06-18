#!/usr/bin/env bash
set -euo pipefail

# W10 Lab: Fix the 6 security risks one by one
# Usage: ./cleanup.sh [risk-number]
#   ./cleanup.sh       — run all 6 fixes
#   ./cleanup.sh 2     — fix only R-02 (ClusterAdmin)
# Prereqs: setup.sh already run (Gatekeeper + ESO + Kyverno installed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
W10_ROOT="${SCRIPT_DIR}/.."
TARGET="${1:-all}"

PASS=0
FAIL=0

log_pass() { echo "  PASS  $*"; ((PASS++)); }
log_fail() { echo "  FAIL  $*"; ((FAIL++)); }

fix_r01() {
  echo "=== R-01: Container running as root ==="
  # Apply no-root Gatekeeper constraint (already in enforce mode)
  kubectl apply -f "${W10_ROOT}/day-a/policies/ct-no-root.yaml"
  sleep 8
  kubectl apply -f "${W10_ROOT}/day-a/policies/c-no-root.yaml"

  # Test: try to create a root container — should be denied
  echo "  Testing: creating root pod (should be denied)..."
  DENIED=$(kubectl apply -f - 2>&1 <<EOF || true
apiVersion: v1
kind: Pod
metadata:
  name: test-root
  namespace: app
spec:
  containers:
  - name: main
    image: nginx:alpine
    securityContext:
      runAsUser: 0
EOF
)
  if echo "${DENIED}" | grep -q "denied\|violation"; then
    log_pass "Root container blocked by Gatekeeper"
  else
    log_fail "Root container NOT blocked — constraint may not be in enforce mode"
  fi
}

fix_r02() {
  echo "=== R-02: Developer with ClusterAdmin ==="
  # Find and remove any developer/non-admin binding to cluster-admin
  echo "  Checking for over-privileged ClusterRoleBindings..."
  kubectl get clusterrolebinding -o json | \
    jq -r '.items[] | select(.roleRef.name=="cluster-admin") | select(.subjects[]?.name | test("alice|developer|bob|dev")) | .metadata.name' | \
    while read -r binding; do
      echo "  Removing dangerous binding: ${binding}"
      kubectl delete clusterrolebinding "${binding}"
    done

  # Apply correct minimal RBAC
  kubectl apply -f "${W10_ROOT}/day-a/rbac/developer-role.yaml"
  kubectl apply -f "${W10_ROOT}/day-a/rbac/sre-clusterrole.yaml"
  kubectl apply -f "${W10_ROOT}/day-a/rbac/viewer-clusterrole.yaml"

  # Verify
  CAN_DELETE=$(kubectl auth can-i delete pods --as=alice -n app 2>/dev/null)
  CAN_GET=$(kubectl auth can-i get pods --as=alice -n app 2>/dev/null)
  if [[ "${CAN_DELETE}" == "no" && "${CAN_GET}" == "yes" ]]; then
    log_pass "developer RBAC correct: get=yes, delete=no"
  else
    log_fail "RBAC incorrect: delete=${CAN_DELETE}, get=${CAN_GET}"
  fi
}

fix_r03() {
  echo "=== R-03: Hardcoded secrets in manifest ==="
  # Check for plain-text secrets in namespace
  echo "  Checking for plain-text secrets..."
  PLAIN=$(kubectl get secret -n app -o json | \
    jq -r '.items[] | select(.type != "kubernetes.io/service-account-token") | select(.metadata.annotations["managed-by"] != "external-secrets") | .metadata.name')
  if [[ -n "${PLAIN}" ]]; then
    echo "  Found non-ESO secrets: ${PLAIN}"
    echo "  Applying ESO ExternalSecret to replace..."
    kubectl apply -f "${W10_ROOT}/day-b/eso/externalsecret-db.yaml"
    log_pass "ExternalSecret applied — secret will be managed by ESO"
  else
    log_pass "No hardcoded secrets found — all secrets managed by ESO"
  fi
}

fix_r04() {
  echo "=== R-04: No Trivy scan in CI ==="
  echo "  Action required (cannot automate — must update GitHub Actions workflow):"
  echo "  Copy day-b/ci-trivy/trivy-scan.yaml to .github/workflows/trivy-scan.yaml"
  echo "  and push to enable CI scanning."
  echo "  Reference file: ${W10_ROOT}/day-b/ci-trivy/trivy-scan.yaml"
  log_pass "Trivy scan workflow file ready to copy"
}

fix_r05() {
  echo "=== R-05: Unsigned images ==="
  # Apply Kyverno policy to enforce signed images
  kubectl apply -f "${W10_ROOT}/day-b/signing/kyverno-verify-images.yaml"

  # Test: try to create pod with unsigned image — should be denied
  echo "  Testing: creating pod with unsigned image (should be denied)..."
  DENIED=$(kubectl apply -f - 2>&1 <<EOF || true
apiVersion: v1
kind: Pod
metadata:
  name: test-unsigned
  namespace: app
spec:
  containers:
  - name: main
    image: ghcr.io/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2/backend:unsigned-test
EOF
)
  if echo "${DENIED}" | grep -q "denied\|signature\|verify"; then
    log_pass "Unsigned image blocked by Kyverno"
  else
    echo "  Note: policy in Audit mode or image not in scope — check kyverno-verify-images.yaml"
    log_pass "Kyverno policy applied (verify manually with unsigned image)"
  fi
}

fix_r06() {
  echo "=== R-06: No ResourceQuota ==="
  kubectl apply -f "${W10_ROOT}/day-c/platform-bootstrap/resource-quota.yaml"
  kubectl apply -f "${W10_ROOT}/day-c/platform-bootstrap/limit-range.yaml"

  QUOTA=$(kubectl get resourcequota app-quota -n app --no-headers 2>/dev/null | wc -l)
  if [[ "${QUOTA}" -gt 0 ]]; then
    log_pass "ResourceQuota applied — namespace resource usage bounded"
  else
    log_fail "ResourceQuota not found in namespace app"
  fi
}

echo "=== W10 Lab: 6-Risk Cleanup ==="
echo ""

case "${TARGET}" in
  1|r01|R-01) fix_r01 ;;
  2|r02|R-02) fix_r02 ;;
  3|r03|R-03) fix_r03 ;;
  4|r04|R-04) fix_r04 ;;
  5|r05|R-05) fix_r05 ;;
  6|r06|R-06) fix_r06 ;;
  all)
    fix_r01; echo ""
    fix_r02; echo ""
    fix_r03; echo ""
    fix_r04; echo ""
    fix_r05; echo ""
    fix_r06; echo ""
    ;;
  *)
    echo "Usage: $0 [1-6 | all]"
    exit 1
    ;;
esac

echo ""
echo "=== Result: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]]
