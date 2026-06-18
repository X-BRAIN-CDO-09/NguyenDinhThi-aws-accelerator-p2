# Báo cáo thu hoạch tuần W10: Secure & Operate

Tuần này tập trung hardening cluster ở tầng infrastructure — không còn "developer hứa sẽ không chạy root", mà là hệ thống tự động từ chối vi phạm ngay tại admission. Kết hợp RBAC tối thiểu (Day A), secrets rotation tự động và supply chain integrity (Day B), tích hợp toàn stack thành mini platform vận hành được (Day C).

---

## 1. Day A: RBAC + Admission Policy

### Kiến thức cốt lõi:
- **RBAC Least Privilege:** 3 role rõ ràng — `developer` (chỉ deploy trong namespace `app`), `sre` (read all + exec + restart), `viewer` (read-only cluster-wide). Không role nào được phép xem Secret trực tiếp — secrets chỉ qua ESO. ServiceAccount `ci-deployer` riêng cho CI pipeline, không dùng user cá nhân.
- **Gatekeeper — ConstraintTemplate vs Constraint:** ConstraintTemplate định nghĩa schema + Rego logic (reusable). Constraint là một instance apply template đó với params cụ thể. Bắt đầu bằng `audit` mode để thấy violations mà không block, sau đó chuyển `deny` khi confident.
- **ValidatingAdmissionPolicy (native K8s 1.30+):** CEL expressions chạy in-process API server, không cần deploy webhook riêng. Phù hợp cho policies đơn giản (no privileged, no hostNetwork). Gatekeeper vẫn cần cho Rego phức tạp.

### Các cấu hình đã làm:
- [rbac/developer-role.yaml](day-a/rbac/developer-role.yaml): Role namespace-scoped, quyền tối thiểu để deploy nhưng không delete, không chạm RBAC.
- [rbac/sre-clusterrole.yaml](day-a/rbac/sre-clusterrole.yaml): ClusterRole có exec + delete pod + update deployment cho incident response.
- [rbac/viewer-clusterrole.yaml](day-a/rbac/viewer-clusterrole.yaml): ClusterRole read-only toàn cluster, không write bất kỳ resource nào.
- [rbac/serviceaccount-ci.yaml](day-a/rbac/serviceaccount-ci.yaml): ServiceAccount `ci-deployer` + IRSA annotation + Role chỉ deploy trong namespace `app`.
- [rbac/rbac-test.sh](day-a/rbac/rbac-test.sh): Tự động kiểm tra `kubectl auth can-i` cho từng role, output PASS/FAIL.
- [policies/ct-no-root.yaml](day-a/policies/ct-no-root.yaml): ConstraintTemplate Rego kiểm tra `runAsNonRoot: true`.
- [policies/c-no-root.yaml](day-a/policies/c-no-root.yaml): Constraint enforce, áp vào namespace `app`.
- [policies/ct-required-labels.yaml](day-a/policies/ct-required-labels.yaml): ConstraintTemplate yêu cầu labels `app` + `env`.
- [policies/c-required-labels.yaml](day-a/policies/c-required-labels.yaml): Constraint audit mode (log violation, không block).
- [policies/validating-admission-policy.yaml](day-a/policies/validating-admission-policy.yaml): Native VAP block `privileged: true`, `hostNetwork`, `hostPID`.

---

## 2. Day B: Secrets Rotation + Supply Chain Security

### Kiến thức cốt lõi:
- **ESO rotation không restart pod:** ESO poll AWS Secrets Manager mỗi `refreshInterval` (60s), cập nhật K8s Secret object. Pod mount Secret dưới dạng **volume** sẽ thấy file mới mà không cần restart. Nếu dùng `env:` thay vì `volumeMount:` thì cần restart — đây là lý do dùng volume mount cho dynamic secrets.
- **Cosign keyless OIDC:** GitHub Actions có OIDC identity (`id-token: write`). Cosign dùng identity này xin certificate từ Fulcio (CA), ký image, ghi vào Rekor (transparency log). Không có private key nào cần lưu trữ — key chỉ tồn tại trong 10 phút của CI run. Verify bằng Issuer + Subject regexp.
- **Trivy fail-fast vs CVE exception ADR:** `exit-code: 1` trên HIGH/CRITICAL bảo vệ production khỏi known-bad images. Khi exception cần thiết (no fix available), phải có: CVE ID, affected package, lý do technical, expiry date, owner — không được exception vô thời hạn.

### Các cấu hình đã làm:
- [eso/secretstore-aws.yaml](day-b/eso/secretstore-aws.yaml): SecretStore connect tới AWS Secrets Manager qua IRSA — không có static credential trong cluster.
- [eso/externalsecret-db.yaml](day-b/eso/externalsecret-db.yaml): ExternalSecret `db-credentials`, `refreshInterval: 60s`, pull từ `/w10/db/credentials`.
- [eso/eso-verify.sh](day-b/eso/eso-verify.sh): Script test end-to-end: update secret ở AWS → verify K8s Secret sync < 60s → verify pod không restart.
- [signing/cosign-keyless.yaml](day-b/signing/cosign-keyless.yaml): GitHub Actions workflow build + push + ký image với Cosign OIDC.
- [signing/cosign-verify.sh](day-b/signing/cosign-verify.sh): Verify chữ ký image với `--certificate-oidc-issuer` + `--certificate-identity-regexp`.
- [signing/kyverno-verify-images.yaml](day-b/signing/kyverno-verify-images.yaml): ClusterPolicy `Enforce` — reject pod nếu image chưa ký, `mutateDigest: true` phòng tag mutation.
- [ci-trivy/trivy-scan.yaml](day-b/ci-trivy/trivy-scan.yaml): GitHub Actions Trivy scan, exit-code=1 khi có HIGH/CRITICAL, upload SARIF lên GitHub Security tab.
- [ci-trivy/exception-policy.yaml](day-b/ci-trivy/exception-policy.yaml): ADR template CVE exception với trường `expiry_date` bắt buộc.

---

## 3. Day C: Platform Integration + Runbook + Cost Guard

### Kiến thức cốt lõi:
- **ResourceQuota vs LimitRange:** ResourceQuota giới hạn tổng resource của toàn namespace (tổng CPU/memory/số pod). LimitRange đặt default request/limit cho từng container chưa khai báo — tránh pod unbounded. Dùng cả hai cùng nhau: Quota bảo vệ cluster, LimitRange bảo vệ node.
- **AWS Cost Anomaly Detection:** ML-based, học baseline từ 10–14 ngày historical data rồi alert khi spend bất thường. Tốt hơn alert ngưỡng cứng vì tự adjust theo growth. Cần configure monitor (per SERVICE) + subscription (threshold + frequency). Alert via SNS → email/Slack.
- **IR Playbook 6-step là muscle memory:** Trong incident thật, người bị stress sẽ improvise sai. Playbook định sẵn: Detect → Triage → Contain → Eradicate → Recover → Post-mortem. Mỗi step có commands cụ thể để chạy, không phải văn bản mô tả. Blameless post-mortem tìm lỗi hệ thống, không tìm người có lỗi.

### Các cấu hình đã làm:
- [platform-bootstrap/bootstrap.sh](day-c/platform-bootstrap/bootstrap.sh): One-click apply toàn bộ security stack theo thứ tự đúng (Gatekeeper → RBAC → ESO → Policies → Quotas).
- [platform-bootstrap/resource-quota.yaml](day-c/platform-bootstrap/resource-quota.yaml): ResourceQuota namespace `app`: 20 pods, 4 CPU request, 8Gi memory request.
- [platform-bootstrap/limit-range.yaml](day-c/platform-bootstrap/limit-range.yaml): LimitRange default 100m/128Mi request, 200m/256Mi limit cho container không khai báo.
- [platform-bootstrap/cost-anomaly.tf](day-c/platform-bootstrap/cost-anomaly.tf): Terraform tạo Cost Anomaly Monitor per-SERVICE + Subscription alert $20/day (daily) và $50/day (immediate).
- [platform-bootstrap/chaos-test.yaml](day-c/platform-bootstrap/chaos-test.yaml): Chaos Mesh pod-kill mỗi 5 phút + NetworkChaos partition test graceful degradation.
- [runbooks/runbook-template.md](day-c/runbooks/runbook-template.md): Skeleton SRE runbook: symptoms → diagnosis → remediation → escalation → post-mortem link.
- [runbooks/ir-playbook-6step.md](day-c/runbooks/ir-playbook-6step.md): IR 6-step đầy đủ với commands kubectl + AWS CLI cụ thể cho từng step.
- [runbooks/pod-compromise.md](day-c/runbooks/pod-compromise.md): Decision tree 5 phút đầu khi pod bị compromise — cordon, preserve evidence, delete, rotate.

---

## 4. Lab — 6-Risk Cluster Cleanup + Cluster-Level Enforcement

Chuẩn bị cho onsite T5–T6: cluster có sẵn 6 rủi ro đã biết, cleanup từng cái một theo thứ tự.

**Setup script:** [lab/setup.sh](lab/setup.sh) — bootstrap Gatekeeper + RBAC + ESO + Kyverno + Quotas lên fresh cluster.

**Cleanup script:** [lab/cleanup.sh](lab/cleanup.sh) — fix từng risk với `./cleanup.sh [1-6]`, có auto-verification sau mỗi fix.

**Acceptance criteria cuối lab:**
- 3 roles enforce (rbac-test.sh PASS toàn bộ)
- 4 Gatekeeper constraints ở enforce mode
- ESO rotate < 60s, no pod restart (eso-verify.sh PASS)
- Kyverno reject unsigned image
