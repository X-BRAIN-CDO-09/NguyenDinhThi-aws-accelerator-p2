# Day B: Secrets Rotation + Supply Chain Security

Thực hành về Secrets Management & Supply Chain:
- AWS Secrets Manager: rotation schedule, version staging (AWSCURRENT / AWSPENDING / AWSPREVIOUS)
- External Secrets Operator (ESO): SecretStore + ExternalSecret + `refreshInterval`
- ESO rotation flow: secret mới trong < 60s, pod không restart (mount từ Secret volume)
- Trivy: image scan trong CI, fail-on HIGH/CRITICAL, SARIF output cho GitHub Security tab
- Cosign/Sigstore: keyless OIDC signing (không cần key file lưu), key-based signing
- Kyverno `verifyImages`: admission reject nếu image chưa ký hoặc chữ ký không hợp lệ
- CVE exception ADR: exception phải có expiry date + owner — không exception vô thời hạn
