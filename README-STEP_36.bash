Thought for a couple of seconds
🔹 STEP 36 — Finance Budgets Page Testing
Nix Life OS — Finance Budgets QA Guide

You are testing the Finance Budgets page from frontend, backend API, PostgreSQL, and Vue UI behavior.

1. Confirm Containers Are Running

From project root:

cd /u01/nix-life-os

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Expected containers:

nixlifeos-nginx
nixlifeos-frontend
nixlifeos-backend-nginx
nixlifeos-backend
nixlifeos-postgres
nixlifeos-ai-engine

If backend or frontend is not running:

docker compose -f docker-compose.prod.yml up -d

Restart if needed:

docker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend nixlifeos-nginx
2. Get Authorization Token

Run login:

curl -i -X POST http://127.0.0.1:8000/api/v1/auth/login \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "email": "nix@example.com",
  "password": "password"
}'

Expected response:

{
  "success": true,
  "message": "Login successful.",
  "data": {
    "user": {
      "id": 1,
      "name": "Nix",
      "email": "nix@example.com"
    },
    "token": "YOUR_ACCESS_TOKEN"
  }
}

Export token:

export TOKEN="PASTE_TOKEN_HERE"

Test token:

echo $TOKEN
3. Test Finance Budgets Route Opens Correctly

Open in browser:

http://localhost/finance/budgets

or if using Vite dev server:

http://localhost:5173/finance/budgets

Expected result:

Finance Budgets page opens without 404.
Sidebar link opens Finance Budgets page.
Page title appears.
Budget cards/table appears.
No blank page.
No Vue console errors.

Check frontend route file:

cd /u01/nix-life-os/frontend

grep -R "finance/budgets\|FinanceBudgets" -n src/router src

Expected route should look similar to:

{
  path: "/finance/budgets",
  name: "finance-budgets",
  component: () => import("@/views/finance/FinanceBudgetsView.vue"),
}
4. Test Budget API Endpoint
GET Budgets
curl -i -X GET http://127.0.0.1:8000/api/v1/finance/budgets \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected successful response:

{
  "success": true,
  "message": "Budgets loaded successfully.",
  "data": [
    {
      "id": 1,
      "category_id": 1,
      "category_name": "Food",
      "amount": "300.00",
      "spent": "120.00",
      "remaining": "180.00",
      "usage_percentage": 40,
      "period": "monthly",
      "month": "2026-05",
      "is_over_budget": false
    }
  ]
}

If no data exists:

{
  "success": true,
  "message": "Budgets loaded successfully.",
  "data": []
}
5. Create Budget Test

Before creating a budget, check available categories:

curl -i -X GET http://127.0.0.1:8000/api/v1/finance/categories \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Food",
      "type": "expense"
    }
  ]
}

Create budget:

curl -i -X POST http://127.0.0.1:8000/api/v1/finance/budgets \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "category_id": 1,
  "amount": 300,
  "period": "monthly",
  "month": "2026-05",
  "notes": "Food budget for May 2026"
}'

Expected response:

{
  "success": true,
  "message": "Budget created successfully.",
  "data": {
    "id": 1,
    "category_id": 1,
    "amount": "300.00",
    "period": "monthly",
    "month": "2026-05",
    "notes": "Food budget for May 2026"
  }
}
6. Edit Budget Test

Replace {BUDGET_ID} with the created budget ID.

curl -i -X PUT http://127.0.0.1:8000/api/v1/finance/budgets/{BUDGET_ID} \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "category_id": 1,
  "amount": 450,
  "period": "monthly",
  "month": "2026-05",
  "notes": "Updated food budget for May 2026"
}'

Expected response:

{
  "success": true,
  "message": "Budget updated successfully.",
  "data": {
    "id": 1,
    "category_id": 1,
    "amount": "450.00",
    "period": "monthly",
    "month": "2026-05",
    "notes": "Updated food budget for May 2026"
  }
}
7. Delete Budget Test
curl -i -X DELETE http://127.0.0.1:8000/api/v1/finance/budgets/{BUDGET_ID} \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Budget deleted successfully."
}

Confirm it no longer appears:

curl -i -X GET http://127.0.0.1:8000/api/v1/finance/budgets \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
8. Test Budget Usage Percentage

Budget usage formula:

usage_percentage = spent / budget_amount * 100

Example:

Budget amount = 300
Spent = 120

120 / 300 * 100 = 40%

Expected UI:

Food Budget
Budget: $300.00
Spent: $120.00
Remaining: $180.00
Usage: 40%
Status: Normal

Create test expense transaction for same category:

curl -i -X POST http://127.0.0.1:8000/api/v1/finance/transactions \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "account_id": 1,
  "category_id": 1,
  "type": "expense",
  "amount": 120,
  "transaction_date": "2026-05-06",
  "description": "Budget usage test expense"
}'

Then reload budgets:

curl -i -X GET "http://127.0.0.1:8000/api/v1/finance/budgets?month=2026-05" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "amount": "300.00",
  "spent": "120.00",
  "remaining": "180.00",
  "usage_percentage": 40,
  "is_over_budget": false
}
9. Test Over-Budget Warning

Create or update a small budget:

curl -i -X POST http://127.0.0.1:8000/api/v1/finance/budgets \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "category_id": 1,
  "amount": 100,
  "period": "monthly",
  "month": "2026-05",
  "notes": "Over-budget warning test"
}'

Create expense higher than budget:

curl -i -X POST http://127.0.0.1:8000/api/v1/finance/transactions \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "account_id": 1,
  "category_id": 1,
  "type": "expense",
  "amount": 150,
  "transaction_date": "2026-05-06",
  "description": "Over budget test expense"
}'

Reload budgets:

curl -i -X GET "http://127.0.0.1:8000/api/v1/finance/budgets?month=2026-05" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "amount": "100.00",
  "spent": "150.00",
  "remaining": "-50.00",
  "usage_percentage": 150,
  "is_over_budget": true
}

Expected UI:

Warning badge appears.
Progress bar exceeds or caps at 100%.
Budget card/table row is highlighted.
Text shows Over Budget.
Remaining amount is negative or displayed as exceeded amount.
10. Test Monthly Budget Filtering

Test May 2026:

curl -i -X GET "http://127.0.0.1:8000/api/v1/finance/budgets?month=2026-05" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Test June 2026:

curl -i -X GET "http://127.0.0.1:8000/api/v1/finance/budgets?month=2026-06" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected behavior:

May filter shows only May budgets.
June filter shows only June budgets.
Changing month in UI reloads budget data.
Empty month shows clean empty state.
11. PostgreSQL Validation Queries

Enter PostgreSQL container:

docker exec -it nixlifeos-postgres psql -U nixlifeos -d nixlifeos

If username/database is different, check .env:

docker exec -it nixlifeos-backend printenv | grep DB_
Check Budget Table
SELECT *
FROM finance_budgets
ORDER BY id DESC;

Expected:

New budget record exists.
amount is correct.
category_id is correct.
month is correct.
period is monthly.
user_id is correct.
Check Budget With Category Name
SELECT
    b.id,
    b.user_id,
    b.category_id,
    c.name AS category_name,
    b.amount,
    b.period,
    b.month,
    b.notes,
    b.created_at,
    b.updated_at
FROM finance_budgets b
LEFT JOIN finance_categories c ON c.id = b.category_id
ORDER BY b.id DESC;
Check Monthly Spending By Category
SELECT
    t.category_id,
    c.name AS category_name,
    SUM(t.amount) AS total_spent
FROM finance_transactions t
LEFT JOIN finance_categories c ON c.id = t.category_id
WHERE t.type = 'expense'
  AND t.transaction_date >= '2026-05-01'
  AND t.transaction_date < '2026-06-01'
GROUP BY t.category_id, c.name
ORDER BY total_spent DESC;
Validate Usage Percentage Manually
SELECT
    b.id AS budget_id,
    c.name AS category_name,
    b.amount AS budget_amount,
    COALESCE(SUM(t.amount), 0) AS spent_amount,
    b.amount - COALESCE(SUM(t.amount), 0) AS remaining_amount,
    ROUND(
        CASE
            WHEN b.amount > 0 THEN COALESCE(SUM(t.amount), 0) / b.amount * 100
            ELSE 0
        END,
        2
    ) AS usage_percentage,
    CASE
        WHEN COALESCE(SUM(t.amount), 0) > b.amount THEN true
        ELSE false
    END AS is_over_budget
FROM finance_budgets b
LEFT JOIN finance_categories c ON c.id = b.category_id
LEFT JOIN finance_transactions t
    ON t.category_id = b.category_id
    AND t.type = 'expense'
    AND t.transaction_date >= '2026-05-01'
    AND t.transaction_date < '2026-06-01'
WHERE b.month = '2026-05'
GROUP BY b.id, c.name, b.amount
ORDER BY b.id DESC;
12. Laravel Route Checks

Inside backend container:

docker exec -it nixlifeos-backend php artisan route:list | grep finance

Expected routes:

GET       api/v1/finance/budgets
POST      api/v1/finance/budgets
GET       api/v1/finance/budgets/{id}
PUT       api/v1/finance/budgets/{id}
DELETE    api/v1/finance/budgets/{id}

If missing:

docker exec -it nixlifeos-backend php artisan route:clear
docker exec -it nixlifeos-backend php artisan config:clear
docker exec -it nixlifeos-backend php artisan cache:clear
docker restart nixlifeos-backend nixlifeos-backend-nginx
13. Vue UI Test Checklist
Page Load

Check:

[ ] Finance Budgets sidebar link works.
[ ] URL becomes /finance/budgets.
[ ] Page title displays correctly.
[ ] Budget list/table/cards display.
[ ] Loading state appears while API is loading.
[ ] No blank screen.
[ ] No console errors.
Budget List

Check:

[ ] Budgets load from backend API.
[ ] Category name displays correctly.
[ ] Budget amount displays correctly.
[ ] Spent amount displays correctly.
[ ] Remaining amount displays correctly.
[ ] Usage percentage displays correctly.
[ ] Progress bar displays correctly.
[ ] Over-budget status displays correctly.
Create Budget

Check:

[ ] Click Add Budget.
[ ] Modal or form opens.
[ ] Category dropdown loads.
[ ] Amount field accepts valid number.
[ ] Month field works.
[ ] Period field works.
[ ] Save creates budget.
[ ] Success message appears.
[ ] Budget list refreshes automatically.
[ ] New budget appears without manual browser refresh.
Edit Budget

Check:

[ ] Click Edit.
[ ] Existing values are loaded.
[ ] Update amount.
[ ] Save changes.
[ ] Success message appears.
[ ] List refreshes.
[ ] Updated value appears in UI.
[ ] Database value is updated.
Delete Budget

Check:

[ ] Click Delete.
[ ] Confirmation appears.
[ ] Confirm delete.
[ ] Budget disappears from UI.
[ ] Success message appears.
[ ] Budget is removed from database.
Monthly Filter

Check:

[ ] Month picker appears.
[ ] Selecting May 2026 loads May budgets.
[ ] Selecting June 2026 loads June budgets.
[ ] API request includes ?month=YYYY-MM.
[ ] Empty month displays proper empty state.
Empty State

Test with no budget data.

Expected UI:

No budgets found.
Add your first budget.
No table crash.
No undefined/null values.
No broken progress bar.
14. Browser DevTools Checks

Open browser DevTools → Network tab.

Reload Finance Budgets page.

Expected API call:

GET /api/v1/finance/budgets
Status: 200
Authorization: Bearer token exists
Response contains success: true

When creating:

POST /api/v1/finance/budgets
Status: 200 or 201

When editing:

PUT /api/v1/finance/budgets/{id}
Status: 200

When deleting:

DELETE /api/v1/finance/budgets/{id}
Status: 200

Console should not show:

Cannot read properties of undefined
budgets.map is not a function
category is undefined
401 Unauthorized
404 Not Found
500 Internal Server Error
15. Common Problems and Fixes
Problem 1 — 401 Unauthorized

Cause:

Token missing or expired.

Fix:

curl -i -X POST http://127.0.0.1:8000/api/v1/auth/login \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{"email":"nix@example.com","password":"password"}'

Then update frontend localStorage token or login again from UI.

Problem 2 — 404 Route Not Found

Cause:

Backend route is missing or route cache is stale.

Fix:

docker exec -it nixlifeos-backend php artisan route:list | grep budgets

docker exec -it nixlifeos-backend php artisan route:clear
docker exec -it nixlifeos-backend php artisan config:clear
docker exec -it nixlifeos-backend php artisan cache:clear

docker restart nixlifeos-backend nixlifeos-backend-nginx
Problem 3 — Budget Data Saves But Does Not Show in UI

Possible causes:

Frontend expects data.data but backend returns data directly.
Wrong field names.
Missing category_name.
Month filter mismatch.
User_id mismatch.

Check API response:

curl -s http://127.0.0.1:8000/api/v1/finance/budgets \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq

Frontend should handle both:

budgets.value = response.data.data || response.data || []
Problem 4 — Category Name Not Displaying

Cause:

Backend returns category_id only.
Frontend expects category_name.

Fix backend query/resource to include:

category_name

SQL check:

SELECT
    b.id,
    b.category_id,
    c.name AS category_name
FROM finance_budgets b
LEFT JOIN finance_categories c ON c.id = b.category_id;
Problem 5 — Usage Percentage Wrong

Cause:

Transactions are not filtered by month.
Income transactions included by mistake.
Category mismatch.
Amount stored as string and not parsed correctly.

Correct logic:

Only expense transactions.
Same category_id.
Same user_id.
Same selected month.
usage = spent / budget_amount * 100.
Problem 6 — Over-Budget Warning Not Showing

Cause:

Frontend checks usage_percentage > 100 but backend sends string.
Backend does not send is_over_budget.

Frontend safe check:

const isOverBudget = Number(budget.spent || 0) > Number(budget.amount || 0)
Problem 7 — Empty Budget Page Crashes

Cause:

Frontend tries to map null instead of empty array.

Fix:

budgets.value = Array.isArray(data) ? data : []

Template should use:

<div v-if="budgets.length === 0">
  No budgets found.
</div>
16. Backend Log Checks

Check Laravel logs:

docker exec -it nixlifeos-backend tail -n 100 storage/logs/laravel.log

Check backend container logs:

docker logs --tail=100 nixlifeos-backend

Check nginx logs:

docker logs --tail=100 nixlifeos-backend-nginx

Expected:

No 500 errors.
No SQL errors.
No missing controller errors.
No missing resource errors.
No auth middleware errors.
17. Final Pass / Fail Checklist
Backend API
[ ] GET /api/v1/finance/budgets returns 200.
[ ] POST /api/v1/finance/budgets creates budget.
[ ] PUT /api/v1/finance/budgets/{id} updates budget.
[ ] DELETE /api/v1/finance/budgets/{id} deletes budget.
[ ] API requires valid Bearer token.
[ ] API returns clean JSON response.
[ ] Validation errors are clear.
Database
[ ] Budget is inserted into finance_budgets.
[ ] Budget update changes database record.
[ ] Budget delete removes database record.
[ ] Budget category_id links correctly to finance_categories.
[ ] Monthly spending calculation is correct.
[ ] Usage percentage is correct.
[ ] Over-budget flag is correct.
Frontend
[ ] /finance/budgets route opens.
[ ] Sidebar link works.
[ ] Budget list loads from backend.
[ ] Add Budget works.
[ ] Edit Budget works.
[ ] Delete Budget works.
[ ] Month filter works.
[ ] Empty state works.
[ ] Loading state works.
[ ] Error state works.
[ ] Over-budget warning appears.
[ ] Browser console has no Vue errors.
Final Result
PASS = All API, database, and frontend checks succeed.

FAIL = Any of these happen:
- Route not found.
- API returns 401/404/500.
- Budget saves but does not display.
- Usage percentage is wrong.
- Over-budget warning does not appear.
- UI crashes on empty data.