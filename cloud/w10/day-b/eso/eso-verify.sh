#!/usr/bin/env bash
set -euo pipefail

# Verify ESO rotation: update secret in AWS → K8s Secret syncs < 60s → pod stays running
# Usage: ./eso-verify.sh
# Prereqs: aws CLI configured, kubectl configured, jq installed

NAMESPACE="app"
SECRET_NAME="db-credentials"
SM_SECRET_ID="/w10/db/credentials"
REGION="ap-southeast-1"
MAX_WAIT=90   # seconds

echo "=== ESO Rotation Verification ==="
echo ""

# 1. Record current secret value
OLD_VALUE=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.data.password}' | base64 -d)
echo "[1] Current K8s Secret password (truncated): ${OLD_VALUE:0:8}..."

# 2. Record pod restarts before rotation
POD_NAME=$(kubectl get pods -n "${NAMESPACE}" -l app=backend \
  -o jsonpath='{.items[0].metadata.name}')
RESTARTS_BEFORE=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
echo "[2] Pod ${POD_NAME} restarts before: ${RESTARTS_BEFORE}"

# 3. Update secret in AWS Secrets Manager
NEW_PASSWORD="rotated-$(date +%s)"
NEW_VALUE="{\"username\":\"dbadmin\",\"password\":\"${NEW_PASSWORD}\"}"
aws secretsmanager put-secret-value \
  --secret-id "${SM_SECRET_ID}" \
  --secret-string "${NEW_VALUE}" \
  --region "${REGION}" > /dev/null
echo "[3] AWS Secrets Manager updated with new password"

# 4. Wait for ESO to sync
echo "[4] Waiting up to ${MAX_WAIT}s for ESO to sync..."
ELAPSED=0
while [[ ${ELAPSED} -lt ${MAX_WAIT} ]]; do
  CURRENT=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" \
    -o jsonpath='{.data.password}' | base64 -d)
  if [[ "${CURRENT}" == "${NEW_PASSWORD}" ]]; then
    echo "    Synced after ${ELAPSED}s"
    break
  fi
  sleep 5
  ((ELAPSED+=5))
done

# 5. Verify sync happened
FINAL_VALUE=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.data.password}' | base64 -d)
if [[ "${FINAL_VALUE}" == "${NEW_PASSWORD}" ]]; then
  echo "[5] PASS  K8s Secret updated successfully"
else
  echo "[5] FAIL  K8s Secret not updated within ${MAX_WAIT}s"
  exit 1
fi

# 6. Verify no pod restart
RESTARTS_AFTER=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
if [[ "${RESTARTS_AFTER}" -eq "${RESTARTS_BEFORE}" ]]; then
  echo "[6] PASS  Pod did not restart (restarts: ${RESTARTS_AFTER})"
else
  echo "[6] FAIL  Pod restarted! before=${RESTARTS_BEFORE}, after=${RESTARTS_AFTER}"
  echo "    Note: Use volume mount (not env var) to avoid restarts on secret rotation"
  exit 1
fi

echo ""
echo "=== RESULT: PASS — ESO rotated secret in ${ELAPSED}s, no pod restart ==="
