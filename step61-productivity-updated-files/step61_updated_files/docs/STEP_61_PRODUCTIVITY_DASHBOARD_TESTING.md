# STEP 61 — Productivity Dashboard Testing

## Updated / New Files

Copy these files into your project:

```bash
backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php
backend/app/Models/ProductivityTask.php
backend/app/Models/ProductivityHabit.php
backend/app/Models/ProductivityGoal.php
backend/app/Models/ProductivityCalendarEvent.php
backend/database/migrations/2026_05_14_000061_create_productivity_module_tables.php
backend/routes/api.php
frontend/src/services/productivityService.js
frontend/src/views/productivity/ProductivityDashboardView.vue
frontend/src/router/index.js
frontend/src/layouts/AppLayout.vue
```

## Apply Files

From `/u01/nix-life-os`:

```bash
cp -r step61_updated_files/backend/* backend/
cp -r step61_updated_files/frontend/* frontend/
```

## Backend Commands

```bash
cd /u01/nix-life-os/backend
php artisan optimize:clear
php artisan migrate
php artisan route:list | grep -i productivity
```

Expected route:

```text
GET|HEAD api/v1/productivity/dashboard App\Http\Controllers\Api\V1\ProductivityDashboardController@summary
```

## Frontend Commands

```bash
cd /u01/nix-life-os/frontend
npm run build
```

## CURL Tests

Set token:

```bash
TOKEN="PASTE_TOKEN_HERE"
```

### 1. Productivity dashboard summary

```bash
curl -s "http://127.0.0.1:8000/api/v1/productivity/dashboard" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

Expected JSON:

```json
{
  "success": true,
  "message": "Productivity dashboard summary loaded successfully.",
  "data": {
    "period": {
      "date": "YYYY-MM-DD",
      "week_start": "YYYY-MM-DD",
      "week_end": "YYYY-MM-DD"
    },
    "summary": {
      "daily_progress_percentage": 0,
      "total_open_items": 0,
      "total_completed_today": 0,
      "has_data": false,
      "empty_state": true
    },
    "tasks": {},
    "habits": {},
    "goals": {},
    "calendar": {},
    "charts": {}
  }
}
```

### 2. Unauthorized test

```bash
curl -s -i "http://127.0.0.1:8000/api/v1/productivity/dashboard" \
  -H "Accept: application/json"
```

Expected: `401 Unauthorized`.

## SQL Checks

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'productivity_tasks',
    'productivity_habits',
    'productivity_goals',
    'productivity_calendar_events'
  )
ORDER BY table_name;
"
```

Expected tables:

```text
productivity_calendar_events
productivity_goals
productivity_habits
productivity_tasks
```

Count data:

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT 'productivity_tasks' AS table_name, COUNT(*) FROM productivity_tasks
UNION ALL
SELECT 'productivity_habits', COUNT(*) FROM productivity_habits
UNION ALL
SELECT 'productivity_goals', COUNT(*) FROM productivity_goals
UNION ALL
SELECT 'productivity_calendar_events', COUNT(*) FROM productivity_calendar_events;
"
```

## Vue Browser Checks

Open:

```text
http://127.0.0.1/productivity/dashboard
```

Verify:

- Productivity sidebar link exists.
- Route opens without 404.
- Loading state appears before API response.
- Empty state appears when all four productivity tables are empty.
- Error state appears if token is invalid or backend is down.
- KPI cards render tasks, habits, goals, and calendar summaries.
- Charts render tasks by status, goals by status, habit completion last 7 days, and calendar next 7 days.
- Refresh button reloads the dashboard.
- Browser console has no Vue errors.

## Final Checklist

| Check | Expected Result | Status |
|---|---|---|
| API route exists | `/api/v1/productivity/dashboard` visible in route list | Pending |
| Controller loads | Returns success JSON | Pending |
| Auth protection | No token returns 401 | Pending |
| Migrations run | Four productivity tables created | Pending |
| Empty state | Displays when no productivity data exists | Pending |
| Loading state | Displays while API request is running | Pending |
| Error state | Displays when API fails | Pending |
| KPI cards | Tasks, habits, goals, calendar cards visible | Pending |
| Charts | Four dashboard chart blocks visible | Pending |
| Daily progress | Percentage ring visible | Pending |
| Sidebar | Productivity Dashboard link visible | Pending |
| Frontend build | `npm run build` passes | Pending |
| Laravel logs | No backend errors | Pending |
| Browser console | No frontend errors | Pending |
