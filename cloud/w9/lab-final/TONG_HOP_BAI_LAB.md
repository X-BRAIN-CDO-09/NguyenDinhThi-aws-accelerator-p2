# 📚 TỔNG HỢP BÀI LAB W9 — DELIVER SMARTLY
> **Chương trình:** X-BRAIN CDO-09 | **Tuần:** W9 | **Cập nhật:** 2026-06-11

---

## 📋 MỤC LỤC

1. [Triết lý W9 — Deliver Smartly là gì?](#1-triết-lý-w9--deliver-smartly-là-gì)
2. [Tech Stack W9](#2-tech-stack-w9)
3. [Day-A: GitOps với ArgoCD](#3-day-a-gitops-với-argocd)
4. [Day-B: Observability — SLO, SLI, Error Budget, Burn-Rate](#4-day-b-observability--slo-sli-error-budget-burn-rate)
5. [Day-C: Canary Deployment với Argo Rollouts](#5-day-c-canary-deployment-với-argo-rollouts)
6. [🔥 Lab-Final: Ship Smartly — Phân tích chi tiết từng file](#6-lab-final-ship-smartly--phân-tích-chi-tiết-từng-file)
   - [Tổng kiến trúc hệ thống](#61-tổng-kiến-trúc-hệ-thống)
   - [Luồng giao tiếp giữa các file](#62-luồng-giao-tiếp-giữa-các-file)
   - [Nhóm 1: Flask Backend App](#63-nhóm-1-flask-backend-app)
   - [Nhóm 2: CI/CD — GitHub Actions](#64-nhóm-2-cicd--github-actions)
   - [Nhóm 3: GitOps — ArgoCD App-of-Apps](#65-nhóm-3-gitops--argocd-app-of-apps)
   - [Nhóm 4: Observability Stack](#66-nhóm-4-observability-stack)
   - [Nhóm 5: Canary Deployment — Argo Rollouts](#67-nhóm-5-canary-deployment--argo-rollouts)
   - [Nhóm 6: Frontend Dashboard](#68-nhóm-6-frontend-dashboard)
   - [Nhóm 7: Load Test với k6](#69-nhóm-7-load-test-với-k6)
   - [Nhóm 8: Setup Script](#610-nhóm-8-setup-script)
7. [Hướng dẫn chạy Lab từng bước](#7-hướng-dẫn-chạy-lab-từng-bước)
8. [Câu lệnh quan trọng giải thích chi tiết](#8-câu-lệnh-quan-trọng-giải-thích-chi-tiết)
9. [Các kịch bản test và kết quả mong đợi](#9-các-kịch-bản-test-và-kết-quả-mong-đợi)
10. [Troubleshooting thường gặp](#10-troubleshooting-thường-gặp)

---

## 1. Triết lý W9 — Deliver Smartly là gì?

### Vấn đề của cách deploy truyền thống

```
❌ CÁCH CŨ (Manual / Push Model):
Developer → SSH → server → git pull → restart service
                           ↑
                    Rủi ro: ai quên bước này?
                    Ai biết trạng thái thật của server?
                    Nếu sập giữa chừng thì sao?
```

### W9 giải quyết 3 vấn đề lớn

| Vấn đề | Giải pháp W9 | Công cụ |
|--------|-------------|---------|
| **Configuration Drift** — Code trên Git ≠ thực tế trên cluster | **GitOps** — Git là nguồn sự thật duy nhất, controller tự đồng bộ | ArgoCD |
| **Mù về chất lượng dịch vụ** — không biết users đang bị ảnh hưởng thế nào | **SLO/SLI** — đo lường từ góc nhìn người dùng + Burn-Rate Alerts | Prometheus + Grafana |
| **Deploy rủi ro cao** — deploy = cầu nguyện may mắn | **Canary + Auto-Abort** — thử nghiệm từng phần, tự rollback khi lỗi | Argo Rollouts |

---

## 2. Tech Stack W9

| Công nghệ | Version | Vai trò cụ thể |
|-----------|---------|----------------|
| **ArgoCD** | stable | GitOps controller — pull state từ Git, apply vào K8s, self-heal |
| **Argo Rollouts** | 2.37.7 | Thay thế K8s Deployment — điều phối canary traffic |
| **kube-prometheus-stack** | 65.1.1 | Bundle: Prometheus + Grafana + AlertManager + CRDs |
| **OpenTelemetry Collector** | 0.97.0 | Thu thập metrics từ app → export cho Prometheus |
| **Flask** | 3.0.3 | Backend API viết bằng Python |
| **prometheus-flask-exporter** | 0.23.1 | Tự động thêm `/metrics` endpoint vào Flask app |
| **kubeconform** | 0.6.7 | Validate K8s YAML schema trong CI pipeline |
| **k6** | Latest | Load testing — giả lập traffic thật |
| **GitHub Actions** | Latest | CI gate — chặn PR nếu YAML không hợp lệ |
| **NGINX** | alpine | Web server cho frontend dashboard |
| **Helm** | Latest | Package manager cài Prometheus stack qua ArgoCD |
| **Minikube** | Latest | K8s cluster local để chạy toàn bộ lab |

---

## 3. Day-A: GitOps với ArgoCD

### Nguyên lý Pull Model

```
❌ PUSH MODEL (truyền thống):
CI Server ──[có kubeconfig]──► kubectl apply ──► K8s Cluster
             Rủi ro bảo mật!

✅ PULL MODEL (GitOps):
Git Repo ◄──[pull]── ArgoCD Controller (chạy BÊN TRONG cluster)
                         │
                         └──► Reconcile ──► K8s Cluster
                         ArgoCD tự làm, không cần ai trigger!
```

### File `day-a/argocd-app.yaml` — ArgoCD Application cơ bản

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
  namespace: argocd        # Application object luôn ở namespace argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # Khi xóa App → xóa resources con
spec:
  project: default
  source:
    repoURL: 'https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2.git'
    targetRevision: HEAD   # Theo branch mới nhất (HEAD)
    path: cloud/w9/day-a   # Thư mục chứa K8s manifests
  destination:
    server: 'https://kubernetes.default.svc'  # Cluster hiện tại
    namespace: app
  syncPolicy:
    automated:
      prune: true     # Xóa resource trong K8s nếu xóa file khỏi Git
      selfHeal: true  # Tự sửa nếu ai kubectl edit trực tiếp
    syncOptions:
      - CreateNamespace=true  # Tự tạo namespace nếu chưa có
```

**Giải thích từng field quan trọng:**
- `prune: true` — Nếu bạn xóa file `service.yaml` khỏi Git → ArgoCD tự xóa Service đó trên cluster
- `selfHeal: true` — Nếu ai đó `kubectl scale deployment simple-app --replicas=1` → ArgoCD phát hiện drift → tự apply lại replicas=2 từ Git
- `targetRevision: HEAD` — Luôn theo HEAD của branch được khai báo

### File `day-a/gitops-pipeline.yaml` — CI Pipeline Day-A

```yaml
# CI Gate trước khi ArgoCD sync:
jobs:
  validate:
    steps:
      # Bước 1: Lint bảo mật (kube-linter)
      - name: Run kube-linter
        run: kube-linter lint cloud/w9/day-a/k8s-manifests.yaml
        # Kiểm tra: có readinessProbe không? resource limits không? runAsRoot không?

      # Bước 2: Dry-run validate YAML syntax
      - name: Dry-run Apply
        run: kubectl apply --dry-run=client -f cloud/w9/day-a/k8s-manifests.yaml
        # Không tạo resource thật — chỉ validate schema K8s

  deploy:
    needs: validate             # Phải qua validate trước
    if: github.ref == 'refs/heads/main'  # Chỉ deploy khi merge vào main
    steps:
      # ArgoCD có automated sync → không cần trigger tay
      # Merge vào main = ArgoCD tự phát hiện và sync
```

---

## 4. Day-B: Observability — SLO, SLI, Error Budget, Burn-Rate

### Toán học của SLO (cần thuộc lòng)

```
SLI (Service Level Indicator):
  = Số request 2xx / Tổng số request × 100%
  = Tỉ lệ thành công thực tế đo được

SLO (Service Level Objective):
  = Cam kết: SLI ≥ 99.5% trong 30 ngày
  = Mục tiêu, không phải đảm bảo 100%

Error Budget:
  = 100% - SLO = 100% - 99.5% = 0.5%
  = 0.5% × 30 ngày × 24h × 60 phút = 216 phút/tháng
  = Tổng thời gian ĐƯỢC PHÉP lỗi trong tháng

Burn Rate:
  = Tốc độ tiêu hao Error Budget so với bình thường
  = 1.0 → bình thường, cháy đúng kế hoạch
  = 14.4 → FAST BURN → budget hết trong 30/14.4 ≈ 2 ngày → NGUY CẤP!
  = 6.0 → SLOW BURN → budget hết trong 30/6 = 5 ngày → CẦN XỬ LÝ
```

### File `day-b/alerts-burn-rate.yaml` — PrometheusRule cơ bản

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule  # CRD — không phải K8s built-in, cần kube-prometheus-stack
metadata:
  name: slo-burn-rate-alerts
  namespace: app
  labels:
    role: alert-rules
    prometheus: k8s   # Label này để Prometheus biết rule này dành cho nó
spec:
  groups:
  - name: simple-app-slo
    rules:
    # ── Fast Burn Alert ──
    # Điều kiện: error_rate_1h > 14.4% VÀ error_rate_5m > 14.4%
    # "và" vì: 1h window = xu hướng thật; 5m window = xác nhận vẫn đang xảy ra
    - alert: SimpleAppAvailabilityFastBurnPage
      expr: |
        (
          sum(rate(http_requests_total{status!~"2.."}[1h]))
          /
          sum(rate(http_requests_total[1h]))
        ) > 0.144
        and
        (
          sum(rate(http_requests_total{status!~"2.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
        ) > 0.144
      for: 2m         # Phải duy trì 2 phút để tránh alert giả
      labels:
        severity: critical
      annotations:
        summary: "Lỗi nghiêm trọng! Error budget cháy nhanh"
```

### File `day-b/otel-collector.yaml` — Pipeline OTel

```
App Flask ──[/metrics endpoint]──► OTel Prometheus Receiver
                                          │
                                   OTel Processors
                                   (batch + memory_limiter)
                                          │
                                   OTel Prometheus Exporter
                                   (expose port 8889)
                                          │
                              Prometheus scrape :8889
```

---

## 5. Day-C: Canary Deployment với Argo Rollouts

### Tại sao không dùng K8s Deployment thông thường?

```
K8s RollingUpdate (mặc định):
  v1: [Pod1, Pod2, Pod3] → thay dần → v2: [Pod1, Pod2, Pod3]
  Vấn đề: v2 có bug → 100% users bị ảnh hưởng trước khi phát hiện!

Argo Rollouts Canary:
  v1: [Pod1, Pod2, Pod3] (stable)
  v2: [PodA] (canary, chỉ 20% traffic)
  → AnalysisTemplate đo chất lượng v2
  → Nếu lỗi → abort → chỉ 20% users bị ảnh hưởng ngắn!
  → Nếu ổn → 50% → 100%
```

### File `day-c/rollout.yaml` — Canary đơn giản

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout          # KHÔNG phải apps/v1 Deployment!
metadata:
  name: simple-app
  namespace: app
spec:
  replicas: 2
  strategy:
    canary:
      analysis:
        templates:
          - templateName: success-rate-analysis  # Tham chiếu AnalysisTemplate
        args:
          - name: service-name
            value: simple-app-service

      steps:             # Các bước canary
        - setWeight: 20  # Bước 1: 20% traffic → canary pod
        - pause: {duration: 30s}  # Đợi 30s để thu thập metrics
        - setWeight: 50  # Bước 2: 50% traffic
        - pause: {duration: 30s}
        - setWeight: 100 # Bước 3: 100% → promote thành stable
```

---

## 6. 🔥 Lab-Final: Ship Smartly — Phân tích chi tiết từng file

### 6.1 Tổng kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                                 │
│  cloud/w9/lab-final/                                                    │
│  ├── argocd/              ← ArgoCD quản lý                             │
│  ├── backend/k8s/         ← Backend manifests                          │
│  ├── frontend/k8s/        ← Frontend manifests                         │
│  └── infra/k8s/           ← Monitoring manifests                       │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │  git push
                               ▼
                    GitHub Actions CI
                    (validate.yaml)
                    kubeconform -strict *.yaml
                    │  PASS
                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (Minikube -p w9)                   │
│                                                                           │
│  namespace: argocd                                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │ ArgoCD root.yaml (App-of-Apps)                                       │ │
│  │   ├── kube-prometheus-stack [wave 0] → namespace: monitoring        │ │
│  │   ├── argo-rollouts         [wave 0] → namespace: argo-rollouts     │ │
│  │   ├── infra                 [wave 0] → namespace: monitoring        │ │
│  │   ├── backend               [wave 1] → namespace: demo              │ │
│  │   └── frontend              [wave 2] → namespace: demo              │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  namespace: monitoring                    namespace: demo                 │
│  ┌───────────────────────────┐           ┌────────────────────────────┐  │
│  │ Prometheus :9090          │◄──scrape──│ Flask API (backend pods)   │  │
│  │ Grafana :3000             │           │ /metrics (port 8080)       │  │
│  │ AlertManager              │           │                            │  │
│  │ OTel Collector :8889      │           │ Argo Rollout               │  │
│  └───────────────────────────┘           │  ├── stable service :30080 │  │
│           ▲                              │  └── canary service :30081 │  │
│           │ ServiceMonitor               │                            │  │
│           └──────────────────────────────┤ Frontend NGINX :30090      │  │
│                                          └────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                    │ k6 load test          │ user browser
                    ▼                       ▼
              http://MINIKUBE_IP:30080    http://MINIKUBE_IP:30090
```

---

### 6.2 Luồng giao tiếp giữa các file

#### Khi Developer thay đổi code backend

```
1. Sửa backend/k8s/rollout.yaml
   (đổi VERSION: "v1" → "v2", ERROR_RATE: "0" → "0.2")
          │
          ▼
2. git push → GitHub
          │ trigger
          ▼
3. .github/workflows/validate.yaml (CI)
   kubeconform -strict backend/k8s/
   └── PASS → PR có thể merge
          │ merge to main
          ▼
4. ArgoCD phát hiện thay đổi (poll mỗi 3 phút)
   argocd/apps/backend.yaml → trỏ đến backend/k8s/
          │
          ▼
5. Argo Rollouts bắt đầu canary
   rollout.yaml:
   ├── Step 1: setWeight 20%
   │     └── backend-preview-service (canary) :30081 nhận 20% traffic
   │
   ├── AnalysisRun bắt đầu (startingStep: 1)
   │     └── analysis-template.yaml query Prometheus mỗi 30s:
   │           sum(rate(flask_http_request_total{status!~"5.."}[2m]))
   │           / sum(rate(flask_http_request_total[2m]))
   │
   ├── Flask pods tự báo cáo lên /metrics (prometheus_flask_exporter)
   │     └── servicemonitor-backend.yaml nói Prometheus scrape /metrics mỗi 15s
   │
   ├── Prometheus lưu metric: flask_http_request_total
   │
   ├── AnalysisTemplate đọc metric → success_rate < 95% (vì ERROR_RATE=0.2)
   │
   └── ABORT! → Rollback về v1 tự động
          │
          ▼
6. prometheus-rule.yaml phát hiện burn rate cao
   → Alert BackendAPIFastBurn FIRES
   → AlertManager gửi notification
```

#### Sơ đồ quan hệ file → file

```
argocd/root.yaml
    │  watches
    ├──► argocd/apps/kube-prometheus-stack.yaml
    │         └── Helm: Prometheus + Grafana (namespace: monitoring)
    │               └── tạo ra CRDs: ServiceMonitor, PrometheusRule
    │
    ├──► argocd/apps/argo-rollouts.yaml
    │         └── Helm: Argo Rollouts controller (namespace: argo-rollouts)
    │               └── tạo ra CRDs: Rollout, AnalysisTemplate, AnalysisRun
    │
    ├──► argocd/apps/infra.yaml
    │         └── applies infra/k8s/:
    │               ├── otel-collector.yaml
    │               │     (nhận metrics → export port 8889)
    │               ├── servicemonitor-backend.yaml
    │               │     (nói Prometheus: scrape backend pods /metrics)
    │               └── prometheus-rule.yaml
    │                     (định nghĩa SLO alerts: FastBurn, SlowBurn, Breach)
    │
    ├──► argocd/apps/backend.yaml
    │         └── applies backend/k8s/:
    │               ├── namespace.yaml (wave -1: tạo namespace "demo" trước)
    │               ├── secret.yaml    (wave  0: tạo DB credentials)
    │               ├── analysis-template.yaml (wave 0: định nghĩa logic abort)
    │               ├── service-stable.yaml   (wave 1: stable endpoint :30080)
    │               ├── service-canary.yaml   (wave 1: canary endpoint :30081)
    │               └── rollout.yaml  (wave 1: Canary Rollout sử dụng tất cả trên)
    │                     ├── dùng secret.yaml → env vars DB_HOST, DB_PASSWORD
    │                     ├── dùng service-stable.yaml → stableService
    │                     ├── dùng service-canary.yaml → canaryService
    │                     └── dùng analysis-template.yaml → auto-abort logic
    │
    └──► argocd/apps/frontend.yaml
              └── applies frontend/k8s/:
                    ├── configmap.yaml (HTML + nginx config)
                    ├── deployment.yaml (mount configmap vào /usr/share/nginx/html)
                    └── service.yaml (NodePort :30090)

app/app.py ──[docker build]──► Docker image w9-api:1
                                    └── chạy trong rollout.yaml containers
                                    └── expose /metrics (prometheus_flask_exporter)
                                    └── Prometheus scrape qua servicemonitor

k6-load-test.js ──► gửi traffic đến :30080 (stable) và :30081 (canary)
                     └── trigger SLO alerts và AnalysisTemplate check
```

---

### 6.3 Nhóm 1: Flask Backend App

#### `app/app.py` — Backend API

```python
"""
Flask API với prometheus_flask_exporter
"""
import os
import random
from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

# ⭐ PrometheusMetrics tự thêm /metrics endpoint
# Tự động track 2 metric quan trọng:
#   flask_http_request_total{method, status, path}   ← dùng trong AnalysisTemplate!
#   flask_http_request_duration_seconds              ← dùng cho latency SLO
metrics = PrometheusMetrics(app)

ERROR_RATE = float(os.getenv("ERROR_RATE", "0"))   # inject từ rollout.yaml env
VERSION    = os.getenv("VERSION", "v1")             # để distinguish stable vs canary

@app.get("/")
def index():
    # ⭐ Error Injection — Khi ERROR_RATE=0.2: 20% request trả 500
    if random.random() < ERROR_RATE:
        return jsonify(error="injected_error", version=VERSION), 500
    return jsonify(ok=True, version=VERSION), 200

@app.get("/healthz")
def healthz():
    # ⭐ Health endpoint — LUÔN trả 200, dù ERROR_RATE=1.0
    # Dùng cho readinessProbe và livenessProbe
    # Tách biệt health check và business logic lỗi!
    return "ok", 200

@app.get("/api/status")
def status():
    return jsonify(status="healthy", version=VERSION, error_rate=ERROR_RATE), 200
```

> **Điểm cần hiểu:**
> - `prometheus_flask_exporter` theo dõi MỌI request qua Flask middleware tự động
> - `ERROR_RATE` inject qua env → có thể thay đổi qua Git mà không cần rebuild image
> - `/healthz` luôn trả 200 → K8s không restart pod vô lý khi đang test error injection

#### `app/Dockerfile` — Build image

```dockerfile
FROM python:3.12-slim   # Nhẹ, không cần full Python image

WORKDIR /app

# Cài dependencies trực tiếp (không cần requirements.txt cho lab đơn giản)
RUN pip install --no-cache-dir \
    flask==3.0.3 \
    prometheus-flask-exporter==0.23.1

COPY app.py /app/app.py

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

EXPOSE 8080    # Port flask chạy

CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]
```

> **Lệnh build và load:**
> ```bash
> docker build -t w9-api:1 app/           # Build image
> minikube image load w9-api:1 -p w9      # Load vào cluster (không cần push registry)
> ```
>
> **Tại sao `minikube image load` thay vì push Docker Hub?**
> Vì trong lab, image `w9-api:1` chưa có trên Docker Hub. Minikube cần có image local.
> Trong production, sẽ push lên ECR/GCR/Docker Hub và dùng imagePullPolicy: Always.

---

### 6.4 Nhóm 2: CI/CD — GitHub Actions

#### `.github/workflows/validate.yaml` — CI Gate

```yaml
name: validate-manifests

on:
  pull_request:          # Chỉ chạy khi có PR
    branches: [main]
    paths:               # Chỉ khi các file này thay đổi (tối ưu không chạy thừa)
      - 'backend/k8s/**'
      - 'frontend/k8s/**'
      - 'infra/k8s/**'
      - 'argocd/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # ⭐ Cài kubeconform — tool validate K8s YAML schema
      - name: Install kubeconform
        run: |
          curl -sSLo kc.tgz https://github.com/yannh/kubeconform/releases/download/v0.6.7/kubeconform-linux-amd64.tar.gz
          tar -xzf kc.tgz && sudo mv kubeconform /usr/local/bin/
          kubeconform -v   # Verify cài xong

      # ⭐ Validate backend — bỏ qua CRD custom
      - name: Validate backend manifests
        run: |
          kubeconform -strict -summary \
            -skip Rollout,AnalysisTemplate,ServiceMonitor,PrometheusRule \
            backend/k8s/
          # -strict: lỗi nếu có field không tồn tại trong schema K8s
          # -skip: Rollout/AnalysisTemplate là CRD custom → kubeconform không biết schema
          # -summary: in tổng kết cuối

      - name: Validate frontend manifests
        run: kubeconform -strict -summary frontend/k8s/

      - name: Validate infra manifests
        run: |
          kubeconform -strict -summary \
            -skip PrometheusRule,ServiceMonitor,OpenTelemetryCollector \
            infra/k8s/

      - name: Validate ArgoCD apps
        run: |
          kubeconform -strict -summary \
            -skip Application \         # Application là CRD của ArgoCD
            argocd/apps/
```

> **Tại sao phải `-skip` các CRD?**
> kubeconform validate dựa trên K8s schema chuẩn.
> `Rollout`, `AnalysisTemplate`, `PrometheusRule`, `Application` không phải K8s built-in
> → kubeconform không có schema → phải skip, nếu không sẽ báo "unknown resource" và fail!

---

### 6.5 Nhóm 3: GitOps — ArgoCD App-of-Apps

#### `argocd/root.yaml` — Cốt lõi của hệ thống

```yaml
# ============================================================
# Apply 1 lần duy nhất bằng tay:
# kubectl apply -f argocd/root.yaml
# Sau đó MỌI THỨ đều tự động qua Git!
# ============================================================
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"  # Root phải chạy TRƯỚC TẤT CẢ apps con
spec:
  project: default
  source:
    repoURL: https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2.git
    targetRevision: main
    path: cloud/w9/lab-final/argocd/apps   # ⭐ Trỏ vào FOLDER chứa các Application con
                                            # Root quản lý tất cả .yaml trong folder này!
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd    # Application objects phải ở namespace argocd

  syncPolicy:
    automated:
      prune: true       # Xóa App con nếu xóa file khỏi folder argocd/apps/
      selfHeal: true    # Tự sửa nếu ai kubectl delete application backend
    syncOptions:
      - CreateNamespace=true
```

> **App-of-Apps Pattern hoạt động thế nào?**
>
> 1. `kubectl apply -f argocd/root.yaml` → Tạo Application tên "root"
> 2. Root nhìn vào folder `argocd/apps/` → thấy 5 file `.yaml`
> 3. Root tạo 5 Application objects: `kube-prometheus-stack`, `argo-rollouts`, `infra`, `backend`, `frontend`
> 4. Mỗi Application con tự sync manifest của mình
> 5. Nếu bạn thêm `argocd/apps/newservice.yaml` → push lên Git → Root tự phát hiện và tạo Application mới!

#### Thứ tự Sync Wave

```
sync-wave: -1  →  root.yaml (Bootstrap root trước)
                      │
sync-wave: 0   →  kube-prometheus-stack.yaml  ┐
               →  argo-rollouts.yaml          ├── Nền tảng phải có trước
               →  infra.yaml                  ┘
                      │  (đợi wave 0 healthy)
sync-wave: 1   →  backend.yaml   (Prometheus đã có → AnalysisTemplate có Prometheus query)
                      │  (đợi wave 1 healthy)
sync-wave: 2   →  frontend.yaml  (Backend đã có → frontend dashboard kết nối được)
```

> **Tại sao thứ tự này quan trọng?**
> - `AnalysisTemplate` trong backend query Prometheus → Prometheus phải tồn tại trước!
> - `ServiceMonitor` cần `kube-prometheus-stack` đã cài CRD `monitoring.coreos.com/v1` trước!
> - Nếu không có wave → K8s apply random thứ tự → `ServiceMonitor` apply trước CRD tồn tại → Error!

#### `argocd/apps/kube-prometheus-stack.yaml` — Cài Prometheus qua GitOps

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-prometheus-stack
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"   # Wave 0: nền tảng
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts  # ⭐ Helm repo, không phải Git!
    chart: kube-prometheus-stack    # Helm chart name
    targetRevision: 65.1.1          # Version cố định → reproducible
    helm:
      values: |                     # ⭐ Override Helm values trực tiếp trong YAML
        prometheus:
          prometheusSpec:
            serviceMonitorSelectorNilUsesHelmValues: false  # Pick up ServiceMonitor từ mọi namespace
            ruleSelector: {}                                # Pick up PrometheusRule từ mọi namespace
            ruleSelectorNilUsesHelmValues: false

        grafana:
          adminPassword: admin123      # Password Grafana (đổi trong production!)
          sidecar:
            dashboards:
              enabled: true
              searchNamespace: ALL     # Grafana tự tìm dashboard từ mọi namespace

        alertmanager:
          alertmanagerSpec:
            retention: 24h             # Giữ alert history 24h
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true    # ⭐ Bắt buộc cho CRD size lớn (PrometheusRule có thể > 256KB)
```

> **`serviceMonitorSelectorNilUsesHelmValues: false`** là gì?
> Mặc định Prometheus chỉ tìm ServiceMonitor trong namespace riêng của nó.
> Set thành `false` → Prometheus tìm ServiceMonitor ở MỌI namespace → pickup `servicemonitor-backend.yaml` ở namespace `monitoring`!

#### `argocd/apps/backend.yaml` — ArgoCD Application cho Backend

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Wave 1: sau khi Prometheus và Argo Rollouts đã có
spec:
  source:
    path: cloud/w9/lab-final/backend/k8s  # Trỏ đến folder chứa TẤT CẢ backend manifests
  destination:
    namespace: demo                        # Deploy vào namespace "demo"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

### 6.6 Nhóm 4: Observability Stack

#### `infra/k8s/otel-collector.yaml` — OpenTelemetry Pipeline

File này định nghĩa 3 K8s resource trong 1 YAML (phân tách bằng `---`):

**Resource 1: ConfigMap** — Cấu hình pipeline OTel

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: monitoring
data:
  otel-collector-config.yaml: |
    receivers:                    # Đầu vào: nhận data từ đâu?
      otlp:                       # Chuẩn OpenTelemetry Protocol
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317   # Nhận từ app gửi OTLP/gRPC
          http:
            endpoint: 0.0.0.0:4318   # Nhận từ app gửi OTLP/HTTP
      prometheus:                 # TỰ SCRAPE Prometheus endpoint
        config:
          scrape_configs:
            - job_name: 'otel-collector'
              static_configs:
                - targets: ['localhost:8888']  # Scrape metrics của chính collector

    processors:                   # Xử lý trung gian
      batch:                      # Gộp thành batch để giảm network calls
        timeout: 5s
        send_batch_size: 1024
      memory_limiter:             # Tránh OOM
        check_interval: 1s
        limit_mib: 256            # Giới hạn 256MB RAM
        spike_limit_mib: 64

    exporters:                    # Đầu ra: export data đi đâu?
      prometheus:                 # Export theo format Prometheus
        endpoint: "0.0.0.0:8889" # Prometheus sẽ scrape port này
        namespace: otel           # Prefix metrics bằng "otel_"
      logging:
        loglevel: warn

    service:
      pipelines:
        metrics:
          receivers:  [otlp, prometheus]       # Nhận qua OTLP hoặc scrape trực tiếp
          processors: [memory_limiter, batch]
          exporters:  [prometheus, logging]
        traces:
          receivers:  [otlp]
          processors: [memory_limiter, batch]
          exporters:  [logging]                # Traces chỉ log (không lưu)
```

**Resource 2: Deployment** — Chạy OTel Collector pod

```yaml
containers:
  - name: otel-collector
    image: otel/opentelemetry-collector-contrib:0.97.0
    args:
      - --config=/etc/otel/otel-collector-config.yaml  # Đọc config từ ConfigMap
    ports:
      - containerPort: 4317   # OTLP gRPC (nhận từ app)
      - containerPort: 4318   # OTLP HTTP (nhận từ app)
      - containerPort: 8888   # Metrics của chính collector
      - containerPort: 8889   # Export Prometheus format (Prometheus scrape đây)
    volumeMounts:
      - name: config-vol
        mountPath: /etc/otel  # Mount ConfigMap vào đây
volumes:
  - name: config-vol
    configMap:
      name: otel-collector-config  # Lấy từ ConfigMap ở trên
```

#### `infra/k8s/servicemonitor-backend.yaml` — Nói Prometheus scrape Backend

```yaml
# ⭐ ServiceMonitor — CRD của kube-prometheus-stack
# Thay vì config static scrape trong Prometheus, dùng ServiceMonitor declarative
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-metrics
  namespace: monitoring       # ⭐ ServiceMonitor ở monitoring, NHƯNG scrape namespace demo!
  labels:
    release: kube-prometheus-stack   # ⭐ Label này BẮT BUỘC để Prometheus nhận ra
spec:
  namespaceSelector:
    matchNames:
      - demo                  # Scrape Pods trong namespace demo
  selector:
    matchLabels:
      app: backend            # Chọn Service có label app: backend
  endpoints:
    - port: http              # Port name "http" trong Service definition
      path: /metrics          # Flask app expose /metrics tại đây
      interval: 15s           # Prometheus scrape mỗi 15 giây
      scrapeTimeout: 10s
```

> **Luồng scrape:**
> `Prometheus` → tìm `ServiceMonitor` có label `release: kube-prometheus-stack`
> → Đọc `namespaceSelector: demo` + `selector: app: backend`
> → Tìm Service ở namespace `demo` với label `app: backend`
> → Scrape `/metrics` của mọi Pod mà Service đó trỏ tới

#### `infra/k8s/prometheus-rule.yaml` — SLO Burn-Rate Alerts đầy đủ

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-burn-rate-alerts
  namespace: monitoring
  labels:
    release: kube-prometheus-stack  # ⭐ Bắt buộc để Prometheus nhận rule này
    role: alert-rules
spec:
  groups:
    - name: backend-api-slo
      interval: 30s    # Evaluate rules mỗi 30s
      rules:
        # ── 1. Recording Rules (tính sẵn để query nhanh hơn) ──
        - record: job:flask_http_request_success_rate:ratio_rate5m
          expr: |
            sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[5m]))
            /
            sum(rate(flask_http_request_total{namespace="demo"}[5m]))
            # Ý nghĩa: trong 5 phút qua, tỉ lệ request không phải 5xx là bao nhiêu?

        # Recording rule 1h và 6h tương tự...

        # ── 2. Fast Burn Alert (Nguy cấp) ──
        # Ngưỡng 0.144 = 14.4% error rate
        # Tại sao 14.4? SLO=99.5%, error_budget=0.5%
        # Fast burn rate = 14.4 → trong 1h tiêu 14.4% budget → hết budget trong 30/14.4 ≈ 2 ngày
        - alert: BackendAPIFastBurn
          expr: |
            (
              sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1h]))
              /
              sum(rate(flask_http_request_total{namespace="demo"}[1h]))
            ) > 0.144           # Error rate_1h > 14.4%
            and
            (
              sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[5m]))
              /
              sum(rate(flask_http_request_total{namespace="demo"}[5m]))
            ) > 0.144           # VÀ error_rate_5m > 14.4% (xác nhận đang xảy ra ngay)
          for: 2m               # Phải duy trì 2 phút → tránh alert giả
          labels:
            severity: critical
          annotations:
            summary: "🔥 Fast Burn: Backend API error budget cháy nhanh"
            description: |
              Error budget sẽ cạn trong ~2 ngày.
              Action: kubectl argo rollouts abort backend -n demo

        # ── 3. Slow Burn Alert (Cảnh báo) ──
        # Ngưỡng 0.06 = 6% → budget hết trong 5 ngày
        - alert: BackendAPISlowBurn
          expr: |
            (error_rate_6h > 0.06) and (error_rate_30m > 0.06)
          for: 15m              # Phải duy trì 15 phút (slow burn nhẹ hơn → đợi lâu hơn)
          labels:
            severity: warning

        # ── 4. SLO Breach Alert (Vi phạm SLO ngay bây giờ!) ──
        - alert: BackendAPISLOBreach
          expr: |
            (
              sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[1h]))
              /
              sum(rate(flask_http_request_total{namespace="demo"}[1h]))
            ) < 0.995           # SLI thực tế < 99.5% SLO cam kết
          for: 5m
          labels:
            severity: critical
```

**Bảng tóm tắt 3 alert:**

| Alert | Điều kiện | `for` | Severity | Hành động |
|-------|-----------|-------|----------|-----------|
| **FastBurn** | error_1h > 14.4% AND error_5m > 14.4% | 2m | critical | Abort canary ngay, check logs |
| **SlowBurn** | error_6h > 6% AND error_30m > 6% | 15m | warning | Tạo ticket, review canary |
| **SLOBreach** | success_1h < 99.5% | 5m | critical | Rollback, PagerDuty |

---

### 6.7 Nhóm 5: Canary Deployment — Argo Rollouts

#### `backend/k8s/namespace.yaml` — Wave -1 (Đầu tiên)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
  annotations:
    argocd.argoproj.io/sync-wave: "-1"  # Tạo TRƯỚC tất cả resources trong backend
```

> Namespace phải tồn tại trước khi tạo Secret, Service, Rollout trong namespace đó!

#### `backend/k8s/secret.yaml` — Wave 0

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: demo
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Tạo trước Rollout (wave 1)
type: Opaque
data:
  # ⭐ Base64 encode: echo -n "localhost" | base64
  DB_HOST:     bG9jYWxob3N0          # "localhost"
  DB_NAME:     ZGVtb19kYg==          # "demo_db"
  DB_PASSWORD: ZGVtb19wYXNzd29yZF9jaGFuZ2VtZQ==  # "demo_password_changeme"
  DB_USER:     ZGVtb191c2Vy          # "demo_user"
```

> **QUAN TRỌNG:** Trong production KHÔNG commit secret thật lên Git!
> Dùng **Sealed Secrets** hoặc **HashiCorp Vault** để mã hóa trước khi commit.

#### `backend/k8s/service-stable.yaml` và `service-canary.yaml`

```yaml
# service-stable.yaml — Nhận toàn bộ traffic bình thường
apiVersion: v1
kind: Service
metadata:
  name: backend-service       # ⭐ Tên này được dùng trong rollout.yaml → stableService
  namespace: demo
  labels:
    app: backend              # ⭐ Label này ServiceMonitor dùng để tìm Service
spec:
  type: NodePort
  selector:
    app: backend              # ⭐ Argo Rollouts TỰ ĐỘNG thay đổi selector này!
                              # Khi canary bắt đầu: stable → trỏ vào Pods bản cũ
                              # Khi promote: stable → trỏ vào Pods bản mới
  ports:
    - name: http              # ⭐ Port name "http" → ServiceMonitor dùng để biết scrape port nào
      port: 80
      targetPort: 8080        # Flask listen trên 8080
      nodePort: 30080         # Truy cập từ ngoài: minikube_ip:30080
---
# service-canary.yaml — Nhận % traffic canary
metadata:
  name: backend-preview-service  # ⭐ Tên này trong rollout.yaml → canaryService
  nodePort: 30081                # Truy cập canary riêng: minikube_ip:30081
```

#### `backend/k8s/rollout.yaml` — Trái tim của hệ thống

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout        # Thay thế apps/v1/Deployment!
metadata:
  name: backend
  namespace: demo
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Wave 1: sau secret và analysis-template
spec:
  replicas: 4        # Tổng số Pods (stable + canary)
  revisionHistoryLimit: 3   # Giữ 3 bản cũ để rollback nhanh

  selector:
    matchLabels:
      app: backend

  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: api
          image: w9-api:1              # ⭐ Đổi thành w9-api:2 để trigger canary!
          imagePullPolicy: IfNotPresent # Dùng local image (không cần registry)
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: ERROR_RATE
              value: "0"               # ⭐ Đổi "0.2" để test auto-abort!
            - name: VERSION
              value: "v1"              # ⭐ Đổi "v2" để phân biệt stable vs canary
            - name: DB_HOST
              valueFrom:
                secretKeyRef:          # Lấy từ backend-secret (wave 0)
                  name: backend-secret
                  key: DB_HOST
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: backend-secret
                  key: DB_PASSWORD

          readinessProbe:
            httpGet:
              path: /healthz           # Dùng /healthz, KHÔNG dùng / (vì / có thể trả 500)
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10

          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"

  strategy:
    canary:
      canaryService: backend-preview-service   # Service nhận canary traffic
      stableService: backend-service           # Service nhận stable traffic

      # ⭐ AnalysisTemplate — Auto-abort logic
      analysis:
        templates:
          - templateName: success-rate-analysis  # Dùng template đã define
        startingStep: 1         # Bắt đầu chấm từ bước 1 (sau setWeight 20%)
        args:
          - name: namespace
            value: demo

      steps:                    # Canary roadmap
        - setWeight: 20         # Step 1: 20% traffic → canary (1 trong 4 Pods)
        - pause: {duration: 30s}  # Đợi 30s để có metrics
        # Nếu muốn manual promote: đổi thành pause: {}
        - setWeight: 50         # Step 2: 50% → canary (2 trong 4 Pods)
        - pause: {duration: 30s}
        - setWeight: 100        # Step 3: 100% → tất cả Pods là version mới
```

#### `backend/k8s/analysis-template.yaml` — Logic tự chấm

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate-analysis
  namespace: demo
spec:
  args:
    - name: namespace        # Nhận namespace từ rollout.yaml
      value: demo

  metrics:
    # ── Metric 1: Success Rate — quan trọng nhất ──
    - name: success-rate
      initialDelay: 20s      # Đợi 20s sau canary start để Flask có đủ data
      interval: 30s          # Query mỗi 30s
      count: 5               # Tổng 5 lần = 150s = 2.5 phút
      successCondition: result[0] >= 0.95   # ⭐ >= 95% thành công → PASS
      failureLimit: 2        # ⭐ Fail 2 lần liên tiếp → ABORT rollout!

      provider:
        prometheus:
          address: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
          # ⭐ Địa chỉ trong-cluster của Prometheus Service
          query: |
            sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[2m]))
            /
            sum(rate(flask_http_request_total{namespace="demo"}[2m]))
            # Đọc: (tổng tốc độ request thành công) / (tổng tốc độ tất cả request)
            # Trong 2 phút gần nhất

    # ── Metric 2: Request rate alive ──
    - name: request-rate-alive
      initialDelay: 20s
      interval: 30s
      count: 3
      successCondition: result[0] >= 0    # Chỉ cần > 0 là có traffic
      failureLimit: 3

      provider:
        prometheus:
          address: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
          query: |
            scalar(sum(rate(flask_http_request_total{namespace="demo"}[1m])) or vector(0))
            # "or vector(0)" → nếu không có metric thì trả 0, không báo lỗi
```

**Hiểu Prometheus Query:**

```promql
# Phân tích:
flask_http_request_total{namespace="demo", status!~"5.."}
                          ↑                ↑
                     chỉ namespace demo   status KHÔNG phải 5xx (200, 302, 404...)

rate(...[2m])
# Tốc độ thay đổi trong 2 phút = số request/giây trung bình của 2 phút qua

sum(...)
# Cộng tất cả Pods trong namespace

sum(success) / sum(total)
# = tỉ lệ thành công
```

---

### 6.8 Nhóm 6: Frontend Dashboard

#### `frontend/k8s/deployment.yaml` — NGINX Dashboard

```yaml
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: frontend
          image: nginx:alpine    # Chỉ cần NGINX, không cần build image riêng
          ports:
            - name: http
              containerPort: 80
          volumeMounts:
            - name: html-vol
              mountPath: /usr/share/nginx/html/index.html  # ⭐ Mount file, không phải folder!
              subPath: index.html                          # Chỉ mount 1 file từ ConfigMap
            - name: nginx-conf-vol
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf                        # NGINX config (proxy /api → backend)

      volumes:
        - name: html-vol
          configMap:
            name: frontend-config   # ConfigMap chứa HTML dashboard
            items:
              - key: index.html
                path: index.html
        - name: nginx-conf-vol
          configMap:
            name: frontend-config
            items:
              - key: default.conf
                path: default.conf
```

> **`subPath`** cho phép mount 1 file cụ thể từ ConfigMap thay vì cả folder.
> Nếu không dùng `subPath`: mount cả ConfigMap vào `/usr/share/nginx/html/` → ghi đè mọi file NGINX mặc định → xóa hết các file khác trong đó!

#### `frontend/k8s/service.yaml`

```yaml
spec:
  type: NodePort
  ports:
    - nodePort: 30090    # Truy cập: http://minikube_ip:30090
      port: 80
      targetPort: 80
```

---

### 6.9 Nhóm 7: Load Test với k6

#### `k6-load-test.js` — Giả lập traffic thật

```javascript
// ── Config: 4 giai đoạn test ──
export const options = {
  stages: [
    { duration: '30s', target: 5  },  // Ramp up: 0 → 5 users đồng thời
    { duration: '3m',  target: 10 },  // Steady state: 10 users (trigger alerts)
    { duration: '1m',  target: 20 },  // Spike: 20 users (stress test)
    { duration: '30s', target: 0  },  // Ramp down: về 0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],  // 95% request phải < 500ms → PASS
    'error_rate':        ['rate<0.2'],   // < 20% lỗi tổng thể → PASS
  },
};

export default function () {
  const BASE = __ENV.TARGET_URL || 'http://localhost:30080';

  if (Math.random() < 0.85) {
    // 85% request bình thường → hit "/" → trả 200
    const res = http.get(`${BASE}/`);
    check(res, { 'status 200': (r) => r.status === 200 });
  } else {
    // 15% request lỗi → hit path không tồn tại → 404
    // Kết hợp với ERROR_RATE=0.2 trong Flask → tổng error rate > 20%
    const res = http.get(`${BASE}/nonexistent-path-to-trigger-error`);
    errorRate.add(true);
  }
  sleep(0.5);  // Mỗi virtual user nghỉ 0.5s giữa các request
}
```

> **Kịch bản trigger canary abort:**
> - k6 gửi 10 users × 2 req/s = 20 req/s
> - Flask app có ERROR_RATE=0.2 → 20% request trả 500
> - k6 cộng thêm 15% request 404
> - Tổng error rate ~35% > ngưỡng 5% (1-95%) → AnalysisTemplate fail
> - Sau 2 lần fail trong 150s → ABORT!

---

### 6.10 Nhóm 8: Setup Script

#### `setup.sh` — One-click setup

```bash
#!/bin/bash
set -euo pipefail    # Dừng ngay nếu bất kỳ lệnh nào fail

# ── Step 1: Kiểm tra prerequisites ──
command -v kubectl > /dev/null || err "kubectl chưa cài"
command -v helm    > /dev/null || err "helm chưa cài"
command -v docker  > /dev/null || err "docker chưa cài"

# Kiểm tra cluster đang chạy
if ! kubectl get nodes &>/dev/null; then
  warn "Cluster chưa sẵn sàng. Chạy:"
  echo "  minikube start -p w9 --cpus=4 --memory=6g"
  exit 1
fi

# ── Step 2: Cài ArgoCD ──
# Dùng --dry-run=client -o yaml | apply để idempotent (chạy nhiều lần không lỗi)
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Đợi ArgoCD sẵn sàng
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=180s

# ── Step 3: Cài kubectl-argo-rollouts plugin ──
curl -sLo /tmp/kubectl-argo-rollouts \
  "https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64"
chmod +x /tmp/kubectl-argo-rollouts
sudo mv /tmp/kubectl-argo-rollouts /usr/local/bin/

# ── Step 4: Build Flask image ──
docker build -t w9-api:1 "${SCRIPT_DIR}/app/"    # Build từ app/Dockerfile
minikube image load w9-api:1 -p w9               # Load vào cluster

# ── Step 5: Apply Root Application ──
# Đây là lệnh DUY NHẤT cần chạy tay — mọi thứ còn lại qua Git!
kubectl apply -f "${SCRIPT_DIR}/argocd/root.yaml"

# ── Step 6: Đợi Prometheus stack ──
kubectl wait --for=condition=available deployment/kube-prometheus-stack-grafana \
  -n monitoring --timeout=300s    # Prometheus cần 3-5 phút!

# ── Step 7: In thông tin truy cập ──
MINIKUBE_IP=$(minikube ip 2>/dev/null)
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
```

---

## 7. Hướng dẫn chạy Lab từng bước

### Bước 0: Chuẩn bị môi trường

```bash
# Khởi động Minikube với đủ tài nguyên cho Prometheus stack
minikube start -p w9 --cpus=4 --memory=6g
# ⚠️ Prometheus + Grafana + ArgoCD cần tối thiểu 4GB RAM!

# Verify cluster OK
kubectl get nodes
# Expected: NAME   STATUS   ROLES           AGE   VERSION
#           w9     Ready    control-plane   ...   v1.31.x

# Cập nhật repoURL trong tất cả argocd/*.yaml
# Thay X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2 bằng repo thật của bạn
grep -r "X-BRAIN-CDO-09" cloud/w9/lab-final/argocd/
```

### Bước 1: Chạy setup tự động

```bash
cd cloud/w9/lab-final
chmod +x setup.sh
./setup.sh
# Script sẽ in thông tin access khi hoàn tất (~5-10 phút)
```

### Bước 2: Verify tất cả apps healthy

```bash
# Xem tất cả ArgoCD apps
kubectl -n argocd get applications
# Expected: 6 apps, tất cả STATUS=Synced, HEALTH=Healthy

# Xem pods ở tất cả namespaces
kubectl get pods -A | grep -v kube-system
# Expected: argocd, monitoring, argo-rollouts, demo namespaces

# Xem Rollout backend
kubectl argo rollouts get rollout backend -n demo
# Expected: Status: Healthy, stable version
```

### Bước 3: Mở các UI

```bash
# Terminal 1: ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080  →  admin / <password từ setup.sh>

# Terminal 2: Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
# http://localhost:3000  →  admin / admin123

# Terminal 3: Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
# http://localhost:9090

# Terminal 4: Argo Rollouts Dashboard
kubectl argo rollouts dashboard -n demo
# http://localhost:3100
```

### Bước 4: Verify metrics đang được scrape

```bash
# Gửi 1 request để có data
curl http://$(minikube ip -p w9):30080/

# Kiểm tra Prometheus có metric chưa
curl "localhost:9090/api/v1/query?query=flask_http_request_total" | python3 -m json.tool

# Expected: data.result có giá trị → metrics đang được scrape!
```

### Bước 5: Chạy Load Test

```bash
TARGET_URL=http://$(minikube ip -p w9):30080 k6 run k6-load-test.js

# Xem alert Prometheus trong lúc chạy:
# http://localhost:9090/alerts → BackendAPIFastBurn sẽ fire sau ~3-5 phút
```

### Bước 6: Test Canary Deploy bình thường (v2 không lỗi)

```bash
# Sửa rollout.yaml:
# VERSION: "v1" → "v2"
# ERROR_RATE: "0" → "0"  (giữ 0, không lỗi)

git add backend/k8s/rollout.yaml
git commit -m "deploy: backend v2 (healthy)"
git push

# Theo dõi rollout:
kubectl argo rollouts get rollout backend -n demo --watch
# Expected: Canary 20% → 50% → 100% → Promoted!
# Mỗi bước mất 30s + thời gian AnalysisRun check
```

### Bước 7: Test Canary Auto-Abort (Challenge ⭐)

```bash
# Sửa rollout.yaml:
# VERSION: "v2" → "v3"
# ERROR_RATE: "0" → "0.2"  (20% request sẽ lỗi!)

git add backend/k8s/rollout.yaml
git commit -m "deploy: backend v3 with 20% error rate (canary abort test)"
git push

# Theo dõi rollout:
kubectl argo rollouts get rollout backend -n demo --watch

# Expected timeline:
# T+0s: Argo Rollouts nhận thay đổi từ ArgoCD
# T+30s: setWeight 20% → 1 Pod v3 nhận 20% traffic
# T+50s: AnalysisRun bắt đầu (initialDelay: 20s)
# T+80s: Query Prometheus → success_rate = 80% < 95% → Fail #1
# T+110s: Query lần 2 → success_rate = 80% < 95% → Fail #2
# T+110s: failureLimit: 2 → ABORT! 100% traffic về v2
# T+115s: Status: Degraded (Aborted)
```

### Bước 8: Manual Promote (Lab 4)

```bash
# Đổi rollout.yaml:
# pause: {duration: 30s}  →  pause: {}  (pause vô hạn, cần promote tay)

git push

# Canary sẽ dừng ở 20% và đợi
kubectl argo rollouts get rollout backend -n demo --watch
# Status: Paused ✋

# Promote thủ công sau khi kiểm tra OK
kubectl argo rollouts promote backend -n demo
# Tiếp tục: 50% → pause → promote tiếp → 100%
```

---

## 8. Câu lệnh quan trọng giải thích chi tiết

### ArgoCD

```bash
# Lấy password admin lần đầu (chỉ dùng lần đầu, nên đổi sau)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
# base64 -d: decode base64 → password thật
# && echo: xuống dòng sau password

# Xem tất cả applications
kubectl -n argocd get applications
# COLUMNS: NAME, SYNC STATUS, HEALTH STATUS, REPO, PATH

# Xem chi tiết 1 application
kubectl -n argocd describe application backend
# Xem: Last Sync, Events, Resources được quản lý

# Force sync (áp dụng ngay không đợi poll 3 phút)
kubectl -n argocd patch application backend \
  --type='merge' -p '{"operation":{"sync":{}}}'
```

### Argo Rollouts

```bash
# Xem rollout realtime (cập nhật liên tục)
kubectl argo rollouts get rollout backend -n demo --watch
# Hiển thị: steps, pods của mỗi version, analysis runs

# Xem chi tiết analysis run (debug abort)
kubectl get analysisrun -n demo
kubectl describe analysisrun <tên-analysisrun> -n demo
# Xem: từng metric, kết quả query, lý do fail

# Promote thủ công (khi đang pause: {})
kubectl argo rollouts promote backend -n demo

# Abort ngay lập tức
kubectl argo rollouts abort backend -n demo

# Undo về revision trước đó
kubectl argo rollouts undo backend -n demo

# Xem history
kubectl argo rollouts history rollout backend -n demo
# REVISION  CHANGE-CAUSE
# 1         v1 stable
# 2         v2 promote
# 3         v3 aborted (rollback)
```

### Prometheus PromQL

```bash
# Query qua CLI
curl "localhost:9090/api/v1/query?query=flask_http_request_total"

# Tỉ lệ thành công 5 phút qua
# Chạy trực tiếp trên http://localhost:9090 → Graph tab:
sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[5m]))
/
sum(rate(flask_http_request_total{namespace="demo"}[5m]))

# Request rate theo giây
sum(rate(flask_http_request_total{namespace="demo"}[1m]))

# Error rate
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[5m]))
/
sum(rate(flask_http_request_total{namespace="demo"}[5m]))
```

### Debug Commands

```bash
# Xem logs của Flask pod
kubectl logs -l app=backend -n demo --tail=50
kubectl logs -l app=backend -n demo -f  # Follow realtime

# Exec vào pod để test
kubectl exec -it $(kubectl get pod -l app=backend -n demo -o name | head -1) \
  -n demo -- sh
# Trong pod: curl localhost:8080/metrics | grep flask_http

# Xem events (lỗi schedule, pull image...)
kubectl get events -n demo --sort-by='.lastTimestamp' | tail -20

# Check ServiceMonitor có được Prometheus nhận không
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor backend-metrics -n monitoring

# Check PrometheusRule có được nhận không
kubectl get prometheusrule -n monitoring
# Prometheus phải có labels: release: kube-prometheus-stack

# Rollback khẩn cấp
kubectl argo rollouts abort backend -n demo    # Step 1: Abort canary
kubectl argo rollouts undo backend -n demo     # Step 2: Undo về version trước
```

---

## 9. Các kịch bản test và kết quả mong đợi

### Kịch bản 1: GitOps Self-Heal

```bash
# Test: Xóa deployment bằng tay (vi phạm GitOps!)
kubectl delete deployment frontend -n demo

# Kết quả mong đợi (trong vòng 3 phút):
# ArgoCD phát hiện drift → tự tạo lại Deployment!
# Xem: kubectl -n argocd get application frontend
# Status sẽ: OutOfSync → Syncing → Synced
```

### Kịch bản 2: Git Revert (Rollback qua GitOps)

```bash
# Nếu production lỗi và cần rollback nhanh:
git revert HEAD
git push
# ArgoCD sync → rollout.yaml về version cũ → Argo Rollouts promote bản cũ
# Mục tiêu: < 5 phút từ khi phát hiện đến khi rollback xong
```

### Kịch bản 3: Canary với Manual Promote

```bash
# Trong rollout.yaml: thay pause: {duration: 30s} → pause: {}
git push

# Rollout dừng ở 20% và đợi vô hạn
# Team review logs, metrics trên Grafana
# Nếu ổn: kubectl argo rollouts promote backend -n demo
# Nếu lỗi: kubectl argo rollouts abort backend -n demo
```

### Kịch bản 4: SLO Breach Alert

```bash
# Trigger bằng cách inject nhiều lỗi (ERROR_RATE=0.5)
git push

# Xem Prometheus Alerts: http://localhost:9090/alerts
# Expected: BackendAPISLOBreach FIRING
# (SLI < 99.5% trong 5 phút liên tiếp)
```

---

## 10. Troubleshooting thường gặp

| Triệu chứng | Nguyên nhân thường gặp | Fix |
|-------------|----------------------|-----|
| ArgoCD app mãi `OutOfSync` | repoURL sai hoặc không public | Kiểm tra `kubectl describe application <name> -n argocd` |
| AnalysisRun không có data | ServiceMonitor label sai | Phải có label `release: kube-prometheus-stack` |
| Canary không abort dù error cao | `analysis` bị comment out | Bỏ comment trong `rollout.yaml` |
| `flask_http_request_total` không có | Flask chưa nhận traffic | Gửi ít nhất 1 request trước |
| Prometheus không scrape | ServiceMonitor `selector` sai | Label `app: backend` phải khớp với Service |
| `kube-prometheus-stack` timeout | Không đủ RAM | Cần 4GB+ cho minikube |
| Image `w9-api:1` không tìm thấy | Chưa load vào minikube | `minikube image load w9-api:1 -p w9` |
| ArgoCD không tìm thấy repo | Repo private, chưa config credentials | Vào ArgoCD UI → Settings → Repositories |

```bash
# Debug ArgoCD sync error
kubectl -n argocd get application backend -o yaml | grep -A 20 "status:"

# Debug AnalysisRun
kubectl get analysisrun -n demo
kubectl describe analysisrun <name> -n demo | grep -A 10 "Message:"

# Reset hoàn toàn rollout
kubectl argo rollouts abort backend -n demo 2>/dev/null; true
kubectl argo rollouts undo backend -n demo
# Xóa analysis runs cũ
kubectl delete analysisrun -n demo --all
```

---

## 📌 Checklist Challenge Lab-Final

```bash
# Tick khi đã làm xong:

[ ] 1. ArgoCD quản lý tất cả 5 Application (không kubectl tay)
[ ] 2. git push thay đổi YAML → ArgoCD tự sync trong 3 phút
[ ] 3. Xóa 1 Pod bằng tay → ArgoCD tự tạo lại (self-heal)
[ ] 4. Metrics flask_http_request_total hiện trong Prometheus
[ ] 5. Load test k6 chạy → Alert BackendAPIFastBurn FIRING
[ ] 6. Deploy v2 bình thường → Canary promote thành công (20→50→100%)
[ ] 7. Deploy v3 với ERROR_RATE=0.2 → Canary TỰ ABORT về v2 ⭐
[ ] 8. git revert HEAD && git push → Rollback < 5 phút
[ ] 9. Grafana hiển thị dashboard SLO với Error Budget
[ ] 10. CI validate.yaml chặn PR khi YAML sai schema
```

---

*📖 Tài liệu tham khảo:*
- [Argo Rollouts Concepts](https://argoproj.github.io/argo-rollouts/concepts/)
- [Google SRE Book — SLO/SLI](https://sre.google/sre-book/service-level-objectives/)
- [Multi-window Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos/)
- [prometheus-flask-exporter](https://github.com/rycus86/prometheus_flask_exporter)
- [ArgoCD App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
