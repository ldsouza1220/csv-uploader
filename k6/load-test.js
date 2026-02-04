import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuration - update TARGET_URL before running
const TARGET_URL = __ENV.TARGET_URL || 'http://localhost:8080';

export const options = {
  stages: [
    // Ramp up to 50 users over 1 minute
    { duration: '1m', target: 50 },
    // Ramp up to 200 users over 2 minutes
    { duration: '2m', target: 200 },
    // Stay at 200 users for 3 minutes (trigger scaling)
    { duration: '3m', target: 200 },
    // Ramp up to 500 users for max pressure
    { duration: '2m', target: 500 },
    // Hold at 500 users
    { duration: '3m', target: 500 },
    // Ramp down
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be < 500ms
    http_req_failed: ['rate<0.1'],    // Less than 10% failure rate
  },
};

export default function () {
  // Hit the main page
  const resMain = http.get(`${TARGET_URL}/`);
  check(resMain, {
    'main page status is 200': (r) => r.status === 200,
  });

  // Small sleep to simulate real user behavior
  sleep(0.1);
}
