#!/usr/bin/env bash
set -euo pipefail

# Verify Cosign image signature (keyless OIDC)
# Usage: ./cosign-verify.sh <image-ref>
# Example: ./cosign-verify.sh ghcr.io/org/backend@sha256:abc123...

IMAGE="${1:-}"
if [[ -z "${IMAGE}" ]]; then
  echo "Usage: $0 <image-ref>"
  echo "Example: $0 ghcr.io/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2/backend@sha256:..."
  exit 1
fi

GITHUB_ORG="X-BRAIN-CDO-09"
REPO="NguyenDinhThi-aws-accelerator-p2"

echo "=== Cosign Signature Verification ==="
echo "Image: ${IMAGE}"
echo ""

cosign verify \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "https://github.com/${GITHUB_ORG}/${REPO}/.github/workflows/.*" \
  "${IMAGE}" | jq '.[0] | {
    issuer: .optional.Issuer,
    subject: .optional.Subject,
    workflow: .optional."github-workflow-name",
    ref: .optional."github-ref"
  }'

echo ""
echo "PASS  Image signature verified — signed by GitHub Actions OIDC"
