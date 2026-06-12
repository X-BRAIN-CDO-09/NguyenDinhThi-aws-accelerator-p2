# 📚 Giải Thích Kỹ Thuật — W9 Lab Final: Ship Smartly

> Tài liệu này giải thích **từng khái niệm** và **từng đoạn code thực tế** trong lab-final.
> Đọc theo thứ tự để hiểu toàn bộ flow từ app → metrics → alert → auto-abort.

---

## MỤC LỤC

1. [Flask API + prometheus_flask_exporter](#1-flask-api--prometheus_flask_exporter)
2. [Prometheus & ServiceMonitor](#2-prometheus--servicemonitor)
3. [Telemetry & OTel Collector](#3-telemetry--otel-collector)
4. [SLO, SLI, Error Budget](#4-slo-sli-error-budget)
5. [SLO Burn-Rate Alerts](#5-slo-burn-rate-alerts)
6. [Argo Rollouts & Canary Deployment](#6-argo-rollouts--canary-deployment)
7. [AnalysisTemplate & AUTO-ABORT](#7-analysistemplate--auto-abort)
8. [Luồng Hoàn Chỉnh — Big Picture](#8-luồng-hoàn-chỉnh--big-picture)

---

## 1. Flask API + prometheus_flask_exporter

### Khái niệm

Flask là web framework Python đơn giản. `prometheus_flask_exporter` là thư viện **tự động** thêm endpoint `/metrics` vào mọi Flask app — không cần viết code thủ công.

Khi Prometheus gọi `GET /metrics`, Flask trả về dữ liệu dạng text như:

```
flask_http_request_total{method="GET",path="/",status="200"} 1523
flask_http_request_total{method="GET",path="/",status="500"} 42
flask_http_request_duration_seconds_bucket{le="0.1"} 1400
flask_http_request_duration_seconds_bucket{le="0.5"} 1520
```

### Code thực tế — `app/app.py`

```python
import os
import random
from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics   # ← thư viện quan trọng

app = Flask(__name__)
metrics = PrometheusMetrics(app)   # ← 1 dòng này tự thêm /metrics endpoint

ERROR_RATE = float(os.getenv("ERROR_RATE", "0"))   # ← đọc từ env var K8s
VERSION    = os.getenv("VERSION", "v1")            # ← đọc từ env var K8s
```

**Tại sao dùng `os.getenv()`?**

Trong Kubernetes, config không được hardcode trong code. Thay vào đó, truyền qua **environment variable** từ file `rollout.yaml`:

```yaml
# backend/k8s/rollout.yaml (dòng 44-48)
env:
  - name: ERROR_RATE
    value: "0.0"   # ← bình thường = 0% lỗi
  - name: VERSION
    value: "v2"    # ← label để phân biệt version khi canary
```

**Logic inject lỗi giả:**

```python
@app.get("/")
def index():
    if random.random() < ERROR_RATE:   # random() trả 0.0 → 1.0
        return jsonify(error="injected_error"), 500   # ← giả lỗi 500
    return jsonify(ok=True, version=VERSION), 200
```

> 💡 **Ý nghĩa:** Khi `ERROR_RATE=0.2`, cứ 10 request thì trung bình 2 request trả 500.
> Đây là cách **giả lập lỗi production** để test hệ thống auto-abort mà không cần code thật có bug.

---

## 2. Prometheus & ServiceMonitor

### Khái niệm

**Prometheus** là hệ thống giám sát theo mô hình **pull** — nó chủ động đi hỏi (scrape) các app để lấy metrics, thay vì app tự gửi.

```
Prometheus ──[GET /metrics mỗi 15s]──► Flask Pod
               ◄── dữ liệu metrics text ──
```

**Vấn đề:** Prometheus trong K8s không biết cần scrape Pod nào. Giải pháp: **ServiceMonitor** — một Custom Resource (CRD) nói với Prometheus "hãy scrape service này theo cấu hình này".

### Code thực tế — `infra/k8s/servicemonitor-backend.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1    # ← CRD từ kube-prometheus-stack
kind: ServiceMonitor
metadata:
  name: backend-metrics
  namespace: monitoring      # ← ServiceMonitor nằm ở namespace monitoring
  labels:
    release: kube-prometheus-stack   # ← QUAN TRỌNG: label này Prometheus mới nhận ra
spec:
  namespaceSelector:
    matchNames:
      - demo              # ← nhưng scrape Pod ở namespace demo
  selector:
    matchLabels:
      app: backend        # ← chọn Service có label app=backend
  endpoints:
    - port: http          # ← tên port trong Service definition
      path: /metrics      # ← endpoint Flask tự tạo
      interval: 15s       # ← cứ 15 giây scrape 1 lần
      scrapeTimeout: 10s
```

**Tại sao label `release: kube-prometheus-stack` quan trọng?**

Prometheus được cài qua Helm chart tên `kube-prometheus-stack`. Prometheus chỉ watch ServiceMonitor có đúng label này. Nếu thiếu → Prometheus không biết ServiceMonitor tồn tại → không scrape.

### Flow scrape hoàn chỉnh

```
ServiceMonitor (monitoring ns)
    ↓ Prometheus Controller đọc
Prometheus biết: "scrape Service app=backend ở namespace demo, port http, /metrics, mỗi 15s"
    ↓
Prometheus GET http://backend-service.demo.svc.cluster.local:8080/metrics
    ↓
Flask trả metrics text
    ↓
Prometheus lưu vào time-series database (TSDB)
    ↓
Có thể query bằng PromQL
```

---

## 3. Telemetry & OTel Collector

### Khái niệm

**Telemetry** (đo từ xa) là khái niệm thu thập 3 loại dữ liệu từ hệ thống:

| Loại | Ví dụ | Dùng để |
|------|-------|---------|
| **Metrics** | request count, latency, CPU % | Dashboard, Alert |
| **Logs** | "ERROR: DB connection failed" | Debug |
| **Traces** | Request đi qua service A → B → C mất bao lâu mỗi bước | Performance profiling |

**OpenTelemetry (OTel)** là chuẩn mở (CNCF) để thu thập cả 3 loại telemetry. **OTel Collector** là một agent trung gian nhận data từ nhiều nguồn, xử lý, rồi gửi đến nhiều đích.

### Code thực tế — `infra/k8s/otel-collector.yaml`

```yaml
# Cấu trúc Pipeline của OTel Collector
receivers:           # Nhận data từ đâu?
  otlp:              # Nhận theo chuẩn OTLP (OpenTelemetry Protocol)
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317   # ← App gửi traces/metrics đến đây
      http:
        endpoint: 0.0.0.0:4318
  prometheus:        # Tự scrape metrics của chính collector
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          static_configs:
            - targets: ['localhost:8888']

processors:          # Xử lý trung gian
  batch:             # Gom nhiều data points vào 1 batch để tiết kiệm network
    timeout: 5s
    send_batch_size: 1024
  memory_limiter:    # Bảo vệ: không dùng quá 256MB RAM
    limit_mib: 256

exporters:           # Gửi data đi đâu?
  prometheus:        # Export sang format Prometheus
    endpoint: "0.0.0.0:8889"   # ← Prometheus scrape OTel tại đây

service:
  pipelines:
    metrics:         # Pipeline cho metrics
      receivers:  [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters:  [prometheus, logging]
    traces:          # Pipeline cho traces
      receivers:  [otlp]
      processors: [memory_limiter, batch]
      exporters:  [logging]    # Traces chỉ log (chưa có Jaeger/Tempo)
```

**Ports của OTel Collector:**

| Port | Giao thức | Dùng để |
|------|-----------|---------|
| `4317` | gRPC | App gửi OTLP data (gRPC) |
| `4318` | HTTP | App gửi OTLP data (HTTP) |
| `8888` | HTTP | Self-metrics của collector |
| `8889` | HTTP | Prometheus scrape metrics từ đây |

> 💡 **Trong lab này** Flask dùng `prometheus_flask_exporter` nên Prometheus scrape trực tiếp Pod — không cần OTel cho metrics. OTel Collector được deploy sẵn để nhận **traces** nếu Flask được tích hợp sau này (OpenTelemetry SDK cho Python).

---

## 4. SLO, SLI, Error Budget

### Khái niệm cốt lõi (từ Google SRE)

| Thuật ngữ | Viết tắt | Định nghĩa | Ví dụ trong lab |
|-----------|----------|-----------|----------------|
| **Service Level Indicator** | SLI | Số đo thực tế về chất lượng dịch vụ | Tỷ lệ request thành công (không phải 5xx) |
| **Service Level Objective** | SLO | Mục tiêu chất lượng cần đạt | SLI ≥ 99.5% trong 30 ngày |
| **Error Budget** | EB | Mức lỗi được phép có = 100% - SLO | 0.5% = 216 phút downtime/tháng |

### Công thức trong lab

```
SLI = requests thành công / tổng requests
    = (không phải 5xx) / tất cả

SLO = 99.5% → Error Budget = 0.5%

Error Budget theo thời gian:
  30 ngày × 24h × 60m × 0.5% = 216 phút cho phép lỗi
```

### Recording Rules trong `prometheus-rule.yaml`

Recording rule = **tính sẵn** kết quả PromQL phức tạp, lưu thành metric mới.
Ưu điểm: Alert query chạy nhanh hơn (không tính lại từ đầu mỗi lần).

```yaml
# Dòng 30-34: SLI cơ bản — success rate 5 phút
- record: job:flask_http_request_success_rate:ratio_rate5m
  expr: |
    sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[5m]))
    /
    sum(rate(flask_http_request_total{namespace="demo"}[5m]))
```

**Giải thích từng phần:**
- `flask_http_request_total` — metric từ `prometheus_flask_exporter`
- `{namespace="demo",status!~"5.."}` — lọc: không phải 5xx (regex `5..` = 500,501,...,599)
- `rate(...[5m])` — tốc độ tăng trung bình trong 5 phút gần nhất
- `sum(...)` — cộng tất cả pods lại
- `/` — chia = tỷ lệ

```yaml
# Dòng 89-99: Error Budget còn lại
- record: job:flask_http_error_budget_remaining:ratio_rate30d
  expr: |
    1 - (
      (1 - sum(rate(...{status!~"5.."}[30d])) / sum(rate(...[30d])))
      / 0.005
    )
```

**Giải thích:**
- `1 - success_rate_30d` = error_rate_30d (actual)
- `/ 0.005` = chia cho error budget (0.5%)
- `1 - (...)` = phần budget còn lại
- Kết quả `1.0` = đầy, `0.0` = hết, `< 0` = vi phạm SLO

---

## 5. SLO Burn-Rate Alerts

### Khái niệm Burn Rate

**Burn Rate** = tốc độ tiêu Error Budget nhanh như thế nào so với bình thường.

```
Burn Rate = 1  → Tiêu vừa đủ (hết budget đúng 30 ngày)
Burn Rate = 14.4 → Tiêu nhanh gấp 14.4 lần
           → Budget hết trong 30/14.4 ≈ 2 ngày → CRITICAL!
Burn Rate = 6   → Tiêu nhanh gấp 6 lần
           → Budget hết trong 30/6 = 5 ngày → WARNING
```

**Tại sao dùng 2 cửa sổ thời gian (1h+5m, 6h+30m)?**

Dùng 1 cửa sổ duy nhất có thể bị **false positive** (alert giả):
- Cửa sổ ngắn (5m): Nhạy nhưng hay false alarm (spike ngắn)
- Cửa sổ dài (1h): Ổn định nhưng phát hiện chậm

**Giải pháp Multi-window:** `AND` hai điều kiện — phải sai ở CẢ HAI cửa sổ mới alert.

### Code thực tế — `infra/k8s/prometheus-rule.yaml`

```yaml
# Dòng 104-128: FAST BURN — CRITICAL
- alert: BackendAPIFastBurn
  expr: |
    (
      sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1h]))   # cửa sổ 1h
      /
      sum(rate(flask_http_request_total{namespace="demo"}[1h]))
    ) > 0.144    # error rate > 14.4% = burn rate > 14.4×  (14.4% × 1/0.005 = 28.8 lần sai)
    and
    (
      sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[5m]))   # cửa sổ 5m
      /
      sum(rate(flask_http_request_total{namespace="demo"}[5m]))
    ) > 0.144
  for: 2m             # ← phải đúng liên tục 2 phút mới fire (tránh spike thoáng qua)
  labels:
    severity: critical
  annotations:
    summary: "🔥 Fast Burn: Backend API error budget cháy nhanh"
    description: |
      Error rate vượt ngưỡng fast burn (>14.4×).
      Error budget sẽ cạn trong ~2 ngày nếu không xử lý.
      Current error rate: {{ $value | humanizePercentage }}   # ← template Go
```

```yaml
# Dòng 134-158: SLOW BURN — WARNING
- alert: BackendAPISlowBurn
  expr: |
    (
      sum(rate(...[6h])) / sum(rate(...[6h]))   # cửa sổ 6h
    ) > 0.06    # burn rate > 6×
    and
    (
      sum(rate(...[30m])) / sum(rate(...[30m]))  # cửa sổ 30m
    ) > 0.06
  for: 15m      # ← phải đúng 15 phút (slow burn diễn ra chậm, cần confirm)
  labels:
    severity: warning
```

**Tóm tắt ngưỡng:**

| Alert | Error Rate ngưỡng | Burn Rate | Budget hết sau | Severity |
|-------|-------------------|-----------|----------------|----------|
| FastBurn | > 14.4% | > 14.4× | ~2 ngày | CRITICAL |
| SlowBurn | > 6% | > 6× | ~5 ngày | WARNING |
| SLOBreach | SLI < 99.5% | N/A | Đã vi phạm | CRITICAL |

---

## 6. Argo Rollouts & Canary Deployment

### Khái niệm

**Deployment thông thường** = thay toàn bộ pods cùng lúc → Nếu lỗi → 100% user bị ảnh hưởng.

**Canary Deployment** = thay dần từng phần nhỏ:
```
Stable (v1): 100% traffic
    ↓ deploy v2
Stable (v1): 80% + Canary (v2): 20%   ← quan sát
    ↓ nếu OK
Stable (v1): 50% + Canary (v2): 50%   ← tiếp tục
    ↓ nếu OK
Canary (v2): 100%                       ← promote
```

**Argo Rollouts** thay thế K8s Deployment thông thường, thêm khả năng điều phối canary traffic qua 2 Service riêng biệt.

### Code thực tế — `backend/k8s/rollout.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout              # ← KHÔNG phải kind: Deployment
metadata:
  name: backend
  namespace: demo
spec:
  replicas: 4              # ← tổng số pods
  selector:
    matchLabels:
      app: backend
  template:                # ← giống Deployment template
    spec:
      containers:
        - name: api
          image: w9-api:1
          env:
            - name: ERROR_RATE
              value: "0.0"    # ← v1 bình thường
            - name: VERSION
              value: "v1"

  strategy:
    canary:
      canaryService: backend-preview-service   # ← Service nhận canary traffic
      stableService: backend-service           # ← Service nhận stable traffic

      analysis:            # ← tự chấm điểm canary
        templates:
          - templateName: success-rate-analysis
        startingStep: 1    # ← bắt đầu chấm sau bước 1 (setWeight 20%)

      steps:
        - setWeight: 20    # Bước 1: 20% request → canary pods
        - pause: {duration: 30s}   # Đợi 30s (có thể đổi thành {} để pause vô hạn)
        - setWeight: 50    # Bước 3: 50% → canary
        - pause: {duration: 30s}
        - setWeight: 100   # Bước 5: 100% → canary (promote hoàn tất)
```

**Cách Argo Rollouts chia traffic:**

```
Tổng 4 pods, canary = 20% → 1 pod canary, 3 pod stable

Service "backend-service" (stable)        → selector: app=backend, rollouts-pod-template-hash=<stable_hash>
Service "backend-preview-service" (canary) → selector: app=backend, rollouts-pod-template-hash=<canary_hash>

Client request đến NodePort :30080 → backend-service → chỉ stable pods
Client request đến NodePort :30081 → backend-preview-service → chỉ canary pods
```

### Để test Lab 4 — Manual Promote

Đổi trong `rollout.yaml`:
```yaml
# Từ:
- pause: {duration: 30s}
# Thành:
- pause: {}    # ← vô hạn, phải promote tay
```

Rồi promote:
```bash
kubectl argo rollouts promote backend -n demo
```

---

## 7. AnalysisTemplate & AUTO-ABORT

### Khái niệm

**AnalysisTemplate** định nghĩa "tiêu chí chấm điểm" cho canary — query Prometheus định kỳ, nếu metrics xấu → tự động abort rollout.

Đây là điểm mấu chốt: **không cần human watch và abort tay**.

### Code thực tế — `backend/k8s/analysis-template.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate-analysis
  namespace: demo
spec:
  metrics:
    # ── METRIC 1: Success Rate (quan trọng nhất) ──
    - name: success-rate
      initialDelay: 20s    # ← đợi 20s để canary có đủ data trước khi chấm
      interval: 30s        # ← query Prometheus mỗi 30 giây
      count: 5             # ← tổng 5 lần query (5 × 30s = 150s)
      successCondition: result[0] >= 0.95   # ← phải >= 95% thành công
      failureLimit: 2      # ← tệ 2 lần → ABORT (nghiêm ngặt)
      provider:
        prometheus:
          address: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
          query: |
            sum(rate(flask_http_request_total{namespace="demo",status!~"5.."}[2m]))
            /
            sum(rate(flask_http_request_total{namespace="demo"}[2m]))
            # Trả về: số từ 0.0 đến 1.0
            # 0.8 nghĩa là 80% thành công → < 0.95 → FAILURE

    # ── METRIC 2: Request Rate > 0 (service còn sống) ──
    - name: request-rate-alive
      interval: 30s
      count: 3
      successCondition: result[0] >= 0   # ← chỉ cần > 0 là có traffic
      failureLimit: 3
      provider:
        prometheus:
          query: |
            sum(rate(flask_http_request_total{namespace="demo"}[1m])) or vector(0)
            # "or vector(0)": nếu không có data → trả 0 thay vì error

    # ── METRIC 3: Latency p99 < 500ms ──
    - name: latency-p99
      initialDelay: 30s    # ← đợi lâu hơn để histogram có đủ buckets
      interval: 30s
      count: 4
      successCondition: result[0] < 0.5   # ← p99 phải < 0.5s (500ms)
      failureLimit: 3
      provider:
        prometheus:
          query: |
            histogram_quantile(0.99,
              sum(rate(flask_http_request_duration_seconds_bucket{namespace="demo"}[2m]))
              by (le)
            ) or vector(0)
            # histogram_quantile(0.99,...) = giá trị mà 99% request hoàn thành dưới đó
            # "or vector(0)": tránh lỗi khi không có histogram data
```

### Timeline khi deploy canary v3 với ERROR_RATE=0.2

```
T+0s    git push: VERSION=v3, ERROR_RATE=0.2
T+30s   ArgoCD sync → Argo Rollouts tạo 1 canary pod (v3)
T+60s   setWeight: 20% → 1/4 pod là v3
T+80s   AnalysisRun bắt đầu (initialDelay: 20s)
T+80s   Query 1: success_rate = 0.80 < 0.95 → FAILURE #1
T+110s  Query 2: success_rate = 0.79 < 0.95 → FAILURE #2
T+110s  failureLimit=2 exceeded → AnalysisRun Phase: Failed
T+110s  Rollout nhận FAILED signal → tự ABORT
T+120s  4/4 pods trở về v2 (stable)
T+120s  Toàn bộ traffic về stable NodePort :30080
```

### Sơ đồ quyết định AUTO-ABORT

```
AnalysisRun Running
    ↓
Query Prometheus mỗi 30s
    ↓
success_rate >= 0.95 ?
├── CÓ → Success #n, tiếp tục
│         ↓
│     count = 5 → AnalysisRun: Successful → Promote canary ✅
│
└── KHÔNG → Failure #n
          ↓
      failures >= failureLimit (2)?
      ├── KHÔNG → tiếp tục query
      └── CÓ → AnalysisRun: Failed
                    ↓
               Rollout ABORT
                    ↓
               Traffic 100% → stable ✅
```

---

## 8. Luồng Hoàn Chỉnh — Big Picture

### Flow 1: Deploy thành công (canary v2)

```
1. git push (VERSION=v2, ERROR_RATE=0)
        ↓
2. ArgoCD detect thay đổi (3 phút)
        ↓
3. ArgoCD apply rollout.yaml
        ↓
4. Argo Rollouts tạo canary pod (v2)
        ↓
5. setWeight 20%: 1 pod v2, 3 pod v1
        ↓
6. AnalysisRun bắt đầu query Prometheus
        ↓
7. success_rate = 1.0 ≥ 0.95 → SUCCESS × 5
   latency_p99 = 0.02s < 0.5s → SUCCESS × 4
        ↓
8. AnalysisRun: Successful
        ↓
9. setWeight 50% → setWeight 100%
        ↓
10. Promote: 4/4 pods là v2
        ↓
11. kubectl argo rollouts history → REVISION 2: v2 ✅
```

### Flow 2: Auto-abort (canary v3 có lỗi)

```
1. git push (VERSION=v3, ERROR_RATE=0.2)
        ↓
2-5. (giống trên)
        ↓
6. AnalysisRun bắt đầu query
        ↓
7. success_rate = 0.8 < 0.95 → FAILURE × 2
        ↓
8. AnalysisRun: Failed (failureLimit=2)
        ↓
9. Rollout ABORT → traffic về v2
        ↓
10. BackendAPIFastBurn fire (Prometheus detect error rate > 14.4%)
        ↓
11. AlertManager route: severity=critical → receiver email-critical
        ↓
12. Gmail SMTP gửi email HTML đến thihtktk@gmail.com (trong 10s)
        ↓
13. curl /api/status → "version": "v2" ← user không bao giờ thấy v3 ở scale > 20%
```

### Flow 3: GitOps Self-Heal

```
1. kubectl delete deployment frontend -n demo (giả lập tai nạn)
        ↓
2. K8s xóa deployment
        ↓
3. ArgoCD reconciliation loop (mỗi 3 phút)
        ↓
4. So sánh: Git có frontend.yaml ≠ Cluster không có frontend
        ↓
5. OutOfSync detected
        ↓
6. selfHeal: true → ArgoCD tự apply frontend.yaml
        ↓
7. Frontend pods Running lại
        ↓
8. Tổng thời gian: < 3 phút ✅
```

---

## Tóm Tắt Mối Quan Hệ Giữa Các Thành Phần

```
┌─────────────────────────────────────────────────────────────┐
│                    Flask App (app.py)                        │
│  ERROR_RATE env → inject 500 errors                         │
│  prometheus_flask_exporter → expose /metrics                 │
└──────────────────────┬──────────────────────────────────────┘
                       │ scrape mỗi 15s (ServiceMonitor)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Prometheus                                │
│  Lưu: flask_http_request_total, duration_seconds_bucket     │
│  Recording rules → tính sẵn success_rate, burn_rate        │
│  Alert rules → BackendAPIFastBurn, SlowBurn, SLOBreach      │
└──────┬──────────────────────────────┬───────────────────────┘
       │ query mỗi 30s                │ fire alerts
       ▼                              ▼
┌──────────────┐              ┌──────────────────────────────┐
│AnalysisRun   │              │      AlertManager             │
│ success_rate │              │  Route: critical → email-crit │
│ >= 95%? ─────┤              │  Route: warning → email-warn  │
│   NO → ABORT │              │  Inhibit: FastBurn → suppress │
│  YES → next  │              │         SlowBurn              │
└──────┬───────┘              └──────────────┬────────────────┘
       │                                     │
       ▼                                     ▼
┌──────────────────┐                 ┌──────────────┐
│  Argo Rollouts   │                 │  Gmail SMTP  │
│  ABORT rollout   │                 │  :587 TLS    │
│  traffic → v2   │                 │  HTML email  │
└──────────────────┘                 └──────────────┘
```

---

> 📖 **Đọc thêm:**
> - [Google SRE Book — SLO/SLI/Error Budget](https://sre.google/sre-book/service-level-objectives/)
> - [Multi-window Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos/)
> - [Argo Rollouts Concepts](https://argoproj.github.io/argo-rollouts/concepts/)
> - [OpenTelemetry Docs](https://opentelemetry.io/docs/)
> - [prometheus_flask_exporter](https://github.com/rycus86/prometheus_flask_exporter)
