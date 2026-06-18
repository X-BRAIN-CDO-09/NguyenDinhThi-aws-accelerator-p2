# Lab: 6-Risk Cluster Cleanup + Cluster-Level Enforcement

Lab onsite T5–T6 (18–19/06/2026) tại Đà Nẵng với mentor Kiệt + Vương.

## 6 rủi ro cần xử lý

| # | Rủi ro | Triệu chứng | Fix |
|---|---|---|---|
| **R-01** | Container chạy root (no securityContext) | `kubectl get pods` → UID 0 | Gatekeeper `K8sNoRootContainer` enforce |
| **R-02** | Developer có ClusterAdmin | `kubectl get clusterrolebinding` → dev user | Xóa binding, áp RBAC tối thiểu từ `day-a/rbac/` |
| **R-03** | Secret hardcode trong manifest | Secret value plain-text trong YAML | Migrate sang ESO + AWS Secrets Manager |
| **R-04** | Image không được scan (no Trivy in CI) | CI pipeline không có bước scan | Thêm Trivy step từ `day-b/ci-trivy/trivy-scan.yaml` |
| **R-05** | Image không có chữ ký (no Cosign) | `cosign verify` fail | Thêm sign step + Kyverno policy từ `day-b/signing/` |
| **R-06** | Không có ResourceQuota | Pod có thể chiếm hết cluster memory | Apply quota từ `day-c/platform-bootstrap/resource-quota.yaml` |

## Mục tiêu cuối lab (Acceptance Criteria)

- [ ] Cluster có 3 role rõ ràng: `developer` / `sre` / `viewer` — đúng quyền tối thiểu
- [ ] 4 Gatekeeper constraints đang enforce (không chỉ audit)
- [ ] ESO rotate secret < 60s, pod không restart
- [ ] Admission reject unsigned image (Kyverno `verifyImages`)
- [ ] `kubectl auth can-i delete pods --as=alice` → `no`
- [ ] `kubectl auth can-i get pods --as=alice` → `yes`

## Cấu trúc lab
