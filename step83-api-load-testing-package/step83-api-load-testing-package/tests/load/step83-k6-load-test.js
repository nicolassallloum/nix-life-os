import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const API_BASE = __ENV.API_BASE || 'http://127.0.0.1:8000/api/v1';
const ADMIN_TOKEN = __ENV.ADMIN_TOKEN || '';
const ADMIN_EMAIL = __ENV.ADMIN_EMAIL || 'step74.admin@gmail.com';
const ADMIN_PASSWORD = __ENV.ADMIN_PASSWORD || 'Password@123';

export const errorRate = new Rate('step83_error_rate');
export const apiDuration = new Trend('step83_api_duration');

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
      tags: { phase: 'smoke' },
    },
    baseline: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 25 },
        { duration: '30s', target: 0 },
      ],
      startTime: '35s',
      tags: { phase: 'baseline' },
    },
    stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 50 },
        { duration: '1m', target: 50 },
        { duration: '30s', target: 0 },
      ],
      startTime: '2m45s',
      tags: { phase: 'stress' },
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1200'],
    'http_req_duration{group:::Dashboard}': ['p(95)<800'],
    'http_req_duration{group:::Finance}': ['p(95)<900'],
    'http_req_duration{group:::Health}': ['p(95)<1000'],
    'http_req_duration{group:::Projects}': ['p(95)<900'],
    'http_req_duration{group:::Productivity}': ['p(95)<1000'],
    'http_req_duration{group:::AI}': ['p(95)<1800'],
    step83_error_rate: ['rate<0.01'],
  },
};

function authHeaders(token) {
  return {
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
    timeout: '30s',
  };
}

function postHeaders(token = '') {
  const headers = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  return { headers, timeout: '30s' };
}

export function setup() {
  if (ADMIN_TOKEN) {
    return { token: ADMIN_TOKEN };
  }

  const res = http.post(
    `${API_BASE}/auth/login`,
    JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
    postHeaders()
  );

  const ok = check(res, {
    'login status is 200': (r) => r.status === 200,
    'login has token': (r) => Boolean(r.json('data.token') || r.json('token') || r.json('access_token')),
  });

  if (!ok) {
    throw new Error(`Login failed. Status=${res.status} Body=${res.body}`);
  }

  return { token: res.json('data.token') || res.json('token') || res.json('access_token') };
}

function getEndpoint(name, path, token) {
  const res = http.get(`${API_BASE}${path}`, authHeaders(token));
  const ok = check(res, {
    [`${name} returns 200`]: (r) => r.status === 200,
    [`${name} returns json`]: (r) => String(r.headers['Content-Type'] || '').includes('application/json'),
  });
  errorRate.add(!ok);
  apiDuration.add(res.timings.duration, { endpoint: name });
}

export default function (data) {
  const token = data.token;

  group('Dashboard', () => {
    getEndpoint('dashboard_summary', '/dashboard/summary', token);
    getEndpoint('life_balance_summary', '/life-balance/summary', token);
  });

  group('Finance', () => {
    getEndpoint('finance_accounts', '/finance/accounts', token);
    getEndpoint('finance_transactions', '/finance/transactions', token);
    getEndpoint('finance_budgets', '/finance/budgets', token);
  });

  group('Health', () => {
    getEndpoint('health_dashboard', '/health/dashboard', token);
    getEndpoint('health_steps', '/health/steps', token);
    getEndpoint('health_weight_summary', '/health/weight/summary', token);
    getEndpoint('health_nutrition_summary', '/health/nutrition/summary', token);
    getEndpoint('health_hydration_daily', '/health/hydration/summary/daily', token);
  });

  group('Projects', () => {
    getEndpoint('projects_dashboard', '/projects/dashboard', token);
    getEndpoint('projects_index', '/projects', token);
  });

  group('Productivity', () => {
    getEndpoint('productivity_dashboard', '/productivity/dashboard', token);
    getEndpoint('productivity_tasks', '/productivity/tasks', token);
    getEndpoint('productivity_goals', '/productivity/goals', token);
    getEndpoint('productivity_habits', '/productivity/habits', token);
  });

  group('AI', () => {
    getEndpoint('finance_ai_insights', '/finance/ai-insights', token);
    getEndpoint('health_ai_insights', '/health/ai-insights', token);
    getEndpoint('productivity_ai_insights', '/productivity/ai-insights', token);
    getEndpoint('ai_recommendations', '/ai/recommendations', token);
    getEndpoint('ai_scores_daily', '/ai/scores/daily', token);
  });

  group('Authentication', () => {
    getEndpoint('auth_me', '/auth/me', token);
  });

  sleep(1);
}
