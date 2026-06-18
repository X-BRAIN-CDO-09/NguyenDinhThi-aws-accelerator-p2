#!/usr/bin/env bash
set -euo pipefail

# Verify RBAC permissions for each role using kubectl auth can-i --as
# Usage: ./rbac-test.sh
# Requires: kubectl configured to target cluster, roles already applied

NAMESPACE="app"
PASS=0
FAIL=0

check() {
  local role="$1"
  local verb="$2"
  local resource="$3"
  local expect="$4"   # "yes" or "no"
  local ns_flag="--namespace=${NAMESPACE}"

  result=$(kubectl auth can-i "${verb}" "${resource}" \
    --as="system:serviceaccount:${NAMESPACE}:${role}" \
    ${ns_flag} 2>/dev/null || true)

  if [[ "${result}" == "${expect}" ]]; then
    echo "  PASS  [${role}] ${verb} ${resource} = ${result}"
    ((PASS++))
  else
    echo "  FAIL  [${role}] ${verb} ${resource}: expected=${expect}, got=${result}"
    ((FAIL++))
  fi
}

echo "=== RBAC Test — namespace: ${NAMESPACE} ==="
echo ""

echo "--- developer ---"
check developer get  pods        yes
check developer list deployments yes
check developer create deployments yes
check developer delete pods     no
check developer get  secrets    no

echo ""
echo "--- viewer ---"
check viewer get  pods        yes
check viewer list deployments yes
check viewer create deployments no
check viewer delete pods      no
check viewer get  secrets     no

echo ""
echo "--- ci-deployer ---"
check ci-deployer create deployments yes
check ci-deployer patch  rollouts    yes
check ci-deployer delete deployments no
check ci-deployer get    pods        yes

echo ""
echo "=== Result: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]]
