import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // ramp up to 20 users
    { duration: '1m', target: 20 },  // stay at 20 users
    { duration: '30s', target: 0 },  // scale down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
  },
};

export default function () {
  // Nhắm tới Backend NodePort (active service)
  const baseUrl = __ENV.TARGET_URL || 'http://localhost:30080';

  // 85% request hợp lệ -> trả về 200 OK
  // 15% request sai -> trigger SLO burn & Canary rollback
  const isErrorRequest = Math.random() < 0.15;
  const path = isErrorRequest ? '/invalid-path-to-trigger-rollback' : '/api.json';

  const res = http.get(`${baseUrl}${path}`);

  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });

  sleep(0.1); // 100ms pause between requests
}
