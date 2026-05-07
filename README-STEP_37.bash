🔹 STEP 37 — Steps Tracking Page Testing
Health Module — Steps Tracking QA Guide
You are testing the Nix Life OS Health Steps Tracking page as a Senior Full-Stack QA Engineer.
Main goals:


Confirm the frontend route opens correctly.


Confirm the API endpoint works.


Confirm step logs load from PostgreSQL.


Confirm create, edit, delete actions work.


Confirm weekly/monthly totals are calculated correctly.


Confirm goal progress works.


Confirm empty data does not break charts.


Confirm authorization is required.



1. Confirm Containers Are Running
From project root:
cd /u01/nix-life-osdocker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Expected containers should include something like:
nixlifeos-backendnixlifeos-backend-nginxnixlifeos-frontendnixlifeos-postgres
If backend is down:
docker restart nixlifeos-backend nixlifeos-backend-nginx
Clear Laravel cache:
docker exec nixlifeos-backend php artisan optimize:cleardocker exec nixlifeos-backend php artisan route:cleardocker exec nixlifeos-backend php artisan config:clear

2. Get Authorization Token
Login:
curl -i -X POST "http://127.0.0.1:8000/api/v1/auth/login" \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}'
Expected response:
{  "success": true,  "message": "Login successful.",  "data": {    "user": {      "id": "USER_ID",      "name": "Nix",      "email": "nix@example.com"    },    "token": "TOKEN_HERE"  }}
Save token:
export TOKEN="PASTE_TOKEN_HERE"
Test token:
curl -i "http://127.0.0.1:8000/api/v1/auth/me" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "data": {    "user": {      "email": "nix@example.com"    }  }}

3. Check Laravel Route Registration
Inside backend:
docker exec nixlifeos-backend php artisan route:list | grep -i "step"
Expected routes may look like:
GET|HEAD   api/v1/health/stepsPOST       api/v1/health/stepsGET|HEAD   api/v1/health/steps/{id}PUT|PATCH  api/v1/health/steps/{id}DELETE     api/v1/health/steps/{id}GET|HEAD   api/v1/health/steps/summary
If nothing appears, check API routes:
docker exec nixlifeos-backend grep -R "health/steps\|steps" -n routes app/Http/Controllers
Common expected route file:
backend/routes/api.php

4. Test Unauthorized Access
Run API without token:
curl -i "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json"
Expected:
HTTP/1.1 401 Unauthorized
Expected JSON:
{  "message": "Unauthenticated."}
This confirms that the endpoint requires Bearer Token authorization.

5. Test GET Step Logs API
curl -i "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected successful response:
{  "success": true,  "message": "Step logs loaded successfully.",  "data": [    {      "id": "STEP_LOG_ID",      "user_id": "USER_ID",      "steps": 8500,      "goal": 10000,      "logged_at": "2026-05-07",      "notes": "Morning and evening walk",      "created_at": "2026-05-07T10:00:00.000000Z",      "updated_at": "2026-05-07T10:00:00.000000Z"    }  ]}
If the table is empty, expected:
{  "success": true,  "message": "Step logs loaded successfully.",  "data": []}
The frontend should show an empty state, not crash.

6. Create Step Log
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "steps": 8500,  "goal": 10000,  "logged_at": "2026-05-07",  "notes": "Daily steps test log"}'
Expected:
HTTP/1.1 201 Created
Expected JSON:
{  "success": true,  "message": "Step log created successfully.",  "data": {    "id": "STEP_LOG_ID",    "steps": 8500,    "goal": 10000,    "logged_at": "2026-05-07",    "notes": "Daily steps test log"  }}
Save the created ID:
export STEP_ID="PASTE_CREATED_STEP_ID"

7. Validate Created Step Log in PostgreSQL
Enter PostgreSQL container:
docker exec -it nixlifeos-postgres psql -U postgres -d nixlifeos
Check possible health tables:
\dt *health*\dt *step*
Expected table may be one of:
health_stepshealth_step_logsstep_logs
Check records:
SELECT     id,    user_id,    steps,    goal,    logged_at,    notes,    created_at,    updated_atFROM health_stepsORDER BY logged_at DESCLIMIT 20;
If your table name is different, use the actual table name from \dt.
Expected:
steps = 8500goal = 10000logged_at = 2026-05-07notes = Daily steps test log
Exit:
\q

8. Edit Step Log
curl -i -X PUT "http://127.0.0.1:8000/api/v1/health/steps/$STEP_ID" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "steps": 9200,  "goal": 10000,  "logged_at": "2026-05-07",  "notes": "Updated daily steps test log"}'
Expected:
{  "success": true,  "message": "Step log updated successfully.",  "data": {    "id": "STEP_LOG_ID",    "steps": 9200,    "goal": 10000,    "logged_at": "2026-05-07",    "notes": "Updated daily steps test log"  }}
Validate in DB:
docker exec -it nixlifeos-postgres psql -U postgres -d nixlifeos
SELECT id, steps, goal, logged_at, notesFROM health_stepsWHERE id = 'STEP_LOG_ID';
Expected:
steps = 9200notes = Updated daily steps test log

9. Test Validation Errors
Invalid negative steps:
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "steps": -100,  "goal": 10000,  "logged_at": "2026-05-07"}'
Expected:
HTTP/1.1 422 Unprocessable Content
Expected JSON:
{  "message": "The steps field must be at least 0.",  "errors": {    "steps": [      "The steps field must be at least 0."    ]  }}
Missing date:
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "steps": 7000,  "goal": 10000}'
Expected:
{  "message": "The logged at field is required.",  "errors": {    "logged_at": [      "The logged at field is required."    ]  }}

10. Test Weekly Totals
Create multiple logs for the same week:
curl -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"steps":7000,"goal":10000,"logged_at":"2026-05-04","notes":"Monday"}'curl -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"steps":8000,"goal":10000,"logged_at":"2026-05-05","notes":"Tuesday"}'curl -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"steps":9200,"goal":10000,"logged_at":"2026-05-06","notes":"Wednesday"}'curl -X POST "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"steps":8500,"goal":10000,"logged_at":"2026-05-07","notes":"Thursday"}'
Expected weekly total:
7000 + 8000 + 9200 + 8500 = 32700
PostgreSQL validation:
SELECT     DATE_TRUNC('week', logged_at::date) AS week_start,    SUM(steps) AS weekly_steps,    AVG(steps) AS average_daily_steps,    SUM(goal) AS weekly_goalFROM health_stepsWHERE logged_at::date BETWEEN '2026-05-04' AND '2026-05-10'GROUP BY DATE_TRUNC('week', logged_at::date);
Expected:
weekly_steps = 32700weekly_goal = 40000
Goal progress:
32700 / 40000 * 100 = 81.75%

11. Test Monthly Totals
PostgreSQL:
SELECT     DATE_TRUNC('month', logged_at::date) AS month_start,    SUM(steps) AS monthly_steps,    AVG(steps) AS average_daily_steps,    SUM(goal) AS monthly_goal,    ROUND((SUM(steps)::numeric / NULLIF(SUM(goal), 0)) * 100, 2) AS goal_progress_percentageFROM health_stepsWHERE logged_at::date BETWEEN '2026-05-01' AND '2026-05-31'GROUP BY DATE_TRUNC('month', logged_at::date);
Expected example:
monthly_steps = total steps in May 2026monthly_goal = total goals in May 2026goal_progress_percentage = monthly_steps / monthly_goal * 100

12. Test Summary Endpoint, If Available
curl -i "http://127.0.0.1:8000/api/v1/health/steps/summary" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "message": "Steps summary loaded successfully.",  "data": {    "today_steps": 8500,    "today_goal": 10000,    "today_progress": 85,    "weekly_steps": 32700,    "weekly_goal": 40000,    "weekly_progress": 81.75,    "monthly_steps": 32700,    "monthly_goal": 40000,    "monthly_progress": 81.75,    "average_daily_steps": 8175  }}
If this endpoint does not exist, expected route error:
HTTP/1.1 404 Not Found
Fix by adding summary route and controller method.

13. Delete Step Log
curl -i -X DELETE "http://127.0.0.1:8000/api/v1/health/steps/$STEP_ID" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "message": "Step log deleted successfully."}
Validate in DB:
SELECT id, steps, logged_atFROM health_stepsWHERE id = 'STEP_LOG_ID';
Expected:
0 rows

14. Frontend Route Check
Open browser:
http://localhost/health/steps
Or if using Vite dev server:
http://localhost:5173/health/steps
Expected:
The page should open with:
Steps TrackingDaily StepsWeekly ProgressMonthly ProgressAdd Step LogSteps chartStep logs table
Check Vue router:
grep -R "health/steps\|HealthSteps" -n /u01/nix-life-os/frontend/src
Expected route example:
{  path: "/health/steps",  name: "health-steps",  component: () => import("@/views/health/HealthStepsView.vue"),  meta: {    requiresAuth: true  }}

15. Vue Component Checks
Check file:
ls -lah /u01/nix-life-os/frontend/src/views/health/
Expected:
HealthStepsView.vue
Search API usage:
grep -n "health/steps\|steps" /u01/nix-life-os/frontend/src/views/health/HealthStepsView.vue
The component should not use static data like:
const steps = [  { date: "Mon", steps: 5000 },  { date: "Tue", steps: 8000 }]
It should fetch from backend:
const response = await api.get("/health/steps")
or:
const response = await axios.get("/api/v1/health/steps")
Check that token is included globally in Axios:
grep -R "Authorization\|Bearer\|axios" -n /u01/nix-life-os/frontend/src
Expected Axios interceptor:
api.interceptors.request.use((config) => {  const token = localStorage.getItem("token")  if (token) {    config.headers.Authorization = `Bearer ${token}`  }  return config})

16. Browser UI Checks
Open DevTools:
F12 → Console
Expected:
No Vue warningsNo undefined property errorsNo chart rendering errorsNo 401 errors when logged in
Open Network tab and refresh the page.
Expected API call:
GET /api/v1/health/stepsStatus: 200
When creating a step log:
POST /api/v1/health/stepsStatus: 201
When editing:
PUT /api/v1/health/steps/{id}Status: 200
When deleting:
DELETE /api/v1/health/steps/{id}Status: 200

17. Empty Data Test
Temporarily remove test data for your user only.
First get user ID:
SELECT id, name, emailFROM usersWHERE email = 'nix@example.com';
Then backup rows:
CREATE TABLE IF NOT EXISTS health_steps_backup ASSELECT *FROM health_stepsWHERE user_id = 'USER_ID';
Delete user rows:
DELETE FROM health_stepsWHERE user_id = 'USER_ID';
Refresh frontend.
Expected UI behavior:
No crashNo blank white screenNo chart errorDisplays message: No step logs foundAdd Step Log button still visibleTotals show 0Goal progress shows 0%
Restore data:
INSERT INTO health_stepsSELECT *FROM health_steps_backupWHERE user_id = 'USER_ID';

18. Common Backend Errors and Fixes
Error 1 — 401 Unauthorized
Cause:
Missing token or expired token.
Fix:
export TOKEN="NEW_LOGIN_TOKEN"
Then retry:
curl -i "http://127.0.0.1:8000/api/v1/health/steps" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"

Error 2 — 404 Not Found
Cause:
Route not registered.
Check:
docker exec nixlifeos-backend php artisan route:list | grep -i steps
Fix in routes/api.php:
Route::middleware('auth:sanctum')->prefix('v1/health')->group(function () {    Route::apiResource('steps', HealthStepController::class);    Route::get('steps-summary', [HealthStepController::class, 'summary']);});
Then clear routes:
docker exec nixlifeos-backend php artisan route:cleardocker exec nixlifeos-backend php artisan optimize:clear

Error 3 — 422 Validation Error
Cause:
Invalid request body.
Common examples:
steps is missingsteps is negativegoal is missinglogged_at is missinglogged_at is invalid date
Fix validation in controller/form request:
$request->validate([    'steps' => ['required', 'integer', 'min:0'],    'goal' => ['nullable', 'integer', 'min:1'],    'logged_at' => ['required', 'date'],    'notes' => ['nullable', 'string', 'max:500'],]);

Error 4 — 500 Internal Server Error
Check logs:
docker exec nixlifeos-backend tail -n 100 storage/logs/laravel.log
Common causes:
Table does not existColumn name mismatchMass assignment errorInvalid date castWrong user_id type
Fix model fillable:
protected $fillable = [    'user_id',    'steps',    'goal',    'logged_at',    'notes',];
Fix casts:
protected $casts = [    'steps' => 'integer',    'goal' => 'integer',    'logged_at' => 'date',];

Error 5 — Table Does Not Exist
Check migrations:
docker exec nixlifeos-backend php artisan migrate:status | grep -i step
Run migrations:
docker exec nixlifeos-backend php artisan migrate
If table is missing, create migration:
docker exec nixlifeos-backend php artisan make:migration create_health_steps_table
Expected schema:
Schema::create('health_steps', function (Blueprint $table) {    $table->uuid('id')->primary();    $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();    $table->integer('steps')->default(0);    $table->integer('goal')->default(10000);    $table->date('logged_at');    $table->text('notes')->nullable();    $table->timestamps();    $table->unique(['user_id', 'logged_at']);});

Error 6 — Duplicate Log for Same Date
Cause:
The table has unique constraint on user_id + logged_at.
Expected error:
{  "message": "Step log already exists for this date."}
Fix options:
Either update the existing record instead of creating duplicate:
HealthStep::updateOrCreate(    [        'user_id' => auth()->id(),        'logged_at' => $request->logged_at,    ],    [        'steps' => $request->steps,        'goal' => $request->goal ?? 10000,        'notes' => $request->notes,    ]);
Or show frontend error:
A step log already exists for this date. Please edit the existing log.

19. Final Pass/Fail Checklist
Test ItemExpected ResultStatusSteps route opens/health/steps opens successfullyPass / FailSidebar link worksOpens Steps Tracking pagePass / FailGET API works/api/v1/health/steps returns 200Pass / FailToken requiredNo token returns 401Pass / FailDaily steps displayCorrect steps from DB appear on screenPass / FailCreate step logPOST returns 201 and row appears in DBPass / FailEdit step logPUT returns 200 and DB row updatesPass / FailDelete step logDELETE returns 200 and DB row removedPass / FailWeekly totalSum is correct for current weekPass / FailMonthly totalSum is correct for current monthPass / FailGoal progressPercentage is calculated correctlyPass / FailEmpty dataUI does not crashPass / FailChartsEmpty and populated chart states workPass / FailConsoleNo Vue errorsPass / FailLaravel logsNo backend errorsPass / Fail

STEP 37 Final Result Format
Use this when reporting the result:
🔹 STEP 37 — Steps Tracking Page TestingStatus: PASSED / FAILED / PARTIALLY PASSEDValidated:✅ Route opens correctly✅ Sidebar navigation works✅ API endpoint /api/v1/health/steps works✅ Authorization token is required✅ Step logs load from PostgreSQL✅ Create step log works✅ Edit step log works✅ Delete step log works✅ Weekly total calculation verified✅ Monthly total calculation verified✅ Goal progress calculation verified✅ Empty data does not break charts✅ Browser console has no Vue errors✅ Laravel logs have no backend errorsIssues Found:- None / List issues hereFinal Notes:The Steps Tracking page is ready for the next health module testing step.