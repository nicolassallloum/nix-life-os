# STEP 83 — API Endpoint Matrix

Reviewed from `routes/api.php` and `php artisan route:list` in the uploaded export.

## Runtime Observed

| Item | Value |
|---|---|
| Laravel | 13.4.0 |
| PHP | 8.3.31 |
| Environment | production |
| Debug | off |
| Database | PostgreSQL |
| Cache driver | database |
| Queue driver | database |
| Route cache | not cached at export time |
| Config cache | not cached at export time |
| Public backend API | `http://127.0.0.1:8000/api/v1` |
| Backend container | `nixlifeos-backend` |
| Backend Nginx container | `nixlifeos-backend-nginx` |
| PostgreSQL host port | `5445` |

## Load Test Endpoint Set

| Group | Method | Endpoint | Priority | Notes |
|---|---:|---|---:|---|
| Dashboard | GET | `/dashboard/summary` | P0 | Main aggregator. Uses cache and multiple DB queries. |
| Dashboard | GET | `/life-balance/summary` | P0 | Cross-module summary endpoint. |
| Finance | GET | `/finance/accounts` | P0 | Account list. |
| Finance | GET | `/finance/transactions` | P0 | Transaction list; default limit appears to be 100. |
| Finance | GET | `/finance/budgets` | P1 | Budget list and budget-line calculations. |
| Finance AI | GET | `/finance/ai-insights` | P1 | Heavier AI/analytics endpoint. |
| Health | GET | `/health/dashboard` | P0 | Health module aggregator. |
| Health | GET | `/health/steps` | P1 | Step logs list. |
| Health | GET | `/health/steps/summary` | P1 | Aggregation endpoint. |
| Health | GET | `/health/weight` | P1 | Weight logs list. |
| Health | GET | `/health/weight/summary` | P1 | Aggregation endpoint. |
| Health | GET | `/health/nutrition` | P1 | Nutrition logs list. |
| Health | GET | `/health/nutrition/summary` | P1 | Aggregation endpoint. |
| Health | GET | `/health/hydration` | P1 | Hydration logs list. |
| Health | GET | `/health/hydration/summary/daily` | P1 | Daily aggregation endpoint. |
| Health | GET | `/health/reports/daily` | P2 | Report-style endpoint. |
| Health AI | GET | `/health/ai-insights` | P1 | Heavier AI/analytics endpoint. |
| Projects | GET | `/projects/dashboard` | P0 | Project aggregator. |
| Projects | GET | `/projects` | P1 | Project list. |
| Productivity | GET | `/productivity/dashboard` | P0 | Productivity aggregator. |
| Productivity | GET | `/productivity/tasks` | P1 | Task list. |
| Productivity | GET | `/productivity/goals` | P1 | Goal list. |
| Productivity | GET | `/productivity/habits` | P1 | Habit list. |
| Productivity AI | GET | `/productivity/ai-insights` | P1 | Heavy: multiple model counts and insight queries. |
| AI | GET | `/ai/recommendations` | P1 | Recommendation list. |
| AI | GET | `/ai/scores/daily` | P1 | Daily score history. |
| Auth | GET | `/auth/me` | P0 | Authenticated identity check. |
| Auth | POST | `/auth/login` | P0 | Public, throttled at `20,1`. Test separately with low concurrency. |
| Auth | POST | `/auth/register` | P2 | Public, throttled at `10,1`. Do not stress heavily unless using test emails. |

## Do Not Load Heavily Without Care

| Endpoint Type | Reason |
|---|---|
| POST create/update/delete endpoints | Load testing write endpoints can pollute production-like data. Use a seed/reset database first. |
| `/auth/login` high concurrency | The route is throttled. Heavy test should expect 429 responses. |
| AI generation POST `/ai/recommendations/generate` | May create records and trigger expensive rule evaluation. Run separately. |
| Alert run POST `/health/alerts/run` | Can create/update alert data. Run only in controlled test DB. |

