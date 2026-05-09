🔹 STEP 40 — Hydration Tracking Page Testing

Nix Life OS — Health Module QA Guide

You are currently seeing:

Hydration Tracking
Server Error
Today Intake: 0 ml
Daily Goal: 2,000 ml
Progress: 0%
Total Records: 0

This means the Vue route is opening, but the hydration API request is failing or returning an unexpected response.

1. Verify Frontend Route Opens Correctly

Open this URL in the browser:

http://localhost/health/hydration

or if your frontend is running on Vite:

http://127.0.0.1:5173/health/hydration

Expected result:

Hydration Tracking page opens
Sidebar highlights Hydration Tracking
No blank screen
No Vue router error

Check browser console:

F12 → Console

Expected:

No red Vue errors
No failed imports
No undefined property errors
2. Verify Vue Router Registration

Open:

cd /u01/nix-life-os/frontend

grep -R "hydration" -n src/router src/views src/components

Expected route should look similar to:

{
  path: "/health/hydration",
  name: "health-hydration",
  component: () => import("@/views/health/HydrationTrackingView.vue"),
}

Also verify sidebar link:

grep -R "Hydration Tracking" -n src
grep -R "/health/hydration" -n src

Expected:

Sidebar link points to /health/hydration
3. Verify Backend Route Exists

Run this inside backend:

cd /u01/nix-life-os/backend

php artisan route:list | grep -i hydration

Expected routes should be similar to:

GET|HEAD  api/v1/health/hydration
POST      api/v1/health/hydration
GET|HEAD  api/v1/health/hydration/{id}
PUT|PATCH api/v1/health/hydration/{id}
DELETE    api/v1/health/hydration/{id}

If nothing appears, the hydration routes are missing.

Check API routes file:

grep -R "hydration" -n routes app/Http/Controllers

Expected files may include:

routes/api.php
app/Http/Controllers/Api/V1/Health/HydrationController.php
4. Verify Authentication Token

Login first and save token:

cd /u01/nix-life-os/backend

export TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "email": "admin@nixlifeos.com",
  "password": "password"
}' | jq -r '.data.token // .token')

echo $TOKEN

Expected:

A long Bearer token is printed

If token is empty, test your real user:

curl -i -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "email": "YOUR_EMAIL",
  "password": "YOUR_PASSWORD"
}'
5. Test Hydration API — GET Logs

Try the endpoint:

curl -i -X GET "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected successful response:

{
  "success": true,
  "message": "Hydration logs loaded successfully.",
  "data": [
    {
      "id": "019e...",
      "user_id": "019e...",
      "date": "2026-05-09",
      "water_ml": 500,
      "drink_type": "Water",
      "notes": "Morning water",
      "created_at": "2026-05-09T..."
    }
  ]
}

If no logs exist, expected response:

{
  "success": true,
  "message": "Hydration logs loaded successfully.",
  "data": []
}

If you get 500 Server Error, check Laravel logs:

docker logs nixlifeos-backend --tail=100

cd /u01/nix-life-os/backend
tail -n 100 storage/logs/laravel.log
6. Test Daily Summary Endpoint

Your page likely needs a summary endpoint for:

Today Intake
Daily Goal
Progress
Total Records

Test:

curl -i -X GET "http://127.0.0.1:8000/api/v1/health/hydration/summary" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Hydration summary loaded successfully.",
  "data": {
    "today_intake_ml": 0,
    "daily_goal_ml": 2000,
    "progress_percent": 0,
    "total_records": 0
  }
}

After adding water logs, expected example:

{
  "success": true,
  "message": "Hydration summary loaded successfully.",
  "data": {
    "today_intake_ml": 1500,
    "daily_goal_ml": 2000,
    "progress_percent": 75,
    "total_records": 3
  }
}
7. Test Add Hydration Log

Use today’s date:

curl -i -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 500,
  "drink_type": "Water",
  "notes": "Morning hydration test"
}'

Expected response:

{
  "success": true,
  "message": "Hydration log created successfully.",
  "data": {
    "id": "019e...",
    "date": "2026-05-09",
    "water_ml": 500,
    "drink_type": "Water",
    "notes": "Morning hydration test"
  }
}

Save the ID:

export HYDRATION_ID="PASTE_CREATED_ID_HERE"

Or extract automatically:

export HYDRATION_ID=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 750,
  "drink_type": "Water",
  "notes": "Auto ID test"
}' | jq -r '.data.id')

echo $HYDRATION_ID
8. Test Daily Total Calculation

Add multiple logs for the same date:

curl -s -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 500,
  "drink_type": "Water",
  "notes": "Test 1"
}' | jq

curl -s -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 700,
  "drink_type": "Water",
  "notes": "Test 2"
}' | jq

Now check summary:

curl -s -X GET "http://127.0.0.1:8000/api/v1/health/hydration/summary?date=2026-05-09" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq

Expected:

{
  "success": true,
  "data": {
    "today_intake_ml": 1200,
    "daily_goal_ml": 2000,
    "progress_percent": 60
  }
}

Calculation:

500 + 700 = 1200 ml
1200 / 2000 * 100 = 60%
9. Test Edit Hydration Log
curl -i -X PUT "http://127.0.0.1:8000/api/v1/health/hydration/$HYDRATION_ID" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 1000,
  "drink_type": "Water",
  "notes": "Updated hydration amount"
}'

Expected response:

{
  "success": true,
  "message": "Hydration log updated successfully.",
  "data": {
    "id": "019e...",
    "water_ml": 1000,
    "notes": "Updated hydration amount"
  }
}

Refresh the Hydration page.

Expected UI result:

Updated amount appears in Recent Hydration Logs
Daily total recalculates
Progress percentage updates
10. Test Delete Hydration Log
curl -i -X DELETE "http://127.0.0.1:8000/api/v1/health/hydration/$HYDRATION_ID" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Hydration log deleted successfully."
}

Refresh page.

Expected:

Deleted row removed from Recent Hydration Logs
Today Intake decreases
Progress decreases
Total Records decreases
11. Test Invalid Quantity Validation
Negative value
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": -500,
  "drink_type": "Water",
  "notes": "Invalid negative test"
}'

Expected:

{
  "message": "The water ml field must be at least 1.",
  "errors": {
    "water_ml": [
      "The water ml field must be at least 1."
    ]
  }
}
Empty quantity
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "drink_type": "Water",
  "notes": "Missing water ml test"
}'

Expected:

{
  "message": "The water ml field is required.",
  "errors": {
    "water_ml": [
      "The water ml field is required."
    ]
  }
}
Too high value
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "date": "2026-05-09",
  "water_ml": 999999,
  "drink_type": "Water",
  "notes": "Invalid huge quantity"
}'

Expected validation should prevent unrealistic values, for example:

{
  "message": "The water ml field must not be greater than 10000.",
  "errors": {
    "water_ml": [
      "The water ml field must not be greater than 10000."
    ]
  }
}

Recommended backend validation:

'water_ml' => ['required', 'integer', 'min:1', 'max:10000'],
'date' => ['required', 'date'],
'drink_type' => ['nullable', 'string', 'max:50'],
'notes' => ['nullable', 'string', 'max:500'],
12. SQL Validation Checks

Connect to PostgreSQL:

docker exec -it nixlifeos-postgres psql -U postgres -d nixlifeos

If your DB/user names are different, use:

docker ps
docker exec -it nixlifeos-postgres psql -U YOUR_DB_USER -d YOUR_DB_NAME

Check hydration table exists:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name ILIKE '%hydration%';

Expected table:

health_hydration_logs

or similar.

Check columns:

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'health_hydration_logs'
ORDER BY ordinal_position;

Expected columns:

id
user_id
date
water_ml
drink_type
notes
created_at
updated_at

Check latest logs:

SELECT 
    id,
    user_id,
    date,
    water_ml,
    drink_type,
    notes,
    created_at
FROM health_hydration_logs
ORDER BY created_at DESC
LIMIT 20;

Check today total:

SELECT 
    date,
    SUM(water_ml) AS total_water_ml,
    COUNT(*) AS total_records
FROM health_hydration_logs
WHERE date = CURRENT_DATE
GROUP BY date;

Check specific date:

SELECT 
    date,
    SUM(water_ml) AS total_water_ml,
    COUNT(*) AS total_records
FROM health_hydration_logs
WHERE date = '2026-05-09'
GROUP BY date;

Expected example:

date        | total_water_ml | total_records
2026-05-09  | 1200           | 2

Check invalid records:

SELECT *
FROM health_hydration_logs
WHERE water_ml <= 0
   OR water_ml IS NULL;

Expected:

0 rows
13. Vue Component Checks

Open the hydration file:

cd /u01/nix-life-os/frontend

find src -iname "*Hydration*"

Expected:

src/views/health/HydrationTrackingView.vue

Open it:

nano src/views/health/HydrationTrackingView.vue

Check that the page has these functions:

fetchHydrationLogs()
fetchHydrationSummary()
saveHydration()
editHydration()
deleteHydration()
resetForm()

Check API paths:

/api/v1/health/hydration
/api/v1/health/hydration/summary

Check token header:

Authorization: `Bearer ${token}`

Check loading/error state:

loading.value = true
error.value = null

Check empty logs handling:

<tr v-if="hydrationLogs.length === 0">
  <td colspan="6">No hydration logs found.</td>
</tr>

Check calculations are not static:

todayIntake.value
dailyGoal.value
progressPercent.value
totalRecords.value

They should come from backend API or be calculated from logs.

14. Browser Network Test

In browser:

F12 → Network → Fetch/XHR
Refresh Hydration Tracking page

Look for requests:

/api/v1/health/hydration
/api/v1/health/hydration/summary

Expected:

Status 200 OK
Response JSON success true

If status is 401:

Token missing or expired
Login again
Check localStorage token name

If status is 404:

Backend route missing
Check api.php route registration

If status is 500:

Backend controller/model/database error
Check Laravel log

If status is 502:

Nginx cannot reach Laravel backend
Restart containers
15. Common Problems and Fixes
Problem 1: Page shows “Server Error”

Most likely causes:

API endpoint failed
Wrong endpoint path
Missing Authorization header
Backend controller error
Database table missing
Column name mismatch

Fix:

cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan route:list | grep -i hydration
tail -n 100 storage/logs/laravel.log

Restart containers:

cd /u01/nix-life-os

docker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend
Problem 2: Hydration logs do not display after saving

Check the API response format.

Vue may expect:

response.data.data

But backend may return:

response.data

Fix frontend mapping:

const payload = response.data

hydrationLogs.value = Array.isArray(payload.data)
  ? payload.data
  : []
Problem 3: Today Intake stays 0

Possible causes:

Summary endpoint not called
Date mismatch
Frontend date format is MM/DD/YYYY instead of YYYY-MM-DD
Backend filters by CURRENT_DATE but inserted date is different

Fix date format in Vue:

const today = new Date().toISOString().slice(0, 10)

Expected format:

2026-05-09

Not:

05/09/2026
Problem 4: Progress percentage is wrong

Correct formula:

progressPercent = Math.round((todayIntake / dailyGoal) * 100)

Example:

Today Intake = 1000 ml
Daily Goal = 2000 ml
Progress = 50%

Recommended protection:

progressPercent = dailyGoal > 0
  ? Math.min(100, Math.round((todayIntake / dailyGoal) * 100))
  : 0
Problem 5: Add Hydration does nothing

Check browser console and network.

Expected request:

POST /api/v1/health/hydration

Payload should be:

{
  "date": "2026-05-09",
  "water_ml": 500,
  "drink_type": "Water",
  "notes": "Optional"
}

Common frontend issue:

Frontend sends waterML but backend expects water_ml

Fix:

water_ml: form.value.water_ml
Problem 6: Edit/Delete buttons missing

Check if Recent Hydration Logs table has action buttons:

<button @click="editHydration(log)">Edit</button>
<button @click="deleteHydration(log.id)">Delete</button>

Expected:

Each hydration row has Edit and Delete actions
16. Laravel Controller Checks

Open controller:

cd /u01/nix-life-os/backend

find app/Http/Controllers -iname "*Hydration*"

Check methods:

index()
summary()
store()
show()
update()
destroy()

Expected route structure:

Route::middleware('auth:sanctum')->prefix('v1/health')->group(function () {
    Route::get('/hydration/summary', [HydrationController::class, 'summary']);
    Route::apiResource('/hydration', HydrationController::class);
});

Important: put /hydration/summary before apiResource.

Correct:

Route::get('/hydration/summary', [HydrationController::class, 'summary']);
Route::apiResource('/hydration', HydrationController::class);

Wrong:

Route::apiResource('/hydration', HydrationController::class);
Route::get('/hydration/summary', [HydrationController::class, 'summary']);

Because Laravel may treat summary as {hydration}.

17. Recommended API Response Standard

Use this format for all hydration APIs:

GET logs
{
  "success": true,
  "message": "Hydration logs loaded successfully.",
  "data": []
}
GET summary
{
  "success": true,
  "message": "Hydration summary loaded successfully.",
  "data": {
    "today_intake_ml": 0,
    "daily_goal_ml": 2000,
    "progress_percent": 0,
    "total_records": 0
  }
}
POST create
{
  "success": true,
  "message": "Hydration log created successfully.",
  "data": {
    "id": "uuid",
    "date": "2026-05-09",
    "water_ml": 500,
    "drink_type": "Water",
    "notes": "Test"
  }
}
PUT update
{
  "success": true,
  "message": "Hydration log updated successfully.",
  "data": {
    "id": "uuid",
    "date": "2026-05-09",
    "water_ml": 1000,
    "drink_type": "Water",
    "notes": "Updated"
  }
}
DELETE
{
  "success": true,
  "message": "Hydration log deleted successfully."
}
18. Final Pass/Fail Checklist
Test Item	Expected Result	Status
Hydration route opens	Page opens without blank screen	⬜
Sidebar link works	Hydration Tracking link active	⬜
GET hydration API works	Returns success: true	⬜
GET summary API works	Returns today intake, goal, progress	⬜
Today Intake displays correctly	Matches DB total	⬜
Daily Goal displays	Shows 2,000 ml or user goal	⬜
Progress displays correctly	Correct percentage calculation	⬜
Add hydration works	New row inserted in DB	⬜
Edit hydration works	Existing row updated	⬜
Delete hydration works	Row removed from DB	⬜
Recent logs display	Logs load dynamically from backend	⬜
Empty logs handled	Shows No hydration logs found	⬜
Invalid quantity blocked	Negative/empty values return 422	⬜
Browser console clean	No Vue errors	⬜
Laravel logs clean	No backend exception	⬜
Page refresh works	Data remains after refresh	⬜
19. Quick Diagnosis for Your Current Screen

Because your screen shows:

Server Error
Today Intake: 0 ml
Total Records: 0
No hydration logs found

Run these three commands first:

cd /u01/nix-life-os/backend

php artisan route:list | grep -i hydration
curl -i -X GET "http://127.0.0.1:8000/api/v1/health/hydration" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
tail -n 100 storage/logs/laravel.log

Most likely issue is one of these:

Hydration backend route missing
HydrationController error
hydration table missing
Vue endpoint path does not match Laravel route
Authorization token not being sent from frontend
summary route is placed after apiResource















nix@DESKTOP-0VMMAOM:/u01/nix-life-os/backend$ cd /u01/nix-life-os/backend

curl -i -X POST "http://127.0.0.1:8000/api/v1/auth/register" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "name": "Nix Admin",
  "email": "nix.admin@nixlifeos.com",
  "password": "password123",
  "password_confirmation": "password123"
}'