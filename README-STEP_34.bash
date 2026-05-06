🔹 STEP 34 — Finance Accounts Page Testing
Nix Life OS — Finance Accounts QA Validation Guide
You are now testing the Finance Accounts page in the Nix Life OS Laravel + Vue.js project.
This step verifies that the frontend page, backend APIs, database records, and UI actions are working correctly for:
View accounts, create account, edit account, delete account, and refresh the UI after changes.

1. Confirm Containers Are Running
From project root:
cd /u01/nix-life-osdocker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Expected containers:
nixlifeos-frontendnixlifeos-backendnixlifeos-backend-nginxnixlifeos-postgresnixlifeos-ai-engine
If needed, restart:
docker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend

2. Clear Laravel Cache
docker exec -it nixlifeos-backend php artisan optimize:clear
Expected:
INFO  Clearing cached bootstrap files successfully.

3. Login and Get Bearer Token
Run:
curl -i -X POST http://127.0.0.1:8000/api/v1/auth/login \-H "Accept: application/json" \-H "Content-Type: application/json" \-d '{  "email": "nix@example.com",  "password": "password"}'
Expected successful response:
{  "success": true,  "message": "Login successful",  "data": {    "user": {      "id": 1,      "name": "Nix",      "email": "nix@example.com"    },    "token": "YOUR_TOKEN_HERE"  }}
Export token:
export TOKEN="PASTE_TOKEN_HERE"
Verify token:
echo $TOKEN

4. Test Finance Accounts GET API
curl -i http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected response:
{  "success": true,  "message": "Finance accounts loaded successfully.",  "data": [    {      "id": 1,      "name": "Cash Wallet",      "type": "cash",      "balance": "250.00",      "currency": "USD",      "description": "Main cash wallet",      "is_active": true    }  ]}
If empty, this is also valid:
{  "success": true,  "message": "Finance accounts loaded successfully.",  "data": []}

5. Test Create Account API
Run:
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Cash Wallet",  "type": "cash",  "balance": 250.00,  "currency": "USD",  "description": "Main cash wallet"}'
Expected response:
{  "success": true,  "message": "Finance account created successfully.",  "data": {    "id": 1,    "name": "Cash Wallet",    "type": "cash",    "balance": "250.00",    "currency": "USD",    "description": "Main cash wallet",    "is_active": true  }}
Create more test accounts:
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Bank Account",  "type": "bank",  "balance": 3000.00,  "currency": "USD",  "description": "Main bank account"}'
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Savings Account",  "type": "savings",  "balance": 1000.00,  "currency": "USD",  "description": "Emergency savings"}'

6. Test Validation Errors
Run invalid request:
curl -i -X POST http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "",  "type": "",  "balance": -100,  "currency": ""}'
Expected response:
{  "message": "The name field is required. The type field is required. The currency field is required.",  "errors": {    "name": [      "The name field is required."    ],    "type": [      "The type field is required."    ],    "balance": [      "The balance must be at least 0."    ],    "currency": [      "The currency field is required."    ]  }}
Validation must appear clearly in the Vue UI.

7. Test Update Account API
First get account ID:
curl -s http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Then update account. Replace 1 with the real account ID:
curl -i -X PUT http://127.0.0.1:8000/api/v1/finance/accounts/1 \-H "Accept: application/json" \-H "Content-Type: application/json" \-H "Authorization: Bearer $TOKEN" \-d '{  "name": "Updated Cash Wallet",  "type": "cash",  "balance": 500.00,  "currency": "USD",  "description": "Updated main cash wallet"}'
Expected response:
{  "success": true,  "message": "Finance account updated successfully.",  "data": {    "id": 1,    "name": "Updated Cash Wallet",    "type": "cash",    "balance": "500.00",    "currency": "USD",    "description": "Updated main cash wallet",    "is_active": true  }}

8. Test Delete Account API
Replace 1 with the real account ID:
curl -i -X DELETE http://127.0.0.1:8000/api/v1/finance/accounts/1 \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
Expected response:
{  "success": true,  "message": "Finance account deleted successfully."}
Then verify account was removed:
curl -i http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"

9. PostgreSQL Table Checks
Enter PostgreSQL container:
docker exec -it nixlifeos-postgres psql -U nixlifeos -d nixlifeos
If your database/user name is different, check .env:
cat backend/.env | grep DB_
Inside PostgreSQL:
\dt
Find finance tables:
\dt *finance*
Check accounts table:
SELECT     id,    user_id,    name,    type,    balance,    currency,    description,    is_active,    created_at,    updated_atFROM finance_accountsORDER BY id DESC;
Expected example:
 id | user_id | name                | type    | balance | currency | description              | is_active----+---------+---------------------+---------+---------+----------+--------------------------+-----------  3 | 1       | Savings Account     | savings | 1000.00 | USD      | Emergency savings        | true  2 | 1       | Bank Account        | bank    | 3000.00 | USD      | Main bank account        | true
Check only active accounts:
SELECT id, name, type, balance, currencyFROM finance_accountsWHERE is_active = trueORDER BY id DESC;
Check total balance:
SELECT     currency,    SUM(balance) AS total_balanceFROM finance_accountsWHERE is_active = trueGROUP BY currency;
Exit PostgreSQL:
\q

10. Finance Accounts Frontend Route Test
Open in browser:
http://localhost/finance/accounts
Or:
http://127.0.0.1/finance/accounts
Verify:
Page opens correctly.Sidebar Finance Accounts link works.No blank screen.No 404 page.Account cards or table are visible.Create Account button is visible.

11. Vue Router Check
Open:
cd /u01/nix-life-os/frontendnano src/router/index.js
Make sure route exists:
{  path: "/finance/accounts",  name: "finance-accounts",  component: () => import("../views/finance/FinanceAccountsView.vue"),  meta: {    requiresAuth: true,  },}
If your project does not use lazy loading, this is also okay:
import FinanceAccountsView from "../views/finance/FinanceAccountsView.vue";{  path: "/finance/accounts",  name: "finance-accounts",  component: FinanceAccountsView,  meta: {    requiresAuth: true,  },}

12. Sidebar Link Check
Find sidebar file. Usually one of these:
find src -iname "*Sidebar*"find src -iname "*Layout*"
Check link:
{  label: "Accounts",  path: "/finance/accounts",  icon: "Wallet"}
Or:
<RouterLink to="/finance/accounts">  Accounts</RouterLink>
Expected behavior:
Clicking Accounts opens /finance/accounts.Active menu state highlights correctly.Page does not reload fully.

13. Vue Component Checks
Open:
nano src/views/finance/FinanceAccountsView.vue
Verify the page has these functions or equivalent:
const fetchAccounts = async () => {}const createAccount = async () => {}const updateAccount = async () => {}const deleteAccount = async () => {}
API should call:
/api/v1/finance/accounts
With authorization:
Authorization: `Bearer ${token}`
After create/update/delete, the component should call:
await fetchAccounts()
The page should handle:
loadingerrorvalidationErrorsaccountsformeditingAccount

14. Browser Developer Tools Check
Open browser DevTools:
F12 → Console
There should be no errors like:
Cannot read properties of undefinedFailed to resolve componentUncaught TypeErrorVue Router warning
Then open:
F12 → Network → Fetch/XHR
Refresh the page.
Expected API call:
GET /api/v1/finance/accountsStatus: 200 OK
When creating account:
POST /api/v1/finance/accountsStatus: 200 OK or 201 Created
When updating account:
PUT /api/v1/finance/accounts/{id}Status: 200 OK
When deleting account:
DELETE /api/v1/finance/accounts/{id}Status: 200 OK

15. Account Balance Display Check
Verify backend response:
{  "balance": "3000.00",  "currency": "USD"}
Frontend should display:
$3,000.00
or:
USD 3,000.00
Balance should not display as:
NaNundefinednull[object Object]
Recommended frontend formatter:
const formatMoney = (value, currency = "USD") => {  const amount = Number(value || 0)  return new Intl.NumberFormat("en-US", {    style: "currency",    currency,  }).format(amount)}

16. Account Type Display Check
Expected account types:
cashbanksavingscredit_cardinvestmentother
Frontend should display them professionally:
CashBankSavingsCredit CardInvestmentOther
Recommended formatter:
const formatAccountType = (type) => {  const map = {    cash: "Cash",    bank: "Bank",    savings: "Savings",    credit_card: "Credit Card",    investment: "Investment",    other: "Other",  }  return map[type] || type}

17. Laravel Logs Check
Check backend logs:
docker exec -it nixlifeos-backend tail -n 100 storage/logs/laravel.log
Or:
docker logs nixlifeos-backend --tail=100
Expected:
No SQL errors.No route errors.No authentication errors.No missing controller errors.No validation exception crash.

18. Common Errors and Fixes
Error 1: Route Not Found
Response:
{  "message": "The route api/v1/finance/accounts could not be found."}
Fix: check routes/api.php.
Expected routes:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    Route::apiResource('finance/accounts', FinanceAccountController::class);});
Then run:
docker exec -it nixlifeos-backend php artisan route:cleardocker exec -it nixlifeos-backend php artisan route:list | grep finance

Error 2: Unauthorized
Response:
{  "message": "Unauthenticated."}
Fix:
export TOKEN="PASTE_VALID_TOKEN"
Then test again with:
-H "Authorization: Bearer $TOKEN"

Error 3: 500 Internal Server Error
Check logs:
docker exec -it nixlifeos-backend tail -n 100 storage/logs/laravel.log
Common causes:
Controller missingModel missingMigration not runColumn name mismatchUser ID not setMass assignment error
Run:
docker exec -it nixlifeos-backend php artisan migratedocker exec -it nixlifeos-backend php artisan optimize:clear

Error 4: Data Saves in DB but Does Not Show on Screen
Check API response:
curl -s http://127.0.0.1:8000/api/v1/finance/accounts \-H "Accept: application/json" \-H "Authorization: Bearer $TOKEN"
If API returns data but UI does not show it, fix Vue mapping.
Example:
accounts.value = response.data.data
Not:
accounts.value = response.data
Because response structure is usually:
{  "success": true,  "message": "...",  "data": []}

Error 5: Balance Shows NaN
Cause:
Number(undefined)
Fix:
const amount = Number(account.balance || 0)

Error 6: Create Works but UI Does Not Refresh
After successful create, run:
await fetchAccounts()
Also reset form:
form.value = {  name: "",  type: "cash",  balance: 0,  currency: "USD",  description: "",}

19. Final Manual UI Test Scenario
Use the browser and test this flow:
1. Open /finance/accounts.2. Confirm existing accounts load.3. Click Create Account.4. Add account:   Name: Test Wallet   Type: Cash   Balance: 150   Currency: USD5. Save.6. Confirm account appears immediately.7. Edit account balance from 150 to 250.8. Save.9. Confirm balance updates immediately.10. Delete the account.11. Confirm account disappears immediately.12. Refresh page.13. Confirm deleted account is still removed.14. Open browser console.15. Confirm no Vue errors.

20. Final Validation Checklist
Test ItemExpected ResultStatusFinance Accounts route opens/finance/accounts loads successfully☐Sidebar link worksOpens correct page☐GET API worksReturns account list☐POST API worksCreates account☐PUT API worksUpdates account☐DELETE API worksDeletes account☐PostgreSQL saves recordsData exists in finance_accounts☐Balance displays correctlyNo NaN/null/undefined☐Account type displays correctlyUser-friendly type labels☐Validation errors showClear error messages in UI☐UI refreshes after createNew account appears immediately☐UI refreshes after updateUpdated data appears immediately☐UI refreshes after deleteDeleted account disappears☐Browser console cleanNo Vue errors☐Laravel logs cleanNo backend errors☐

STEP 34 Result
When all checklist items pass, mark this step as:
✅ STEP 34 — Finance Accounts Page Testing Completed Successfully
Then continue to:
🔹 STEP 35 — Finance Transactions Page Testing