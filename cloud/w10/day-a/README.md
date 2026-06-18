# Day A: RBAC + Admission Policy

Thực hành về RBAC & Admission Control:
- RBAC: Role, RoleBinding, ClusterRole, ClusterRoleBinding
- Service Account cho workload + CI/CD pipeline
- `kubectl auth can-i` — kiểm tra quyền trực tiếp, không đoán
- OPA Rego cơ bản — policy-as-code, declarative, testable
- Gatekeeper: ConstraintTemplate (schema + Rego) vs Constraint (instance), audit vs enforce mode
- ValidatingAdmissionPolicy native (K8s 1.30+) — CEL expressions, không cần webhook riêng
