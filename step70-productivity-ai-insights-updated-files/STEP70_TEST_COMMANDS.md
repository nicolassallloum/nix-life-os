# STEP 70 — Productivity AI Insights Test Commands

## 1. Apply updated files

```bash
cd /u01/nix-life-os

tar -xzf step70-productivity-ai-insights-updated-files.tar.gz
cd step70-productivity-ai-insights-updated-files
chmod +x apply-step70-productivity-ai-insights-updates.sh
./apply-step70-productivity-ai-insights-updates.sh /u01/nix-life-os
```

## 2. Clear Laravel cache

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan optimize:clear"
```

## 3. Check route

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan route:list | grep -i 'productivity/ai-insights'"
```

Expected:

```text
GET|HEAD api/v1/productivity/ai-insights
```

## 4. Login and set token

```bash
TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@nixlifeos.com",
    "password": "password"
  }' | jq -r '.data.token')

echo $TOKEN
```

## 5. Test Productivity AI Insights API

```bash
curl -s -X GET "http://127.0.0.1:8000/api/v1/productivity/ai-insights" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

Expected top-level JSON:

```json
{
  "success": true,
  "message": "Productivity AI insights generated successfully.",
  "data": {
    "productivity_score": 0,
    "score_label": "No Data",
    "weekly_summary": {},
    "task_priority_recommendations": [],
    "habit_consistency_insights": [],
    "goal_progress_recommendations": [],
    "calendar_overload_warnings": [],
    "recommendations": [],
    "has_data": false
  }
}
```

The exact score depends on your productivity data.

## 6. Unauthorized test

```bash
curl -s -X GET "http://127.0.0.1:8000/api/v1/productivity/ai-insights" \
  -H "Accept: application/json" | jq .
```

Expected:

```json
{
  "message": "Unauthenticated."
}
```

## 7. SQL checks

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name ILIKE 'productivity_%'
ORDER BY table_name;
"
```

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT 'productivity_tasks' AS table_name, COUNT(*) AS total FROM productivity_tasks
UNION ALL
SELECT 'productivity_habits', COUNT(*) FROM productivity_habits
UNION ALL
SELECT 'productivity_goals', COUNT(*) FROM productivity_goals
UNION ALL
SELECT 'productivity_calendar_events', COUNT(*) FROM productivity_calendar_events;
"
```

## 8. Frontend checks

```bash
cd /u01/nix-life-os/frontend
npm run build
```

Open:

```text
http://127.0.0.1/productivity/ai-insights
```

Verify:

- Productivity Score card appears.
- Weekly Summary appears.
- Task Priority Recommendations appears.
- Habit Consistency Insights appears.
- Goal Progress Recommendations appears.
- Calendar Overload Warnings appears.
- Empty state works when no data exists.
- Browser console has no route/component/API errors.
