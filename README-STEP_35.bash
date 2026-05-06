🔹 STEP 35 — Finance Transactions Page Testing
Senior QA Engineer Guide for Nix Life OS
You are testing the Finance Transactions page in the Nix Life OS Laravel + Vue.js project.
This step verifies:


Finance Transactions route opens correctly.


Transaction list loads successfully.


API endpoint /api/v1/finance/transactions works.


Create transaction works for income.


Create transaction works for expense.


Edit transaction works.


Delete transaction works.


Filtering by account, category, and date works.


Account balance updates after transaction changes.


Empty transaction history does not break the UI.



1. Go to Project Root
cd /u01/nix-life-os
Check containers:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Expected running containers:
nixlifeos-frontendnixlifeos-backendnixlifeos-backend-nginxnixlifeos-postgres

2. Check Laravel Backend Health
curl -i http://127.0.0.1:8000/api/v1/health \-H "Accept: application/json"
Expected:
{  "success": true,  "message": "API is healthy"}
If /health does not exist, test with:
curl -i http://127.0.0.1:8000/api/v1/dashboard/summary \-H "Accept: application/json"

3. Login and Export Token
Use your existing test user.
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}' | jq -r '.data.token')
Verify token:
echo $TOKEN
Expected:
eyJ...
If empty, test login directly:
curl -i -X POST http://127.0.0.1:8000/api/v1/auth/login \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}'

4. Laravel Route Checks
Enter backend container:
docker exec -it nixlifeos-backend bash
Check finance transaction routes:
php artisan route:list | grep finance
Or specifically:
php artisan route:list | grep transactions
Expected routes should include something similar to:
GET|HEAD   api/v1/finance/transactionsPOST       api/v1/finance/transactionsGET|HEAD   api/v1/finance/transactions/{id}PUT|PATCH  api/v1/finance/transactions/{id}DELETE     api/v1/finance/transactions/{id}
Exit container:
exit
If routes are missing, check:
docker exec -it nixlifeos-backend bashphp artisan route:clearphp artisan config:clearphp artisan cache:clearphp artisan optimize:clearphp artisan route:list | grep financeexit

5. Check Finance Accounts Before Transactions
Before creating a transaction, confirm at least one finance account exists.
curl -s http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "message": "Finance accounts loaded successfully.",  "data": [    {      "id": 1,      "name": "Cash Wallet",      "type": "cash",      "balance": "1000.00"    }  ]}
If no accounts exist, create one:
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Cash Wallet",  "type": "cash",  "balance": 1000,  "currency": "USD",  "description": "Main cash account for transaction testing"}'
Then get the account ID:
ACCOUNT_ID=$(curl -s http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')echo $ACCOUNT_ID

6. Test GET Finance Transactions
curl -i http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected successful response:
{  "success": true,  "message": "Finance transactions loaded successfully.",  "data": []}
If transactions exist:
{  "success": true,  "message": "Finance transactions loaded successfully.",  "data": [    {      "id": 1,      "account_id": 1,      "type": "income",      "amount": "250.00",      "category": "Salary",      "transaction_date": "2026-05-06",      "description": "Monthly salary test"    }  ]}

7. Create Income Transaction
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d "{  \"account_id\": $ACCOUNT_ID,  \"type\": \"income\",  \"amount\": 250,  \"category\": \"Salary\",  \"transaction_date\": \"2026-05-06\",  \"description\": \"STEP 35 test income transaction\"}"
Expected:
{  "success": true,  "message": "Finance transaction created successfully.",  "data": {    "id": 1,    "account_id": 1,    "type": "income",    "amount": "250.00",    "category": "Salary",    "transaction_date": "2026-05-06",    "description": "STEP 35 test income transaction"  }}
Save transaction ID:
INCOME_TRANSACTION_ID=$(curl -s http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')echo $INCOME_TRANSACTION_ID

8. Create Expense Transaction
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d "{  \"account_id\": $ACCOUNT_ID,  \"type\": \"expense\",  \"amount\": 40,  \"category\": \"Food\",  \"transaction_date\": \"2026-05-06\",  \"description\": \"STEP 35 test expense transaction\"}"
Expected:
{  "success": true,  "message": "Finance transaction created successfully.",  "data": {    "id": 2,    "account_id": 1,    "type": "expense",    "amount": "40.00",    "category": "Food",    "transaction_date": "2026-05-06",    "description": "STEP 35 test expense transaction"  }}
Save expense transaction ID:
EXPENSE_TRANSACTION_ID=$(curl -s http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq -r '.data[] | select(.description=="STEP 35 test expense transaction") | .id')echo $EXPENSE_TRANSACTION_ID

9. Validate List After Create
curl -s http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "data": [    {      "type": "income",      "amount": "250.00"    },    {      "type": "expense",      "amount": "40.00"    }  ]}

10. Test Edit Transaction
Update expense amount from 40 to 55.
curl -i -X PUT http://127.0.0.1:8000/api/v1/finance/transactions/$EXPENSE_TRANSACTION_ID \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d "{  \"account_id\": $ACCOUNT_ID,  \"type\": \"expense\",  \"amount\": 55,  \"category\": \"Food\",  \"transaction_date\": \"2026-05-06\",  \"description\": \"STEP 35 updated expense transaction\"}"
Expected:
{  "success": true,  "message": "Finance transaction updated successfully.",  "data": {    "id": 2,    "account_id": 1,    "type": "expense",    "amount": "55.00",    "category": "Food",    "transaction_date": "2026-05-06",    "description": "STEP 35 updated expense transaction"  }}
Confirm update:
curl -s http://127.0.0.1:8000/api/v1/finance/transactions/$EXPENSE_TRANSACTION_ID \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq

11. Test Delete Transaction
curl -i -X DELETE http://127.0.0.1:8000/api/v1/finance/transactions/$EXPENSE_TRANSACTION_ID \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected:
{  "success": true,  "message": "Finance transaction deleted successfully."}
Confirm deleted:
curl -s http://127.0.0.1:8000/api/v1/finance/transactions \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
The deleted transaction should no longer appear.

12. Test Filters
Filter by Account
curl -s "http://127.0.0.1:8000/api/v1/finance/transactions?account_id=$ACCOUNT_ID" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "data": [    {      "account_id": 1    }  ]}
Filter by Category
curl -s "http://127.0.0.1:8000/api/v1/finance/transactions?category=Salary" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "data": [    {      "category": "Salary"    }  ]}
Filter by Type
curl -s "http://127.0.0.1:8000/api/v1/finance/transactions?type=income" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "data": [    {      "type": "income"    }  ]}
Filter by Date
curl -s "http://127.0.0.1:8000/api/v1/finance/transactions?date_from=2026-05-01&date_to=2026-05-31" \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected:
{  "success": true,  "data": [    {      "transaction_date": "2026-05-06"    }  ]}

13. Check Balance Update After Transactions
Get account balance:
curl -s http://127.0.0.1:8000/api/v1/finance/accounts/$ACCOUNT_ID \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Expected logic:
Initial balance: 1000Income created: +250Expense created: -40Expense updated to 55: -55Expense deleted: +55 restoredFinal expected balance after deleting expense:1000 + 250 = 1250
Expected account response:
{  "success": true,  "data": {    "id": 1,    "balance": "1250.00"  }}
If your system does not store balance directly and calculates balance dynamically, then verify that the Finance Dashboard reflects:
Total Balance = Account Opening Balance + Income - Expense

14. PostgreSQL Validation Queries
Enter PostgreSQL container:
docker exec -it nixlifeos-postgres psql -U nixlifeos -d nixlifeos
If the username/database is different, inspect .env:
docker exec -it nixlifeos-backend bashcat .env | grep DB_exit
Then use the correct values.

Check Finance Accounts Table
SELECT     id,    name,    type,    balance,    currency,    created_at,    updated_atFROM finance_accountsORDER BY id DESC;
Expected:
Cash Wallet | cash | 1250.00 | USD

Check Finance Transactions Table
SELECT    id,    account_id,    type,    amount,    category,    transaction_date,    description,    created_at,    updated_atFROM finance_transactionsORDER BY id DESC;
Expected:
income | 250.00 | Salary | STEP 35 test income transaction
Deleted expense transaction should not appear unless you use soft deletes.

If Soft Deletes Are Enabled
SELECT    id,    account_id,    type,    amount,    category,    deleted_atFROM finance_transactionsORDER BY id DESC;
Expected deleted transaction:
deleted_at is not null

Validate Account Balance by SQL
SELECT     fa.id,    fa.name,    fa.balance AS stored_balance,    COALESCE(SUM(        CASE             WHEN ft.type = 'income' THEN ft.amount            WHEN ft.type = 'expense' THEN -ft.amount            ELSE 0        END    ), 0) AS transaction_netFROM finance_accounts faLEFT JOIN finance_transactions ft     ON ft.account_id = fa.idWHERE fa.id = 1GROUP BY fa.id, fa.name, fa.balance;
Replace 1 with your real $ACCOUNT_ID.
Exit:
\q

15. Frontend Browser Checks
Open the app:
http://localhost
Or, depending on your setup:
http://127.0.0.1
Go to:
Finance → Transactions
Expected route examples:
/finance/transactions
or:
/finance/transactions/list
Check the following:
CheckExpected ResultSidebar link opens pageFinance Transactions page appearsURL route is correct/finance/transactionsPage title appearsFinance TransactionsTransaction table loadsExisting records displayEmpty state worksMessage like “No transactions found”Create button worksModal/form opensIncome creation worksNew income appears in listExpense creation worksNew expense appears in listEdit button worksForm opens with selected transactionDelete button worksRow removed after confirmationAccount filter worksOnly selected account transactions appearCategory filter worksOnly selected category appearsDate filter worksOnly selected date range appearsBalance updatesRelated account balance changesLoading state appearsSpinner or loading text while API is pendingError state appearsClear error message if API fails

16. Browser DevTools Checks
Open DevTools:
F12 → Console
Expected:
No Vue errorsNo uncaught promise errorsNo failed importsNo undefined property errors
Then open:
F12 → Network → Fetch/XHR
Reload the transactions page.
Expected API call:
GET /api/v1/finance/transactionsStatus: 200
When creating transaction:
POST /api/v1/finance/transactionsStatus: 200 or 201
When editing:
PUT /api/v1/finance/transactions/{id}Status: 200
When deleting:
DELETE /api/v1/finance/transactions/{id}Status: 200

17. Vue Component Checks
Check route file:
cd /u01/nix-life-os/frontendgrep -R "FinanceTransactions" -n src/router src/views src/components
Expected route example:
{  path: "/finance/transactions",  name: "finance-transactions",  component: () => import("../views/finance/FinanceTransactionsView.vue"),}
Check component exists:
ls -lah src/views/finance/
Expected:
FinanceTransactionsView.vue
Check API usage:
grep -R "finance/transactions" -n src
Expected:
/api/v1/finance/transactions
Check if token is sent:
grep -R "Authorization" -n src
Expected:
Authorization: `Bearer ${token}`

18. Laravel Controller Checks
Enter backend:
docker exec -it nixlifeos-backend bash
Search controller:
grep -R "FinanceTransaction" -n app/Http/Controllers app/Models app/Http/Resources
Expected files:
app/Models/FinanceTransaction.phpapp/Http/Controllers/Api/FinanceTransactionController.php
Check route file:
grep -R "finance/transactions" -n routes
Expected:
Route::apiResource('finance/transactions', FinanceTransactionController::class);
or:
Route::prefix('finance')->group(function () {    Route::apiResource('transactions', FinanceTransactionController::class);});
Clear Laravel caches if changes are made:
php artisan optimize:clearphp artisan route:clearphp artisan config:clearphp artisan cache:clearexit

19. Laravel Logs Check
docker exec -it nixlifeos-backend bashtail -f storage/logs/laravel.log
Then test the page from browser.
Expected:
No SQL errorsNo validation exceptionsNo missing controller errorsNo route not found errorsNo unauthorized errors
Stop log tail:
CTRL + C
Exit:
exit

20. Common Errors and Fixes
Error: 401 Unauthorized
Cause:
Missing or invalid Bearer token
Fix:
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{"email":"nix@example.com","password":"password"}' | jq -r '.data.token')
Then retry with:
-H "Authorization: Bearer $TOKEN"

Error: 404 Route Not Found
Check:
docker exec -it nixlifeos-backend php artisan route:list | grep transactions
Fix:
docker exec -it nixlifeos-backend php artisan optimize:clear
Also confirm route exists in:
backend/routes/api.php

Error: 422 Validation Error
Example:
{  "message": "The amount field is required."}
Fix request body:
{  "account_id": 1,  "type": "income",  "amount": 250,  "category": "Salary",  "transaction_date": "2026-05-06",  "description": "Test income"}
Required fields should usually be:
account_idtypeamountcategorytransaction_date

Error: Account Not Found
Cause:
Invalid account_id
Fix:
curl -s http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN" | jq
Use a valid account ID.

Error: Data Saves in DB But Not Showing on Screen
Check frontend API response in DevTools.
Common causes:
Frontend expects response.data but backend returns response.data.dataWrong field namesWrong routeList is not refreshed after create/update/deleteMissing await on API callComponent state not updated
Frontend should usually handle:
transactions.value = response.data.data || [];
After create/update/delete:
await fetchTransactions();

Error: Balance Not Updating
Check whether balance logic exists in backend.
Expected backend behavior:
Income increases account balanceExpense decreases account balanceEditing reverses old transaction and applies new transactionDeleting reverses transaction impact
Example logic:
Create income: balance + amountCreate expense: balance - amountUpdate: reverse old amount first, then apply new amountDelete: reverse deleted transaction

21. Final Pass/Fail Checklist
Test ItemStatusBackend containers are runningPASS / FAILLogin returns Bearer tokenPASS / FAILLaravel route /api/v1/finance/transactions existsPASS / FAILGET transactions returns 200PASS / FAILEmpty transaction history displays correctlyPASS / FAILCreate income transaction worksPASS / FAILIncome appears in DBPASS / FAILIncome appears in UIPASS / FAILAccount balance increases after incomePASS / FAILCreate expense transaction worksPASS / FAILExpense appears in DBPASS / FAILExpense appears in UIPASS / FAILAccount balance decreases after expensePASS / FAILEdit transaction worksPASS / FAILEdited transaction updates in DBPASS / FAILEdited transaction updates in UIPASS / FAILBalance recalculates after editPASS / FAILDelete transaction worksPASS / FAILDeleted transaction removed from UIPASS / FAILDeleted transaction removed/soft-deleted in DBPASS / FAILBalance recalculates after deletePASS / FAILFilter by account worksPASS / FAILFilter by category worksPASS / FAILFilter by date worksPASS / FAILBrowser console has no Vue errorsPASS / FAILNetwork tab shows correct API callsPASS / FAILLaravel logs have no errorsPASS / FAIL

STEP 35 Final Validation Result
Use this final result format:
STEP 35 — Finance Transactions Page TestingResult: PASS / FAILBackend API:- GET /api/v1/finance/transactions: PASS / FAIL- POST income transaction: PASS / FAIL- POST expense transaction: PASS / FAIL- PUT transaction: PASS / FAIL- DELETE transaction: PASS / FAILDatabase:- Transactions saved correctly: PASS / FAIL- Account balance updated correctly: PASS / FAILFrontend:- Route opens correctly: PASS / FAIL- Transaction list loads: PASS / FAIL- Create/Edit/Delete actions work: PASS / FAIL- Filters work: PASS / FAIL- Empty state works: PASS / FAIL- No console errors: PASS / FAILNotes:- Add any errors found here.