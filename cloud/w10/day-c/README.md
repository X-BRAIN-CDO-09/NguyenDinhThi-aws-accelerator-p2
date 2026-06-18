# Day C: Platform Integration + Runbook + Cost Guard

Thực hành về tích hợp toàn stack & vận hành:
- Full stack integration W8→W10: Terraform (VPC/EKS) → ArgoCD → RBAC → Gatekeeper → ESO
- ResourceQuota: giới hạn tổng CPU/memory/pod per namespace — một team không thể chiếm hết cluster
- LimitRange: default request/limit cho container chưa khai báo — tránh pod dùng unbounded resource
- AWS Cost Anomaly Detection: monitor theo service, alert SNS khi chi phí vượt ngưỡng bất thường
- Chaos engineering cơ bản: Chaos Mesh pod-kill → verify cluster self-heal (ArgoCD + K8s reconcile)
- Runbook template: cấu trúc SRE on-call guide — ai làm gì, kiểm tra gì, leo thang thế nào
- IR Playbook 6-step: quy trình xử lý security incident có hệ thống (không improvise khi stress)
