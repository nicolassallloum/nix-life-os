🔹 STEP 39 — Nutrition Tracking Page Testing
Nix Life OS Health Module
You are now testing the Nutrition Tracking page.
Current screen shows:
Nutrition TrackingNutrition tracking page is available.
This means the route exists, but the page still looks like a placeholder. We need to test both:


Backend Nutrition APIs


Frontend Nutrition Tracking UI



1. Go to Project Folder
cd /u01/nix-life-os/backend
Set your token:
export TOKEN="PASTE_YOUR_LOGIN_TOKEN_HERE"
Or login again:
curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}' | jq
Then copy the token and export it:
export TOKEN="eyJ..."

2. Check Laravel Nutrition Routes
Run:
php artisan route:list | grep -i nutrition
Expected routes should look similar to:
GET       api/v1/health/nutritionPOST      api/v1/health/nutritionGET       api/v1/health/nutrition/{id}PUT       api/v1/health/nutrition/{id}DELETE    api/v1/health/nutrition/{id}GET       api/v1/health/nutrition/summary
If no routes appear, check:
grep -R "nutrition" routes app/Http/Controllers -n

3. Test Nutrition List API
curl -i -X GET "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected response:
{  "success": true,  "message": "Nutrition logs loaded successfully.",  "data": []}
Or:
{  "success": true,  "data": [    {      "id": "019e...",      "meal_date": "2026-05-08",      "meal_type": "breakfast",      "food_name": "Boiled Egg",      "quantity": 1,      "calories": 78,      "protein": 6,      "sodium": 62,      "potassium": 63,      "phosphorus": 86    }  ]}

4. Test Add Meal Log
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "meal_date": "2026-05-08",  "meal_type": "breakfast",  "food_name": "Boiled Egg",  "quantity": 1,  "unit": "piece",  "calories": 78,  "protein": 6,  "sodium": 62,  "potassium": 63,  "phosphorus": 86,  "notes": "Kidney-friendly breakfast item"}'
Expected response:
{  "success": true,  "message": "Nutrition log created successfully.",  "data": {    "id": "019e...",    "meal_date": "2026-05-08",    "meal_type": "breakfast",    "food_name": "Boiled Egg",    "quantity": 1,    "unit": "piece",    "calories": 78,    "protein": 6,    "sodium": 62,    "potassium": 63,    "phosphorus": 86,    "notes": "Kidney-friendly breakfast item"  }}
Save the ID:
export NUTRITION_ID="PASTE_CREATED_ID_HERE"

5. Add More Meal Logs for Daily Totals
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "meal_date": "2026-05-08",  "meal_type": "lunch",  "food_name": "White Rice with Grilled Chicken",  "quantity": 1,  "unit": "plate",  "calories": 420,  "protein": 22,  "sodium": 180,  "potassium": 280,  "phosphorus": 190,  "notes": "Controlled portion"}'
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "meal_date": "2026-05-08",  "meal_type": "dinner",  "food_name": "Pasta with Olive Oil",  "quantity": 1,  "unit": "bowl",  "calories": 350,  "protein": 9,  "sodium": 120,  "potassium": 150,  "phosphorus": 110,  "notes": "Low sodium meal"}'

6. Test Daily Nutrition Summary API
curl -i -X GET "http://127.0.0.1:8000/api/v1/health/nutrition/summary?date=2026-05-08" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected response:
{  "success": true,  "message": "Nutrition summary loaded successfully.",  "data": {    "date": "2026-05-08",    "total_calories": 848,    "total_protein": 37,    "total_sodium": 362,    "total_potassium": 493,    "total_phosphorus": 386,    "limits": {      "calories": 1800,      "protein": 45,      "sodium": 2000,      "potassium": 2000,      "phosphorus": 800    },    "status": {      "calories": "within_limit",      "protein": "within_limit",      "sodium": "within_limit",      "potassium": "within_limit",      "phosphorus": "within_limit"    }  }}

7. Test Edit Meal Log
curl -i -X PUT "http://127.0.0.1:8000/api/v1/health/nutrition/$NUTRITION_ID" \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "meal_date": "2026-05-08",  "meal_type": "breakfast",  "food_name": "Boiled Egg",  "quantity": 2,  "unit": "pieces",  "calories": 156,  "protein": 12,  "sodium": 124,  "potassium": 126,  "phosphorus": 172,  "notes": "Updated quantity"}'
Expected response:
{  "success": true,  "message": "Nutrition log updated successfully."}
Verify list again:
curl -s -X GET "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq

8. Test Delete Meal Log
curl -i -X DELETE "http://127.0.0.1:8000/api/v1/health/nutrition/$NUTRITION_ID" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected response:
{  "success": true,  "message": "Nutrition log deleted successfully."}

9. PostgreSQL Validation Queries
Enter PostgreSQL container:
docker exec -it nixlifeos-postgres psql -U nixlifeos -d nixlifeos
Check nutrition tables:
\dt *nutrition*
Common expected tables:
health_nutrition_logsnutrition_logshealth_meal_logs
Check table structure:
\d health_nutrition_logs
Check saved logs:
SELECT     id,    user_id,    meal_date,    meal_type,    food_name,    quantity,    unit,    calories,    protein,    sodium,    potassium,    phosphorus,    notes,    created_at,    updated_atFROM health_nutrition_logsORDER BY meal_date DESC, created_at DESCLIMIT 20;
Check daily totals:
SELECT     meal_date,    SUM(calories) AS total_calories,    SUM(protein) AS total_protein,    SUM(sodium) AS total_sodium,    SUM(potassium) AS total_potassium,    SUM(phosphorus) AS total_phosphorusFROM health_nutrition_logsWHERE meal_date = '2026-05-08'GROUP BY meal_date;
Check meal type counts:
SELECT     meal_type,    COUNT(*) AS total_logs,    SUM(calories) AS caloriesFROM health_nutrition_logsGROUP BY meal_typeORDER BY meal_type;
Exit:
\q

10. Vue UI Checks
Open:
http://localhost/health/nutrition
or:
http://127.0.0.1/health/nutrition
Check the page should have:
Nutrition TrackingDaily Nutrition SummaryAdd MealMeal HistoryCaloriesProteinSodiumPotassiumPhosphorus
Verify these UI actions:
TestExpected ResultRoute opensNutrition page loads without 404Sidebar active stateNutrition Tracking is highlightedAPI loadsMeal logs appear from backendAdd mealNew meal appears immediatelyEdit mealUpdated values appear immediatelyDelete mealMeal is removed from tableEmpty stateShows clean message, not blank pageDaily totalsTotals match PostgreSQL SUM queryKidney limitsWarning appears when sodium/potassium/phosphorus exceeds limitConsoleNo Vue errors
Open browser console:
F12 → Console
Expected:
No red Vue errorsNo 401 UnauthorizedNo 404 API errorsNo CORS errors

11. Frontend File Checks
Go to frontend:
cd /u01/nix-life-os/frontend
Find Nutrition component:
find src -iname "*Nutrition*"
Expected file:
src/views/health/NutritionTrackingView.vue
Check route:
grep -R "nutrition" src/router -n
Expected route example:
{  path: "/health/nutrition",  name: "health-nutrition",  component: () => import("@/views/health/NutritionTrackingView.vue")}
Check API usage:
grep -R "health/nutrition" src -n
Expected:
/api/v1/health/nutrition/api/v1/health/nutrition/summary

12. Laravel Controller Checks
Find controller:
find app -iname "*Nutrition*"
Expected examples:
app/Http/Controllers/Api/V1/Health/NutritionController.phpapp/Models/HealthNutritionLog.php
Check controller methods:
grep -n "function" app/Http/Controllers/Api/V1/Health/NutritionController.php
Expected methods:
indexstoreshowupdatedestroysummary
Run PHP syntax check:
php -l app/Http/Controllers/Api/V1/Health/NutritionController.php
Expected:
No syntax errors detected

13. Common Errors and Fixes
Error: 404 Not Found
Cause: Route missing.
Fix:
php artisan route:list | grep -i nutritionphp artisan optimize:clear
Check routes/api.php contains something like:
Route::prefix('v1/health')->middleware('auth:sanctum')->group(function () {    Route::apiResource('nutrition', NutritionController::class);    Route::get('nutrition/summary', [NutritionController::class, 'summary']);});
Important: Put /nutrition/summary before apiResource if Laravel treats summary as {nutrition}.

Error: 401 Unauthorized
Cause: Missing or expired Bearer token.
Fix:
export TOKEN="NEW_LOGIN_TOKEN"
Then retry:
curl -i "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"

Error: 422 Validation Error
Example:
{  "message": "The meal date field is required."}
Fix: Send all required fields:
{  "meal_date": "2026-05-08",  "meal_type": "breakfast",  "food_name": "Boiled Egg",  "calories": 78}

Error: Data Saves but Does Not Show on Screen
Check API response:
curl -s "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Authorization: Bearer $TOKEN" \-H "Accept: application/json" | jq
If backend returns data but UI does not show it, the Vue page is probably still using static/placeholder text.
Check:
grep -n "Nutrition tracking page is available" -R src
Then replace placeholder code with dynamic API loading.

Error: Daily Totals Are Wrong
Check PostgreSQL:
SELECT     SUM(calories),    SUM(protein),    SUM(sodium),    SUM(potassium),    SUM(phosphorus)FROM health_nutrition_logsWHERE meal_date = '2026-05-08';
Compare with frontend cards.
If mismatch, check:
grep -R "total_calories\|totalProtein\|sodium" src/views src/components -n

14. Final Pass / Fail Checklist
Validation ItemStatusNutrition route opens correctly☐ Pass / ☐ FailSidebar link works☐ Pass / ☐ FailGET nutrition API works☐ Pass / ☐ FailPOST add meal works☐ Pass / ☐ FailPUT edit meal works☐ Pass / ☐ FailDELETE meal works☐ Pass / ☐ FailMeal history loads from database☐ Pass / ☐ FailCalories display correctly☐ Pass / ☐ FailProtein displays correctly☐ Pass / ☐ FailSodium displays correctly☐ Pass / ☐ FailPotassium displays correctly☐ Pass / ☐ FailPhosphorus displays correctly☐ Pass / ☐ FailDaily totals calculate correctly☐ Pass / ☐ FailKidney-friendly limits work☐ Pass / ☐ FailEmpty logs show clean empty state☐ Pass / ☐ FailBrowser console has no Vue errors☐ Pass / ☐ FailLaravel logs have no backend errors☐ Pass / ☐ Fail

15. Laravel Logs Check
cd /u01/nix-life-os/backendtail -f storage/logs/laravel.log
In another terminal, refresh the Nutrition page.
Expected:
No SQL errorNo route errorNo authentication errorNo controller exception

16. Docker Restart If Needed
cd /u01/nix-life-osdocker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend
Clear Laravel cache:
docker exec -it nixlifeos-backend php artisan optimize:clear
Then test again:
curl -i "http://127.0.0.1:8000/api/v1/health/nutrition" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"

Final Expected Result
The Nutrition Tracking page should no longer show only:
Nutrition tracking page is available.
It should display real dynamic data:
Daily CaloriesProteinSodiumPotassiumPhosphorusMeal HistoryAdd MealEdit MealDelete MealKidney-Friendly Nutrition Status
with all values loaded from PostgreSQL through Laravel API.