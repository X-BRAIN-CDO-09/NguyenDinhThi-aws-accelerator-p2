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
  // Read target URL from environment or fallback to localhost NodePort
  const url = __ENV.TARGET_URL || 'http://localhost:30080';
  
  // 85% of requests go to healthy root page
  // 15% of requests go to non-existent path to trigger 404 errors (triggers SLO burn & Canary rollback)
  const isErrorRequest = Math.random() < 0.15;
  const path = isErrorRequest ? '/invalid-page-to-trigger-rollback' : '/';
  
  const res = http.get(`${url}${path}`);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  
  sleep(0.1); // 100ms pause between requests
}
