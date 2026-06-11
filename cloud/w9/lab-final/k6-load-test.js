/**
 * k6 Load Test — W9 Lab Final
 * Từ slide buổi chiều: giả lập traffic để trigger SLO alerts + canary abort
 *
 * Kịch bản:
 *   - 85% request thành công → /  (normal traffic)
 *   - 15% request lỗi       → /error (trigger 500)
 *
 * Chạy:
 *   TARGET_URL=http://<MINIKUBE_IP>:30080 k6 run k6-load-test.js
 *
 * Kết quả mong đợi:
 *   - Burn rate > 14.4 → Alert BackendAPIFastBurn fires
 *   - AnalysisTemplate phát hiện success_rate < 95% → Canary ABORT
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';

// ── Custom Metrics ─────────────────────────────────────────
const errorRate   = new Rate('error_rate');
const successRate = new Rate('success_rate');
const totalReqs   = new Counter('total_requests');

// ── Test Config ────────────────────────────────────────────
export const options = {
  stages: [
    { duration: '30s', target: 5  },   // Ramp up
    { duration: '3m',  target: 10 },   // Steady load (trigger alerts)
    { duration: '1m',  target: 20 },   // Spike
    { duration: '30s', target: 0  },   // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    'error_rate':        ['rate<0.2'],  // Không quá 20% lỗi tổng thể
  },
};

// ── Main Test Function ─────────────────────────────────────
export default function () {
  const BASE = __ENV.TARGET_URL || 'http://localhost:30080';

  // 85% normal request — success
  if (Math.random() < 0.85) {
    const res = http.get(`${BASE}/`);
    const ok = check(res, {
      'status 200': (r) => r.status === 200,
    });
    successRate.add(ok);
    errorRate.add(!ok);
    totalReqs.add(1);

  // 15% error trigger — để giả lập canary lỗi
  } else {
    // Gửi tới stable service với header giả lập lỗi
    // Hoặc gửi tới endpoint không tồn tại
    const res = http.get(`${BASE}/nonexistent-path-to-trigger-error`);
    const isError = check(res, {
      'expected 404': (r) => r.status === 404 || r.status === 500,
    });
    errorRate.add(true);
    successRate.add(false);
    totalReqs.add(1);
  }

  sleep(0.5);
}

// ── Summary ────────────────────────────────────────────────
export function handleSummary(data) {
  const dur = data.metrics.http_req_duration;
  const errR = data.metrics.error_rate;

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  W9 Load Test Summary');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Total Requests : ${data.metrics.total_requests?.values?.count || 'N/A'}`);
  console.log(`  Error Rate     : ${((errR?.values?.rate || 0) * 100).toFixed(1)}%`);
  console.log(`  p95 Latency    : ${dur?.values?.['p(95)']?.toFixed(0) || 'N/A'}ms`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  Kiểm tra:');
  console.log('  - Prometheus Alert: BackendAPIFastBurn fired?');
  console.log('  - Argo Rollouts: canary ABORTED?');
  console.log('  - Grafana: Error Budget sụt giảm?');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  return {};
}
