# 📸 Evidence — W9 Lab Final: GitOps + SLO Observability + Canary Deployment

> **Sinh viên:** Nguyễn Đình Thi  
> **Ngày nộp:** _______________  
> **Repo:** https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2  
> **Cluster:** EC2 Instance (t3.large) + Minikube profile `w9` (Public IP: 47.128.221.30)

---

## Hướng Dẫn Chụp

| Ký hiệu | Nghĩa |
|---------|-------|
| 🖥️ | Chụp toàn màn hình terminal |
| 🌐 | Chụp toàn tab trình duyệt (bao gồm URL bar) |
| 🔍 | Zoom vào khu vực cụ thể |
| ✅ | Bắt buộc phải có |
| ⭐ | Điểm thưởng / Challenge |

---

## PHẦN 1 — GitOps & ArgoCD App-of-Apps

### 📸 SS-01: Cấu Trúc Git Repository
```
Chụp: VS Code hoặc File Explorer mở folder lab-final/
Cần thấy:
  ✅ argocd/root.yaml  và  argocd/apps/*.yaml
  ✅ backend/k8s/rollout.yaml
  ✅ infra/k8s/prometheus-rule.yaml
  ✅ infra/k8s/alertmanager-config.yaml  (file mới)
  ✅ .github/workflows/ci-build.yaml     (file mới)
```
**Label:** `SS-01_git_repo_structure.png`

![Ss-01 Git Repo Structure](images/SS-01_git_repo_structure.png)

---

### 📸 SS-02: GitHub Actions CI — Validate Pass ✅
```
URL: https://github.com/<your-repo>/actions
Chụp: Tab GitHub Actions trên trình duyệt
Cần thấy:
  ✅ Workflow "validate-manifests" hoặc "ci-build-validate" → ✔ green check
  ✅ Tên branch/commit rõ ràng
  ✅ Tất cả jobs: validate + build-verify đều PASS
```
**Label:** `SS-02_github_actions_ci_pass.png`

![Ss-02 Github Actions Ci Pass](images/SS-02_github_actions_ci_pass.png)

---

### 📸 SS-03: ArgoCD — App-of-Apps Overview (Root App)
```
URL: https://47.128.221.30:8080
Chụp: Trang chủ ArgoCD hiển thị tất cả Applications
Cần thấy:
  ✅ 6 Applications:
      root                    Synced  Healthy
      kube-prometheus-stack   Synced  Healthy
      argo-rollouts           Synced  Healthy
      infra                   Synced  Healthy
      backend                 Synced  Healthy
      frontend                Synced  Healthy
  ✅ URL bar hiển thị https://47.128.221.30:8080
```
**Label:** `SS-03_argocd_all_apps_healthy.png`

![Ss-03 Argocd All Apps Healthy](images/SS-03_argocd_all_apps_healthy.png)

---

### 📸 SS-04: ArgoCD — App Details (Backend App)
```
URL: https://47.128.221.30:8080/applications/argocd/backend
Chụp: Click vào app "backend" → xem cây tài nguyên
Cần thấy:
  ✅ Rollout, Service, AnalysisTemplate objects
  ✅ SYNC STATUS: Synced
  ✅ HEALTH STATUS: Healthy
  ✅ Source: repo GitHub của bạn + path backend/k8s/
```
**Label:** `SS-04_argocd_backend_app_detail.png`

![Ss-04 Argocd Backend App Detail](images/SS-04_argocd_backend_app_detail.png)

---

### 📸 SS-05: ArgoCD — Infra App (Monitoring Stack)
```
URL: https://47.128.221.30:8080/applications/argocd/infra
Chụp: Click vào app "infra" → xem resources
Cần thấy:
  ✅ ServiceMonitor, PrometheusRule, ConfigMap (grafana dashboard)
  ✅ Secret alertmanager-kube-prometheus-stack  ← Gap 1 mới
  ✅ OTel Collector
  ✅ Tất cả Synced + Healthy
```
**Label:** `SS-05_argocd_infra_app_detail.png`

![Ss-05 Argocd Infra App Detail](images/SS-05_argocd_infra_app_detail.png)

---

### 📸 SS-06: Terminal — kubectl get applications
```
Chụp: Terminal chạy lệnh
Command:
  kubectl -n argocd get applications
Cần thấy:
  ✅ 6 apps, tất cả STATUS=Synced HEALTH=Healthy
  ✅ Có timestamp SYNC AGE
```
**Label:** `SS-06_kubectl_get_applications.png`

![Ss-06 Kubectl Get Applications](images/SS-06_kubectl_get_applications.png)

---

## PHẦN 2 — Kubernetes Workloads

### 📸 SS-07: Terminal — Tất Cả Pods Running
```
Chụp: Terminal
Command:
  kubectl get pods -A | grep -Ev "kube-system|Completed"
Cần thấy:
  ✅ Namespace demo: backend pods, frontend pods
  ✅ Namespace monitoring: prometheus, grafana, alertmanager
  ✅ Namespace argocd: argocd-server, argocd-application-controller...
  ✅ TẤT CẢ STATUS = Running
  ✅ KHÔNG có Pending, CrashLoopBackOff, Error
```
**Label:** `SS-07_all_pods_running.png`

![Ss-07 All Pods Running](images/SS-07_all_pods_running.png)

---

### 📸 SS-08: Terminal — Rollout Status v1 Healthy
```
Chụp: Terminal
Command:
  kubectl argo rollouts get rollout backend -n demo
Cần thấy:
  ✅ Name: backend
  ✅ Status: ✔ Healthy
  ✅ Strategy: Canary
  ✅ Images: w9-api:1
  ✅ Pods: 4/4 running (stable)
```
**Label:** `SS-08_rollout_v1_healthy.png`

![Ss-08 Rollout V1 Healthy](images/SS-08_rollout_v1_healthy.png)

---

## PHẦN 3 — Observability Stack (Slide Chiều)

### 📸 SS-09: Prometheus — Targets UP
```
URL: http://47.128.221.30:9090/targets
Chụp: Trang Prometheus Targets
Cần thấy:
  ✅ Job "demo/backend-metrics" → State: UP (màu xanh)
  ✅ URL scrape: http://<pod-ip>:8080/metrics
  ✅ Last Scrape: vài giây trước
```
**Label:** `SS-09_prometheus_targets_up.png`

![Ss-09 Prometheus Targets Up](images/SS-09_prometheus_targets_up.png)

---

### 📸 SS-10: Prometheus — flask_http_request_total Metric
```
URL: http://47.128.221.30:9090/graph
Chụp: Query tab Graph
Cần thấy:
  ✅ Query: flask_http_request_total
  ✅ Có data trả về (bảng hoặc graph)
  ✅ Labels: namespace="demo", method, status
```
**Label:** `SS-10_prometheus_flask_metrics.png`

![Ss-10 Prometheus Flask Metrics](images/SS-10_prometheus_flask_metrics.png)

---

### 📸 SS-11: Prometheus — Alert Rules (3 rules)
```
URL: http://47.128.221.30:9090/rules
Chụp: Trang Rules
Cần thấy:
  ✅ BackendAPIFastBurn  (severity: critical)
  ✅ BackendAPISlowBurn  (severity: warning)
  ✅ BackendAPISLOBreach (severity: critical)
  ✅ Recording rules: job:flask_http_request_success_rate:*
  ✅ Gap 6 mới: job:flask_http_stable_success_rate:ratio_rate5m
  ✅ Gap 6 mới: job:flask_http_canary_success_rate:ratio_rate5m
  ✅ Gap 3 mới: job:flask_http_error_budget_remaining:ratio_rate30d
```
**Label:** `SS-11_prometheus_alert_rules.png`

![Ss-11 Prometheus Alert Rules](images/SS-11_prometheus_alert_rules.png)

---

### 📸 SS-12: Prometheus — Burn Rate Query
```
URL: http://47.128.221.30:9090/graph
Chụp: Query tab
Query (dán vào):
  sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1h]))
  / sum(rate(flask_http_request_total{namespace="demo"}[1h])) / 0.005
Cần thấy:
  ✅ Query chạy được, có result (số hoặc graph)
  ✅ Giải thích được ý nghĩa: đây là Burn Rate (> 14.4 = CRITICAL)
```
**Label:** `SS-12_prometheus_burn_rate_query.png`

![Ss-12 Prometheus Burn Rate Query](images/SS-12_prometheus_burn_rate_query.png)

---

### 📸 SS-13: Grafana — Dashboard Overview (10 Panels)
```
URL: http://47.128.221.30:3000 → Dashboard "W9 Lab Final Dashboard — SLO + Canary"
Chụp: Toàn bộ dashboard (scroll để thấy hết các rows)
Cần thấy:
  ✅ Row 1: Request Rate, Error Rate 5xx, Latency p95+p99
  ✅ Row 2: SLI Availability, Canary Success Rate
  ✅ Row 2: 🏦 Error Budget Remaining gauge (GAP 3 MỚI)
  ✅ Row 2: ⚡ Burn Rate stat (GAP 3 MỚI)
  ✅ Row 3: Burn Rate Timeline với đường 14.4x và 6x đỏ/cam (GAP 3 MỚI)
  ✅ Row 3: Error Budget Burndown chart (GAP 3 MỚI)
  ✅ Row 4: Canary vs Stable Error Rate split (GAP 6 MỚI)
  ✅ Row 4: Traffic Volume Stable vs Canary bar (GAP 6 MỚI)
```
**Label:** `SS-13_grafana_dashboard_overview.png`

![Ss-13 Grafana Dashboard Overview](images/SS-13_grafana_dashboard_overview.png)

---

### 📸 SS-14: Grafana — Error Budget Gauge (Gap 3)
```
URL: http://47.128.221.30:3000
Chụp: Zoom vào panel "🏦 Error Budget Remaining"
Cần thấy:
  ✅ Gauge hiển thị % (ví dụ: 95% = còn nhiều budget)
  ✅ Màu xanh = OK, vàng = Low, đỏ = CRITICAL
  ✅ Tiêu đề panel rõ ràng
```
**Label:** `SS-14_grafana_error_budget_gauge.png`

![Ss-14 Grafana Error Budget Gauge](images/SS-14_grafana_error_budget_gauge.png)

---

### 📸 SS-15: Grafana — Burn Rate Timeline (Gap 3)
```
URL: http://47.128.221.30:3000
Chụp: Zoom vào panel "Burn Rate Timeline"
Cần thấy:
  ✅ Đường Burn Rate (1h window) màu xanh
  ✅ Đường threshold 14.4x màu đỏ đứt (---)
  ✅ Đường threshold 6x màu cam đứt (---)
  ✅ Legend hiển thị ở bên phải
```
**Label:** `SS-15_grafana_burn_rate_timeline.png`

![Ss-15 Grafana Burn Rate Timeline](images/SS-15_grafana_burn_rate_timeline.png)

---

### 📸 SS-16: AlertManager — Receivers Config (Gap 1)
```
URL: http://47.128.221.30:9093
Chụp: AlertManager UI → tab "Status" hoặc trang chủ
Cần thấy:
  ✅ Cluster Status: ready
  ✅ Receivers: email-critical, email-warning (không còn "null receiver")
  ✅ Global config: smtp_smarthost: smtp.gmail.com:587
```
**Label:** `SS-16_alertmanager_receivers_configured.png`

![Ss-16 Alertmanager Receivers Configured](images/SS-16_alertmanager_receivers_configured.png)

---

### 📸 SS-17: Terminal — kubectl get serviceMonitor
```
Chụp: Terminal
Command:
  kubectl get servicemonitor -n monitoring
Cần thấy:
  ✅ backend-metrics   tồn tại
  ✅ AGE > 0
```
**Label:** `SS-17_servicemonitor_exists.png`

![Ss-17 Servicemonitor Exists](images/SS-17_servicemonitor_exists.png)

---

## PHẦN 4 — Canary Deployment (Slide Chiều — Argo Rollouts)

### 📸 SS-18: Canary v2 — Bắt Đầu 20%
```
URL: http://47.128.221.30:3100 (Argo Rollouts Dashboard)
Chụp: Ngay khi canary bắt đầu ở bước 20%
Cần thấy:
  ✅ Rollout: backend
  ✅ Step 1/5: setWeight 20%
  ✅ 1 pod màu vàng (canary) + 3 pods màu xanh (stable)
  ✅ AnalysisRun: Running
```
**Label:** `SS-18_canary_v2_start_20pct.png`

![Ss-18 Canary V2 Start 20Pct](images/SS-18_canary_v2_start_20pct.png)

---

### 📸 SS-19: Canary v2 — AnalysisRun PASS
```
Chụp: Argo Rollouts Dashboard hoặc Terminal
Command (terminal):
  kubectl argo rollouts get rollout backend -n demo --watch
Cần thấy:
  ✅ AnalysisRun: Successful ✔
  ✅ Metrics: success-rate PASS, latency-p99 PASS (Gap 4 mới!)
  ✅ Đang ở bước setWeight 50% hoặc 100%
```
**Label:** `SS-19_canary_v2_analysis_pass.png`

![Ss-19 Canary V2 Analysis Pass](images/SS-19_canary_v2_analysis_pass.png)

---

### 📸 SS-20: Canary v2 — Promoted 100% ✅
```
Chụp: Terminal hoặc Argo Rollouts Dashboard
Command:
  kubectl argo rollouts get rollout backend -n demo
Cần thấy:
  ✅ Status: ✔ Healthy
  ✅ Image: w9-api:2
  ✅ 4/4 pods stable (tất cả màu xanh)
  ✅ Rollout history: revision 2
```
**Label:** `SS-20_canary_v2_promoted_100pct.png`

![Ss-20 Canary V2 Promoted 100Pct](images/SS-20_canary_v2_promoted_100pct.png)

---

### 📸 SS-21: curl /api/status → version v2
```
Chụp: Terminal
Command:
  curl http://$MINIKUBE_IP:30080/api/status | python3 -m json.tool
Cần thấy:
  ✅ "version": "v2"
  ✅ "ok": true
  ✅ Không có lỗi
```
**Label:** `SS-21_api_status_v2.png`

![Ss-21 Api Status V2](images/SS-21_api_status_v2.png)

---

## PHẦN 5 — ⭐ CHALLENGE: Canary Auto-Abort (Quan Trọng Nhất)

### 📸 SS-22: ⭐ Canary v3 — Bắt Đầu với ERROR_RATE=0.2
```
Chụp: Terminal
Command:
  kubectl argo rollouts get rollout backend -n demo --watch
Cần thấy:
  ✅ Status: Progressing
  ✅ Step: setWeight 20% (canary đang nhận 20% traffic)
  ✅ Image: w9-api:3 hoặc thấy ENV ERROR_RATE=0.2
  ✅ AnalysisRun: Running (đang kiểm tra)
Thời điểm chụp: Ngay sau khi canary bắt đầu
```
**Label:** `SS-22_canary_v3_error_rate_start.png`

![Ss-22 Canary V3 Error Rate Start](images/SS-22_canary_v3_error_rate_start.png)

---

### 📸 SS-23: ⭐ AnalysisRun — FAIL (Success Rate < 95%)
```
Chụp: Terminal
Command:
  kubectl describe analysisrun \
    $(kubectl get analysisrun -n demo -o name | head -1) -n demo \
    | grep -A 15 "Metric Results"
Cần thấy:
  ✅ Metric: success-rate
  ✅ Phase: Failed
  ✅ Value: 0.8 (hoặc tương đương 80%)
  ✅ FailureLimit: 2  →  Failures: 2
  ✅ Message: "Metric assessed Failed..."
```
**Label:** `SS-23_analysisrun_fail_success_rate.png`

![Ss-23 Analysisrun Fail Success Rate](images/SS-23_analysisrun_fail_success_rate.png)

---

### 📸 SS-24: ⭐ Rollout — TỰ ABORT (Trạng Thái Aborted)
```
Chụp: Terminal (ngay khi thấy Aborted)
Command:
  kubectl argo rollouts get rollout backend -n demo
Cần thấy:
  ✅ Status: ✖ Degraded (hoặc Aborted)
  ✅ Message: "RolloutAborted: Metric 'success-rate' assessed Failed..."
  ✅ Image canary: đã bị remove
  ✅ 4/4 pods trở về stable (v2)
```
**Label:** `SS-24_rollout_auto_aborted.png`

![Ss-24 Rollout Auto Aborted](images/SS-24_rollout_auto_aborted.png)

---

### 📸 SS-25: ⭐ curl → Tự Rollback về v2
```
Chụp: Terminal
Command:
  curl http://$MINIKUBE_IP:30080/api/status | python3 -m json.tool
Cần thấy:
  ✅ "version": "v2"   ← KHÔNG phải v3!
  ✅ "ok": true
  (Chứng minh: canary v3 bị abort, user vẫn nhận v2 ổn định)
```
**Label:** `SS-25_api_status_rollback_v2.png`

![Ss-25 Api Status Rollback V2](images/SS-25_api_status_rollback_v2.png)

---

### 📸 SS-26: ⭐ Prometheus Alerts — BackendAPISLOBreach FIRING
```
URL: http://47.128.221.30:9090/alerts
Chụp: Trang Alerts
Cần thấy:
  ✅ BackendAPIFastBurn  → state: firing (màu đỏ)
  ✅ BackendAPISLOBreach → state: firing (màu đỏ)
  ✅ Severity: critical
  ✅ for: thời gian đang cháy
```
**Label:** `SS-26_prometheus_alerts_firing.png`

![Ss-26 Prometheus Alerts Firing](images/SS-26_prometheus_alerts_firing.png)

---

### 📸 SS-27: ⭐ Email Nhận Được — Alert Notification (Gap 1)
```
Chụp: Gmail inbox tại thihtktk@gmail.com
Cần thấy:
  ✅ Email từ: thihtktk@gmail.com (AlertManager)
  ✅ Subject: "🔥 [CRITICAL] BackendAPIFastBurn - W9 Lab" hoặc
             "🔥 [CRITICAL] BackendAPISLOBreach - W9 Lab"
  ✅ Nội dung: Alert name, Namespace, Summary, Description
  ✅ Timestamp của email
```
**Label:** `SS-27_email_alert_received.png`

![Ss-27 Email Alert Received](images/SS-27_email_alert_received.png)

---

## PHẦN 6 — Lab 4: Manual Promote

### 📸 SS-28: Rollout Paused — Chờ Approve ở 20%
```
Chụp: Terminal
Command:
  kubectl argo rollouts get rollout backend -n demo --watch
Cần thấy:
  ✅ Status: Paused ✋
  ✅ Step: "pause: {}" (vô hạn, không có duration)
  ✅ setWeight: 20%
  ✅ Message: "CanaryPauseStep"
```
**Label:** `SS-28_rollout_manual_paused_20pct.png`

![Ss-28 Rollout Manual Paused 20Pct](images/SS-28_rollout_manual_paused_20pct.png)

---

### 📸 SS-29: Manual Promote — kubectl argo rollouts promote
```
Chụp: Terminal (2 cửa sổ cạnh nhau nếu có thể)
Commands:
  # Cửa sổ 1: đang watch --watch
  # Cửa sổ 2: kubectl argo rollouts promote backend -n demo
Cần thấy:
  ✅ Lệnh promote được chạy
  ✅ Rollout tiến lên 50% → Paused lần 2
  ✅ Sau promote lần 2: setWeight 100% → Healthy
```
**Label:** `SS-29_manual_promote_command.png`

![Ss-29 Manual Promote Command](images/SS-29_manual_promote_command.png)

---

## PHẦN 7 — GitOps Self-Heal

### 📸 SS-30: Frontend Bị Xóa (kubectl delete)
```
Chụp: Terminal
Command:
  kubectl delete deployment frontend -n demo && \
  kubectl get pods -n demo -l app=frontend
Cần thấy:
  ✅ "deployment.apps frontend deleted"
  ✅ Ngay sau đó: "No resources found in demo namespace."
```
**Label:** `SS-30_frontend_deleted.png`

![Ss-30 Frontend Deleted](images/SS-30_frontend_deleted.png)

---

### 📸 SS-31: ArgoCD Self-Heal — Auto Restore
```
Chụp: ArgoCD UI hoặc terminal
Watch command:
  watch kubectl -n argocd get application frontend
Cần thấy:
  ✅ STATUS chuyển từ: Synced → OutOfSync → Syncing → Synced
  ✅ HEALTH: Degraded → Progressing → Healthy
  ✅ Thời gian tự heal < 3 phút
```
**Label:** `SS-31_argocd_self_heal.png`

![Ss-31 Argocd Self Heal](images/SS-31_argocd_self_heal.png)

---

### 📸 SS-32: Frontend Đã Hồi Phục
```
Chụp: Terminal + trình duyệt
Commands:
  kubectl get pods -n demo -l app=frontend
  curl -s http://$MINIKUBE_IP:30090 | head -3
Cần thấy:
  ✅ Pods: Running lại
  ✅ HTTP response: HTML frontend
```
**Label:** `SS-32_frontend_recovered.png`

![Ss-32 Frontend Recovered](images/SS-32_frontend_recovered.png)

---

## PHẦN 8 — Git Revert Rollback

### 📸 SS-33: git revert + git push
```
Chụp: Terminal
Commands:
  git log --oneline -3
  git revert HEAD
  git push
Cần thấy:
  ✅ Commit log hiển thị trước khi revert
  ✅ git revert tạo commit mới
  ✅ git push thành công
```
**Label:** `SS-33_git_revert_push.png`

![Ss-33 Git Revert Push](images/SS-33_git_revert_push.png)

---

### 📸 SS-34: Rollback Hoàn Tất — < 5 Phút
```
Chụp: Terminal
Command:
  kubectl argo rollouts get rollout backend -n demo
Cần thấy:
  ✅ Status: ✔ Healthy
  ✅ Image: version trước (v2)
  ✅ Revision history: tăng lên
  ✅ Chụp kèm: date/time để chứng minh thời gian < 5 phút
    (Gõ: date để hiện timestamp)
```
**Label:** `SS-34_rollback_complete_under_5min.png`

![Ss-34 Rollback Complete Under 5Min](images/SS-34_rollback_complete_under_5min.png)

---

## PHẦN 9 — Tổng Kết Kiến Trúc

### 📸 SS-35: ArgoCD — App-of-Apps Tree View
```
URL: https://47.128.221.30:8080/applications/argocd/root
Chụp: Click vào app "root" → xem cây app-of-apps
Cần thấy:
  ✅ root app → 5 child apps
  ✅ Cây quan hệ đầy đủ
  ✅ Tất cả leaf nodes: Synced + Healthy
```
**Label:** `SS-35_argocd_app_of_apps_tree.png`

![Ss-35 Argocd App Of Apps Tree](images/SS-35_argocd_app_of_apps_tree.png)

---

### 📸 SS-36: Terminal — kubectl argo rollouts history
```
Chụp: Terminal
Command:
  kubectl argo rollouts history rollout backend -n demo
Cần thấy:
  ✅ Lịch sử các lần deploy:
      REVISION 1: v1
      REVISION 2: v2 promoted
      REVISION 3: v3 aborted
      REVISION 4: (manual promote)
      REVISION 5: (revert)
```
**Label:** `SS-36_rollout_history.png`

![Ss-36 Rollout History](images/SS-36_rollout_history.png)

---

## 📋 Bảng Kiểm Tra Trước Khi Nộp

```
PHẦN 1 — GitOps & ArgoCD:
[ ] SS-01  Cấu trúc Git repo (có file mới: alertmanager-config.yaml, ci-build.yaml)
[ ] SS-02  GitHub Actions CI PASS (validate + build)
[ ] SS-03  ArgoCD 6 apps Synced + Healthy
[ ] SS-04  ArgoCD backend app detail
[ ] SS-05  ArgoCD infra app detail (có alertmanager Secret)
[ ] SS-06  kubectl get applications terminal

PHẦN 2 — K8s Workloads:
[ ] SS-07  Tất cả pods Running
[ ] SS-08  Rollout v1 Healthy

PHẦN 3 — Observability:
[ ] SS-09  Prometheus Targets UP
[ ] SS-10  flask_http_request_total metric có data
[ ] SS-11  Prometheus Rules (3 alerts + recording rules mới)
[ ] SS-12  Burn Rate query
[ ] SS-13  Grafana 10 panels overview
[ ] SS-14  Error Budget gauge (Gap 3)
[ ] SS-15  Burn Rate Timeline với thresholds (Gap 3)
[ ] SS-16  AlertManager receivers config (Gap 1)
[ ] SS-17  ServiceMonitor exists

PHẦN 4 — Canary Normal:
[ ] SS-18  Canary v2 bắt đầu 20%
[ ] SS-19  AnalysisRun PASS (success-rate + latency-p99)
[ ] SS-20  Canary v2 promoted 100%
[ ] SS-21  curl /api/status → v2

PHẦN 5 — ⭐ Challenge Auto-Abort:
[ ] SS-22  ⭐ Canary v3 ERROR_RATE=0.2 bắt đầu
[ ] SS-23  ⭐ AnalysisRun FAIL (success_rate=80% < 95%)
[ ] SS-24  ⭐ Rollout tự ABORT
[ ] SS-25  ⭐ curl → version v2 (đã rollback!)
[ ] SS-26  ⭐ Prometheus alerts FIRING
[ ] SS-27  ⭐ Email nhận được tại thihtktk@gmail.com

PHẦN 6 — Lab 4 Manual:
[ ] SS-28  Rollout paused vô hạn ở 20%
[ ] SS-29  kubectl promote command

PHẦN 7 — Self-Heal:
[ ] SS-30  kubectl delete deployment frontend
[ ] SS-31  ArgoCD tự heal
[ ] SS-32  Frontend recovered

PHẦN 8 — Git Revert:
[ ] SS-33  git revert + git push
[ ] SS-34  Rollback < 5 phút

PHẦN 9 — Tổng Kết:
[ ] SS-35  App-of-Apps tree view
[ ] SS-36  kubectl argo rollouts history

TỔNG: 36 screenshots
```

---

## 💡 Tips Chụp Màn Hình

1. **Luôn hiện URL bar** trong browser screenshots (chứng minh đúng service)
2. **Luôn hiện timestamp** trong terminal: gõ `date` trước khi chụp
3. **Chụp cả lệnh lẫn output** — không crop mất lệnh đã gõ
4. **Tên file** dùng format: `SS-XX_ten_mo_ta.png` để dễ sort
5. **Canary abort** (SS-22 → SS-25): Chuẩn bị trước, chụp liên tục vì diễn ra nhanh (~80 giây)
6. **Email alert** (SS-27): Trigger bằng k6 load test hoặc set ERROR_RATE=0.5 để alert fire nhanh hơn
