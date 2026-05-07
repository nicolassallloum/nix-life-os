🔹 STEP 38 — Weight Tracking Page Testing
Nix Life OS — Health Module
You are currently seeing:
Server ErrorLatest Weight: 0 kgTarget Weight: 60 kgDifference: -60 kgTotal Records: 0No weight logs found.
This means the frontend route is opening, but the backend API for weight logs is failing or returning an error.

1. Verify Frontend Route Opens Correctly
Open the page in browser:
http://127.0.0.1/health/weight
Expected:
Weight Tracking page opens.Sidebar highlights Weight Tracking.No Vue console errors.No infinite loading.
Browser checks:
F12 → Console
Expected:
No red Vue errors.No failed JavaScript imports.No undefined variable errors.
Also check Network tab:
F12 → Network → Fetch/XHRRefresh page
Look for requests like:
/api/v1/health/weight/api/v1/health/weights/api/v1/health/weight-logs
The failed request will show the real endpoint name.

2. Check Laravel Routes
Inside backend container or backend folder:
cd /u01/nix-life-os/backenddocker exec -it nixlifeos-backend php artisan route:list | grep -i weight
Expected routes should look similar to:
GET|HEAD   api/v1/health/weightPOST       api/v1/health/weightPUT|PATCH  api/v1/health/weight/{id}DELETE     api/v1/health/weight/{id}
Or:
GET|HEAD   api/v1/health/weightsPOST       api/v1/health/weightsPUT|PATCH  api/v1/health/weights/{id}DELETE     api/v1/health/weights/{id}
If nothing appears, the route is missing.
Check API routes file:
grep -R "weight" -n routes app/Http/Controllers

3. Clear Laravel Cache
Before testing APIs:
cd /u01/nix-life-os/backenddocker exec nixlifeos-backend php artisan optimize:cleardocker exec nixlifeos-backend php artisan route:cleardocker exec nixlifeos-backend php artisan config:cleardocker exec nixlifeos-backend php artisan cache:clear
Restart containers:
docker restart nixlifeos-backend nixlifeos-backend-nginx

4. Get Bearer Token
Login:
curl -i -X POST "http://127.0.0.1:8000/api/v1/auth/login" \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}'
Expected response:
{  "success": true,  "message": "Login successful.",  "data": {    "token": "YOUR_TOKEN_HERE",    "user": {      "id": "...",      "name": "...",      "email": "nix@example.com"    }  }}
Export token:
export TOKEN="PASTE_TOKEN_HERE"
Verify token:
curl -i "http://127.0.0.1:8000/api/v1/auth/me" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "data": {    "user": {      "email": "nix@example.com"    }  }}

5. Test Weight Log API — GET
Try the most likely endpoint first:
curl -i "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
If that fails, try:
curl -i "http://127.0.0.1:8000/api/v1/health/weight" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected success:
{  "success": true,  "message": "Weight logs loaded successfully.",  "data": {    "logs": [],    "summary": {      "latest_weight": 0,      "target_weight": 60,      "difference": -60,      "total_records": 0    }  }}
Or a simpler format:
{  "success": true,  "data": []}
If you get 500 Server Error, check Laravel logs:
docker exec -it nixlifeos-backend tail -n 100 storage/logs/laravel.log

6. Test Add Weight Log — POST
Use the endpoint that exists in your route:list.
Example using /api/v1/health/weights:
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "weight_kg": 50,  "bmi": 20.8,  "log_date": "2026-05-07",  "notes": "Initial weight test log"}'
If your backend uses date instead of log_date, test this:
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "date": "2026-05-07",  "weight_kg": 50,  "bmi": 20.8,  "notes": "Initial weight test log"}'
Expected response:
{  "success": true,  "message": "Weight log created successfully.",  "data": {    "id": "REAL_WEIGHT_ID",    "weight_kg": 50,    "bmi": 20.8,    "log_date": "2026-05-07",    "notes": "Initial weight test log"  }}
Save the ID:
export WEIGHT_ID="PASTE_REAL_WEIGHT_ID"

7. Verify Current Weight Displays
Refresh the browser page.
Expected cards:
Latest Weight: 50 kgTarget Weight: 60 kgDifference: -10 kgTotal Records: 1
If page still shows 0 kg, then frontend is not reading the API response correctly.
Check in browser:
F12 → Network → weight API → Response
Compare the response field names with the Vue file.
Common mismatch examples:
Backend returns: weight_kgFrontend reads: weightBackend returns: log_dateFrontend reads: dateBackend returns: data.logsFrontend reads: data.data

8. Test Weight History
Run:
curl -i "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "data": {    "logs": [      {        "id": "REAL_WEIGHT_ID",        "weight_kg": 50,        "bmi": 20.8,        "log_date": "2026-05-07",        "notes": "Initial weight test log"      }    ]  }}
Frontend expected:
Recent Weight Logs section displays the new record.Date displays correctly.Weight displays correctly.BMI displays correctly if available.Notes display correctly.Edit/Delete actions are visible if implemented.

9. Test Edit Weight Log — PUT/PATCH
Try PUT:
curl -i -X PUT "http://127.0.0.1:8000/api/v1/health/weights/$WEIGHT_ID" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "weight_kg": 49.5,  "bmi": 20.6,  "log_date": "2026-05-07",  "notes": "Updated weight test log"}'
If PUT is not supported, try PATCH:
curl -i -X PATCH "http://127.0.0.1:8000/api/v1/health/weights/$WEIGHT_ID" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "weight_kg": 49.5,  "bmi": 20.6,  "log_date": "2026-05-07",  "notes": "Updated weight test log"}'
Expected:
{  "success": true,  "message": "Weight log updated successfully.",  "data": {    "id": "REAL_WEIGHT_ID",    "weight_kg": 49.5,    "bmi": 20.6,    "log_date": "2026-05-07",    "notes": "Updated weight test log"  }}
Frontend check:
Click Edit.Update weight.Save.Record changes without full page error.Summary cards refresh.Chart refreshes.

10. Test Delete Weight Log — DELETE
curl -i -X DELETE "http://127.0.0.1:8000/api/v1/health/weights/$WEIGHT_ID" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "message": "Weight log deleted successfully."}
Frontend check:
Record disappears from Recent Weight Logs.Total Records decreases.Empty state appears when no records remain.No Vue error appears.

11. SQL Checks
Connect to PostgreSQL:
docker exec -it nixlifeos-postgres psql -U postgres -d nixlifeos
If your DB/user is different, check .env:
cat /u01/nix-life-os/backend/.env | grep DB_
Find weight table:
SELECT table_nameFROM information_schema.tablesWHERE table_schema = 'public'AND table_name ILIKE '%weight%';
Expected possible table names:
health_weightsweight_logshealth_weight_logs
Check columns:
SELECT column_name, data_type, is_nullableFROM information_schema.columnsWHERE table_name = 'health_weight_logs'ORDER BY ordinal_position;
Replace table name if yours is different.
Check records:
SELECT *FROM health_weight_logsORDER BY created_at DESCLIMIT 10;
Check current user records:
SELECT     id,    user_id,    weight_kg,    bmi,    log_date,    notes,    created_atFROM health_weight_logsORDER BY log_date DESC;
Check latest weight:
SELECT     weight_kg AS latest_weight,    log_dateFROM health_weight_logsORDER BY log_date DESC, created_at DESCLIMIT 1;
Check total records:
SELECT COUNT(*) AS total_recordsFROM health_weight_logs;

12. BMI Calculation Check
BMI formula:
BMI = weight_kg / (height_m * height_m)
Your known height from previous project data:
155 cm = 1.55 m
Example for 50 kg:
BMI = 50 / (1.55 * 1.55)BMI = 20.81
SQL check:
SELECT     weight_kg,    ROUND((weight_kg / (1.55 * 1.55))::numeric, 2) AS calculated_bmi,    bmi AS saved_bmiFROM health_weight_logsORDER BY created_at DESCLIMIT 10;
Expected:
calculated_bmi and saved_bmi should be close.
If BMI is manually entered, frontend should either:
Accept typed BMI.
Or calculate automatically from weight and profile height.

13. Weight Trend Chart Test
Add several records:
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"log_date":"2026-05-01","weight_kg":51,"bmi":21.2,"notes":"Chart test 1"}'curl -i -X POST "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"log_date":"2026-05-03","weight_kg":50.5,"bmi":21.0,"notes":"Chart test 2"}'curl -i -X POST "http://127.0.0.1:8000/api/v1/health/weights" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{"log_date":"2026-05-07","weight_kg":50,"bmi":20.8,"notes":"Chart test 3"}'
Expected frontend:
Chart appears.X-axis shows dates.Y-axis shows weight values.Line moves from 51 → 50.5 → 50.Chart does not crash with 1 record or empty records.
If chart is blank, check:
F12 → Console
Common chart errors:
Cannot read properties of undefinedInvalid prop: expected ArrayChart library not importedData format mismatch

14. Empty Weight Logs Test
Delete all test records or use SQL in test environment only:
DELETE FROM health_weight_logs;
Then refresh page.
Expected:
Latest Weight: 0 kgTotal Records: 0Recent Weight Logs: No weight logs found.Chart area should show empty state or no chart.No server error.No frontend crash.

15. Laravel Controller Checks
Search controller:
grep -R "class.*Weight" -n app/Http/Controllers
Open file:
grep -R "weight" -n app/Http/Controllers/Api
Expected controller methods:
index()store()show()update()destroy()summary()
Check model:
grep -R "class.*Weight" -n app/Models
Expected model fillable fields:
protected $fillable = [    'user_id',    'log_date',    'weight_kg',    'bmi',    'notes',];
Check migration:
ls database/migrations | grep -i weight
Expected columns:
$table->uuid('id')->primary();$table->foreignUuid('user_id')->constrained()->cascadeOnDelete();$table->date('log_date');$table->decimal('weight_kg', 5, 2);$table->decimal('bmi', 5, 2)->nullable();$table->text('notes')->nullable();$table->timestamps();

16. Common Errors and Fixes
Error 1: Server Error on page
Check logs:
docker exec -it nixlifeos-backend tail -n 150 storage/logs/laravel.log
Common causes:
Table does not exist.Column name mismatch.Auth user is null.Controller returns wrong response.Route points to missing method.Frontend endpoint is wrong.

Error 2: 401 Unauthorized
Fix:
export TOKEN="VALID_LOGIN_TOKEN"
Then retest:
curl -i "http://127.0.0.1:8000/api/v1/auth/me" \-H "Authorization: Bearer $TOKEN" \-H "Accept: application/json"

Error 3: 404 Not Found
Check route:
docker exec nixlifeos-backend php artisan route:list | grep -i weight
Fix frontend endpoint to match backend route.
Example:
const API_URL = '/api/v1/health/weights'

Error 4: 422 Validation Error
The backend expects different field names.
Check response:
{  "message": "The weight kg field is required.",  "errors": {    "weight_kg": [      "The weight kg field is required."    ]  }}
Fix request body or frontend payload.

Error 5: Data saves but does not show
Likely frontend response mapping issue.
Check if backend returns:
{  "data": {    "logs": []  }}
But frontend expects:
response.data.data
Fix to:
logs.value = response.data.data.logs ?? []

17. Final Frontend Test Checklist
TestExpected ResultStatusRoute opens/health/weight loads successfully☐Sidebar activeWeight Tracking highlighted☐API loadsGET weight logs returns 200☐Current weightLatest weight card updates☐Target weightTarget card displays configured target☐DifferenceLatest weight - target weight calculated correctly☐Total recordsCount matches database☐Add weightNew log saves successfully☐Edit weightExisting log updates successfully☐Delete weightLog deletes successfully☐HistoryRecent logs display from backend☐ChartTrend chart renders correctly☐Empty stateNo records message displays☐ValidationRequired fields show clear messages☐ConsoleNo Vue errors☐NetworkNo failed API requests☐

18. Final Backend Validation Checklist
TestCommandExpectedRoute existsphp artisan route:list | grep -i weightWeight routes listedController existsgrep -R "Weight" app/Http/ControllersController foundModel existsgrep -R "Weight" app/ModelsModel foundMigration existsls database/migrations | grep -i weightMigration foundTable existsSQL table checkWeight table foundGET worksCURL GET200 OKPOST worksCURL POST201/200 OKPUT/PATCH worksCURL update200 OKDELETE worksCURL delete200 OKLogs cleantail laravel.logNo new errors

Immediate Next Step
Because your screenshot shows Server Error, start with these two commands:
docker exec -it nixlifeos-backend php artisan route:list | grep -i weight
Then:
docker exec -it nixlifeos-backend tail -n 150 storage/logs/laravel.log
Send me the output, and I will identify the exact backend issue.