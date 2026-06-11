# W9 Lab Final — Ship Smartly 🚀

> **Bài lab hoàn chỉnh** kết hợp 3 trụ cột từ 2 slide W9:
> - 🌅 Buổi sáng: **GitOps & CI/CD** (ArgoCD App-of-Apps)
> - 🌇 Buổi chiều: **Observability** (SLO/Burn-Rate) + **Canary** (Auto-Abort)

---

## Kiến Trúc Tổng Quan

```
git push ──► GitHub
                │
         ArgoCD root.yaml (apply 1 lần)
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
infra (wave0) backend(wave1) frontend(wave2)
    │           │
Prometheus   Argo Rollout
Grafana      (Canary 20→50→100%)
OTel             │
                 ▼
          AnalysisTemplate
          (query Prometheus)
                 │
         success_rate < 95%
                 │
             AUTO-ABORT ✓
```

---

## Cấu Trúc Thư Mục

```
lab-final/
├── .github/workflows/validate.yaml     # CI: kubeconform validate YAML
├── argocd/
│   ├── root.yaml                        # Apply 1 lần duy nhất!
│   └── apps/
│       ├── kube-prometheus-stack.yaml   # Helm: Prometheus + Grafana
│       ├── argo-rollouts.yaml           # Helm: Argo Rollouts controller
│       ├── infra.yaml                   # wave 0: monitoring
│       ├── backend.yaml                 # wave 1: API
│       └── frontend.yaml               # wave 2: UI
├── app/
│   ├── app.py                           # Flask API + /metrics
│   └── Dockerfile
├── backend/k8s/
│   ├── namespace.yaml                   # wave -1
│   ├── secret.yaml                      # wave 0
│   ├── rollout.yaml                     # Canary Rollout
│   ├── analysis-template.yaml           # Auto-abort rule
│   ├── service-stable.yaml              # :30080
│   └── service-canary.yaml             # :30081
├── frontend/k8s/
│   ├── configmap.yaml                   # Dark/Light UI HTML
│   ├── deployment.yaml
│   └── service.yaml                    # :30090
├── infra/k8s/
│   ├── otel-collector.yaml
│   ├── prometheus-rule.yaml             # SLO burn-rate alerts
│   └── servicemonitor-backend.yaml
├── setup.sh                             # One-click setup
└── k6-load-test.js                      # Load test
```

---

## 🚀 Hướng Dẫn Chạy Lab

### Bước 0: Chuẩn bị

```bash
# Khởi động minikube (cần 4 CPU + 6GB RAM cho Prometheus stack)
minikube start -p w9 --cpus=4 --memory=6g

# Clone/fork repo về máy, cập nhật repoURL:
# Tìm tất cả <YOUR_USERNAME>/<YOUR_REPO> trong argocd/ và thay bằng repo thật
grep -r "YOUR_USERNAME" argocd/
```

### Bước 1: Cài đặt tự động (Lab 1)

```bash
chmod +x setup.sh && ./setup.sh
```

Script sẽ:
1. Kiểm tra prerequisites (kubectl, helm, docker)
2. Cài ArgoCD
3. Cài kubectl-argo-rollouts plugin
4. Build Flask image: `w9-api:1`
5. Apply root Application (App-of-Apps)
6. In URLs + credentials

### Bước 2: Build Flask image (Lab 2)

```bash
# Build image Flask với prometheus_flask_exporter
docker build -t w9-api:1 app/

# Load vào minikube
minikube image load w9-api:1 -p w9

# Verify
minikube image ls -p w9 | grep w9-api
```

### Bước 3: Push và xem ArgoCD sync

```bash
# Sau khi cập nhật repoURL:
git add . && git commit -m "init: lab-final" && git push

# Quan sát ArgoCD tự tạo các App con (KHÔNG kubectl apply)
kubectl -n argocd get applications
# Expected:
# NAME                      STATUS   HEALTH
# root                      Synced   Healthy
# kube-prometheus-stack     Synced   Healthy
# argo-rollouts             Synced   Healthy
# infra                     Synced   Healthy
# backend                   Synced   Healthy
# frontend                  Synced   Healthy
```

### Bước 4: Xem Prometheus scrape metrics (Lab 3)

```bash
# Port-forward Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090 &

# Truy cập http://localhost:9090 → Targets
# Kiểm tra job "backend" UP

# Query test:
curl "localhost:9090/api/v1/query?query=flask_http_request_total"
```

### Bước 5: Chạy load test để trigger SLO alert

```bash
# Chạy k6 (cần cài: https://k6.io/docs/get-started/installation/)
TARGET_URL=http://$(minikube ip -p w9):30080 k6 run k6-load-test.js

# Xem alert trên Prometheus:
# http://localhost:9090/alerts → BackendAPIFastBurn fired!
```

### Bước 6: Test Canary Auto-Abort (Challenge ⭐)

```bash
# Đổi VERSION và ERROR_RATE trong backend/k8s/rollout.yaml:
#   VERSION: "v1" → "v2"
#   ERROR_RATE: "0" → "0.2"   (20% lỗi giả → trigger abort)
git commit -am "deploy: backend v2 with 20% error rate" && git push

# Theo dõi rollout:
kubectl argo rollouts get rollout backend -n demo --watch

# Expected kịch bản xảy ra:
# Step 1: setWeight 20%  → 20% traffic → canary pods
# Step 2: AnalysisTemplate query Prometheus mỗi 30s
# Step 3: success_rate = 80% < 95% → FAIL
# Step 4: failureLimit: 2 lần → ABORT
# Step 5: 100% traffic về bản cũ (v1) tự động!
```

### Bước 7: Xem Grafana Dashboard

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80 &
# http://localhost:3000  admin / admin123
# Import dashboard từ: infra/k8s/grafana-dashboard-cm.yaml
```

---

## 📊 SLO & Alert Configuration

| Thông số | Giá trị |
|----------|---------|
| SLO | 99.5% availability / 30 ngày |
| Error Budget | 0.5% = 216 phút/tháng |
| Fast Burn | Burn rate > 14.4× → CRITICAL (cháy trong 2 ngày) |
| Slow Burn | Burn rate > 6× → WARNING (cháy trong 5 ngày) |
| Analysis threshold | success_rate < 95% → abort canary |

---

## ✅ Challenge Checklist

- [ ] Mọi thay đổi qua Git → ArgoCD Synced (không kubectl tay)
- [ ] `git revert HEAD && git push` → rollback < 5 phút
- [ ] 1 SLO + 1 alert fire khi inject lỗi
- [ ] **Canary bản lỗi TỰ ABORT** về bản cũ *(quan trọng nhất)*

---

## 🛠️ Troubleshooting

```bash
# Xem tất cả pods:
kubectl get pods -A

# Xem rollout chi tiết:
kubectl describe rollout backend -n demo

# Xem analysis run:
kubectl get analysisrun -n demo
kubectl describe analysisrun <name> -n demo

# Debug Prometheus rule:
kubectl get prometheusrule -n monitoring
kubectl describe prometheusrule slo-burn-rate-alerts -n monitoring

# Reset rollout về stable:
kubectl argo rollouts abort backend -n demo
kubectl argo rollouts undo backend -n demo
```

---

## 📚 Tài Liệu Tham Khảo

- [Argo Rollouts — Concepts & Analysis](https://argoproj.github.io/argo-rollouts/concepts/)
- [Google SRE Book — SLO/SLI/Error Budget](https://sre.google/sre-book/service-level-objectives/)
- [Multi-window Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos/)
- [prometheus-flask-exporter](https://github.com/rycus86/prometheus_flask_exporter)
- [k6 Load Testing](https://k6.io/docs/)
