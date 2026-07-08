# Finance Module Inventory

Finance Module must remain unchanged.

## Protected Rule

No Finance routes, APIs, models, controllers, pages, components, UI, or logic were changed in Bundle 1.

## Finance Files Detected
```text
backend/app/Console/Commands/GenerateFinanceAlerts.php
backend/app/Http/Controllers/Api/FinanceAccountController.php
backend/app/Http/Controllers/Api/FinanceCategoryController.php
backend/app/Http/Controllers/Api/FinanceTransactionController.php
backend/app/Http/Controllers/Api/V1/Finance/BudgetAlertRuleController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceAnomalyController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceForecastController.php
backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php
backend/app/Http/Controllers/FinanceCategoryController.php
backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php
backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php
backend/app/Http/Requests/StoreFinanceAccountRequest.php
backend/app/Http/Requests/StoreFinanceCategoryRequest.php
backend/app/Http/Requests/StoreFinanceTransactionRequest.php
backend/app/Http/Requests/UpdateFinanceAccountRequest.php
backend/app/Http/Requests/UpdateFinanceCategoryRequest.php
backend/app/Http/Requests/UpdateFinanceTransactionRequest.php
backend/app/Http/Resources/Finance/FinanceAnomalyResource.php
backend/app/Http/Resources/Finance/FinanceBudgetResource.php
backend/app/Http/Resources/Finance/FinanceBudgetSummaryResource.php
backend/app/Http/Resources/Finance/FinanceForecastSummaryResource.php
backend/app/Http/Resources/Finance/FinanceIntelligenceSettingResource.php
backend/app/Http/Resources/FinanceAccountResource.php
backend/app/Http/Resources/FinanceCategoryResource.php
backend/app/Http/Resources/FinanceTransactionResource.php
backend/app/Models/Finance/Expense.php
backend/app/Models/Finance/Income.php
backend/app/Models/FinanceAccount.php
backend/app/Models/FinanceBudget.php
backend/app/Models/FinanceBudgetLine.php
backend/app/Models/FinanceCategory.php
backend/app/Models/FinanceTransaction.php
backend/app/Policies/FinanceCategoryPolicy.php
backend/app/Services/Finance/BudgetCalculationService.php
backend/app/Services/FinanceAIInsightService.php
backend/app/Services/FinanceBalanceService.php
backend/app/Services/Notifications/FinanceNotificationService.php
backend/core[finance_score],
backend/database/factories/FinanceCategoryFactory.php
backend/database/migrations/2026_05_04_011800_create_finance_core_tables.php
backend/database/migrations/2026_05_04_012611_create_finance_core_tables.php
backend/database/migrations/2026_05_04_014144_add_description_to_finance_accounts_table.php
backend/database/migrations/2026_05_04_015954_fix_finance_transactions_missing_columns.php
backend/database/migrations/2026_05_04_020126_fix_finance_transactions_missing_columns.php
backend/database/migrations/2026_05_04_022137_create_or_fix_finance_budget_lines_table.php
backend/database/migrations/2026_05_04_023606_fix_finance_budget_tables_columns.php
backend/database/migrations/2026_05_06_011628_add_to_account_id_to_finance_transactions_table.php
backend/database/migrations/2026_05_06_015232_fix_finance_transactions_nullable_optional_columns.php
backend/database/migrations/2026_05_06_015607_fix_finance_transactions_insert_defaults.php
backend/database/migrations/2026_06_11_235900_create_finance_categories_table_if_missing.php
backend/database/migrations/disabled/create_finance_accounts_table.php
backend/database/migrations/disabled/create_finance_categories_table.php
backend/database/migrations/disabled/create_finance_transactions_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040708_create_finance_categories_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_041508_create_finance_categories_table.php
backend/database/seeders/FinanceCategorySeeder.php
backups/manual-fix-patches/before_dashboard_finance_health_fix_20260616_184610.patch
backups/step77-error-state-20260517-033609/frontend/src/services/financeService.ts
backups/step77-error-state-hotfix-v2-20260517-034403/frontend/src/services/financeService.ts
backups/step81-1-finance-hotfix-20260517-071338/backend/app/Http/Controllers/Api/FinanceAccountController.php
backups/step81-1-finance-hotfix-20260517-071338/backend/app/Http/Controllers/Api/FinanceTransactionController.php
backups/step81-2-finance-json-hotfix-20260517-071625/backend/app/Http/Controllers/Api/FinanceAccountController.php
backups/step81-2-finance-json-hotfix-20260517-071625/backend/app/Http/Controllers/Api/FinanceTransactionController.php
backups/step81-e2e-20260517-070831/backend/app/Http/Controllers/Api/FinanceAccountController.php
backups/step81-e2e-20260517-070831/backend/app/Http/Controllers/Api/FinanceTransactionController.php
backups/step82-dashboard-performance-20260517-224851/backend/app/Http/Controllers/Api/FinanceTransactionController.php
backups/step90-6-frontend-api-cleanup/src-backup/api/financeApi.js
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceAIInsightsWidget.vue
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceAddTransactionForm.vue
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceBudgetProgress.vue
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceDashboardCards.vue
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceIncomeExpenseChart.vue
backups/step90-6-frontend-api-cleanup/src-backup/components/finance/FinanceTransactionsTable.vue
backups/step90-6-frontend-api-cleanup/src-backup/layouts/FinanceLayout.vue
backups/step90-6-frontend-api-cleanup/src-backup/services/financeService.ts
backups/step90-6-frontend-api-cleanup/src-backup/src/api/financeApi.js
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceAIInsightsWidget.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceAddTransactionForm.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceBudgetProgress.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceDashboardCards.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceIncomeExpenseChart.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/components/finance/FinanceTransactionsTable.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/layouts/FinanceLayout.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/services/financeService.ts
backups/step90-6-frontend-api-cleanup/src-backup/src/views/FinanceDashboardView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/ExpensesView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/FinanceAIInsightsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/FinanceAccountsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/FinanceBudgetsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/FinanceDashboardView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/finance/FinanceTransactionsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/FinanceDashboardView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/ExpensesView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/FinanceAIInsightsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/FinanceAccountsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/FinanceBudgetsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/FinanceDashboardView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/finance/FinanceTransactionsView.vue
fix-finance-tables.sql
frontend/src/api/financeApi.js
frontend/src/components/finance/CategoryModal.vue
frontend/src/components/finance/FinanceAIInsightsWidget.vue
frontend/src/components/finance/FinanceAddTransactionForm.vue
frontend/src/components/finance/FinanceBudgetProgress.vue
frontend/src/components/finance/FinanceDashboardCards.vue
frontend/src/components/finance/FinanceIncomeExpenseChart.vue
frontend/src/components/finance/FinanceTransactionsTable.vue
frontend/src/layouts/FinanceLayout.vue
frontend/src/services/financeCategoryService.ts
frontend/src/services/financeService.ts
frontend/src/views/FinanceDashboardView.vue
frontend/src/views/finance/CreateBudgetView.vue
frontend/src/views/finance/CreateCategoryView.vue
frontend/src/views/finance/ExpensesView.vue
frontend/src/views/finance/FinanceAIInsightsView.vue
frontend/src/views/finance/FinanceAccountsView.vue
frontend/src/views/finance/FinanceBudgetsView.vue
frontend/src/views/finance/FinanceDashboard.vue
frontend/src/views/finance/FinanceDashboardView.vue
frontend/src/views/finance/FinanceTransactionsView.vue
nix-life-os-finance-admin-files.zip
nix-life-os-missing-finance-admin-files.zip
step61-productivity-files/frontend/src/layouts/FinanceLayout.vue
step71-life-balance-ai-export/backend/app/Models/FinanceAccount.php
step71-life-balance-ai-export/backend/app/Models/FinanceBudget.php
step71-life-balance-ai-export/backend/app/Models/FinanceTransaction.php
step71-life-balance-ai-files/backend/app/Models/FinanceAccount.php
step71-life-balance-ai-files/backend/app/Models/FinanceBudget.php
step71-life-balance-ai-files/backend/app/Models/FinanceTransaction.php
step73_auth_export/backend/database/migrations/2026_05_04_011800_create_finance_core_tables.php
step73_auth_export/backend/database/migrations/2026_05_04_012611_create_finance_core_tables.php
step73_auth_export/backend/database/migrations/2026_05_04_014144_add_description_to_finance_accounts_table.php
step73_auth_export/backend/database/migrations/2026_05_04_015954_fix_finance_transactions_missing_columns.php
step73_auth_export/backend/database/migrations/2026_05_04_020126_fix_finance_transactions_missing_columns.php
step73_auth_export/backend/database/migrations/2026_05_04_022137_create_or_fix_finance_budget_lines_table.php
step73_auth_export/backend/database/migrations/2026_05_04_023606_fix_finance_budget_tables_columns.php
step73_auth_export/backend/database/migrations/2026_05_06_011628_add_to_account_id_to_finance_transactions_table.php
step73_auth_export/backend/database/migrations/2026_05_06_015232_fix_finance_transactions_nullable_optional_columns.php
step73_auth_export/backend/database/migrations/2026_05_06_015607_fix_finance_transactions_insert_defaults.php
step73_auth_export/backend/database/migrations/disabled/create_finance_accounts_table.php
step73_auth_export/backend/database/migrations/disabled/create_finance_categories_table.php
step73_auth_export/backend/database/migrations/disabled/create_finance_transactions_table.php
step73_auth_export/backend/database/seeders/FinanceCategorySeeder.php
step76-empty-data-regression-patch/frontend/src/components/finance/FinanceBudgetProgress.vue
step76-empty-data-regression-patch/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step76-empty-data-regression-patch/frontend/src/components/finance/FinanceTransactionsTable.vue
step77-error-state-hotfix-v2/frontend/src/services/financeService.ts
step77-error-state-patch/frontend/src/services/financeService.ts
step77-error-state-review-files/backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php
step77-error-state-review-files/backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php
step77-error-state-review-files/backend/app/Http/Requests/StoreFinanceAccountRequest.php
step77-error-state-review-files/backend/app/Http/Requests/StoreFinanceCategoryRequest.php
step77-error-state-review-files/backend/app/Http/Requests/StoreFinanceTransactionRequest.php
step77-error-state-review-files/backend/app/Http/Requests/UpdateFinanceAccountRequest.php
step77-error-state-review-files/backend/app/Http/Requests/UpdateFinanceCategoryRequest.php
step77-error-state-review-files/backend/app/Http/Requests/UpdateFinanceTransactionRequest.php
step77-error-state-review-files/frontend/src/components/finance/FinanceAIInsightsWidget.vue
step77-error-state-review-files/frontend/src/components/finance/FinanceAddTransactionForm.vue
step77-error-state-review-files/frontend/src/components/finance/FinanceBudgetProgress.vue
step77-error-state-review-files/frontend/src/components/finance/FinanceDashboardCards.vue
step77-error-state-review-files/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step77-error-state-review-files/frontend/src/components/finance/FinanceTransactionsTable.vue
step77-error-state-review-files/frontend/src/services/financeService.ts
step77-error-state-review-files/frontend/src/views/FinanceDashboardView.vue
step77-error-state-review-files/frontend/src/views/finance/ExpensesView.vue
step77-error-state-review-files/frontend/src/views/finance/FinanceAIInsightsView.vue
step77-error-state-review-files/frontend/src/views/finance/FinanceAccountsView.vue
step77-error-state-review-files/frontend/src/views/finance/FinanceBudgetsView.vue
step77-error-state-review-files/frontend/src/views/finance/FinanceDashboardView.vue
step77-error-state-review-files/frontend/src/views/finance/FinanceTransactionsView.vue
step81-1-finance-e2e-hotfix.tar.gz
step81-1-finance-e2e-hotfix/README_STEP81_1_FINANCE_HOTFIX.md
step81-1-finance-e2e-hotfix/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-1-finance-e2e-hotfix/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step81-1-finance-e2e-hotfix/install_step81_1_finance_hotfix.sh
step81-1-finance-e2e-hotfix/scripts/step81_1_finance_retest.sh
step81-1-finance-e2e-hotfix/step81-1-finance-e2e-hotfix/README_STEP81_1_FINANCE_HOTFIX.md
step81-1-finance-e2e-hotfix/step81-1-finance-e2e-hotfix/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-1-finance-e2e-hotfix/step81-1-finance-e2e-hotfix/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step81-1-finance-e2e-hotfix/step81-1-finance-e2e-hotfix/install_step81_1_finance_hotfix.sh
step81-1-finance-e2e-hotfix/step81-1-finance-e2e-hotfix/scripts/step81_1_finance_retest.sh
step81-2-finance-json-hotfix.tar.gz
step81-2-finance-json-hotfix/README_STEP81_2_FINANCE_JSON_HOTFIX.md
step81-2-finance-json-hotfix/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-2-finance-json-hotfix/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step81-2-finance-json-hotfix/install_step81_2_finance_json_hotfix.sh
step81-2-finance-json-hotfix/scripts/step81_2_finance_retest.sh
step81-2-finance-json-hotfix/step81-2-finance-json-hotfix/README_STEP81_2_FINANCE_JSON_HOTFIX.md
step81-2-finance-json-hotfix/step81-2-finance-json-hotfix/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-2-finance-json-hotfix/step81-2-finance-json-hotfix/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step81-2-finance-json-hotfix/step81-2-finance-json-hotfix/install_step81_2_finance_json_hotfix.sh
step81-2-finance-json-hotfix/step81-2-finance-json-hotfix/scripts/step81_2_finance_retest.sh
step81-e2e-export/backend/app/Models/FinanceAccount.php
step81-e2e-export/backend/app/Models/FinanceBudget.php
step81-e2e-export/backend/app/Models/FinanceTransaction.php
step81-e2e-export/backend/app/Services/Finance/BudgetCalculationService.php
step81-e2e-export/backend/app/Services/FinanceAIInsightService.php
step81-e2e-export/backend/app/Services/FinanceBalanceService.php
step81-e2e-export/backend/database/migrations/2026_05_04_011800_create_finance_core_tables.php
step81-e2e-export/backend/database/migrations/2026_05_04_012611_create_finance_core_tables.php
step81-e2e-export/backend/database/migrations/2026_05_04_014144_add_description_to_finance_accounts_table.php
step81-e2e-export/backend/database/migrations/2026_05_04_015954_fix_finance_transactions_missing_columns.php
step81-e2e-export/backend/database/migrations/2026_05_04_020126_fix_finance_transactions_missing_columns.php
step81-e2e-export/backend/database/migrations/2026_05_04_022137_create_or_fix_finance_budget_lines_table.php
step81-e2e-export/backend/database/migrations/2026_05_04_023606_fix_finance_budget_tables_columns.php
step81-e2e-export/backend/database/migrations/2026_05_06_011628_add_to_account_id_to_finance_transactions_table.php
step81-e2e-export/backend/database/migrations/2026_05_06_015232_fix_finance_transactions_nullable_optional_columns.php
step81-e2e-export/backend/database/migrations/2026_05_06_015607_fix_finance_transactions_insert_defaults.php
step81-e2e-export/backend/database/migrations/disabled/create_finance_accounts_table.php
step81-e2e-export/backend/database/migrations/disabled/create_finance_categories_table.php
step81-e2e-export/backend/database/migrations/disabled/create_finance_transactions_table.php
step81-e2e-export/backend/database/seeders/FinanceCategorySeeder.php
step81-e2e-export/frontend/src/components/finance/FinanceAIInsightsWidget.vue
step81-e2e-export/frontend/src/components/finance/FinanceAddTransactionForm.vue
step81-e2e-export/frontend/src/components/finance/FinanceBudgetProgress.vue
step81-e2e-export/frontend/src/components/finance/FinanceDashboardCards.vue
step81-e2e-export/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step81-e2e-export/frontend/src/components/finance/FinanceTransactionsTable.vue
step81-e2e-export/frontend/src/services/financeService.ts
step81-e2e-export/frontend/src/views/finance/ExpensesView.vue
step81-e2e-export/frontend/src/views/finance/FinanceAIInsightsView.vue
step81-e2e-export/frontend/src/views/finance/FinanceAccountsView.vue
step81-e2e-export/frontend/src/views/finance/FinanceBudgetsView.vue
step81-e2e-export/frontend/src/views/finance/FinanceDashboardView.vue
step81-e2e-export/frontend/src/views/finance/FinanceTransactionsView.vue
step81-e2e-stabilization-patch/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-e2e-stabilization-patch/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step81-e2e-stabilization-patch/step81-e2e-stabilization-patch/backend/app/Http/Controllers/Api/FinanceAccountController.php
step81-e2e-stabilization-patch/step81-e2e-stabilization-patch/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step82-dashboard-performance-patch/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step82-dashboard-performance-patch/step82-dashboard-performance-patch/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/FinanceAccountController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/FinanceCategoryController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceAnomalyController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceForecastController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceAIInsightController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceAnomalyController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceBudgetController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceBudgetSummaryController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceForecastController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Finance/FinanceIntelligenceSettingController.php
step83-api-load-testing-export/backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/StoreFinanceAccountRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/StoreFinanceCategoryRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/StoreFinanceTransactionRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/UpdateFinanceAccountRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/UpdateFinanceCategoryRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/UpdateFinanceTransactionRequest.php
step83-api-load-testing-export/backend/app/Models/Finance/Expense.php
step83-api-load-testing-export/backend/app/Models/Finance/Income.php
step83-api-load-testing-export/backend/app/Models/FinanceAccount.php
step83-api-load-testing-export/backend/app/Models/FinanceBudget.php
step83-api-load-testing-export/backend/app/Models/FinanceBudgetLine.php
step83-api-load-testing-export/backend/app/Models/FinanceCategory.php
step83-api-load-testing-export/backend/app/Models/FinanceTransaction.php
step83-api-load-testing-export/backend/app/Services/Finance/BudgetCalculationService.php
step83-api-load-testing-export/backend/app/Services/FinanceAIInsightService.php
step83-api-load-testing-export/backend/app/Services/FinanceBalanceService.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_011800_create_finance_core_tables.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_012611_create_finance_core_tables.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_014144_add_description_to_finance_accounts_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_015954_fix_finance_transactions_missing_columns.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_020126_fix_finance_transactions_missing_columns.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_022137_create_or_fix_finance_budget_lines_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_04_023606_fix_finance_budget_tables_columns.php
step83-api-load-testing-export/backend/database/migrations/2026_05_06_011628_add_to_account_id_to_finance_transactions_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_06_015232_fix_finance_transactions_nullable_optional_columns.php
step83-api-load-testing-export/backend/database/migrations/2026_05_06_015607_fix_finance_transactions_insert_defaults.php
step83-api-load-testing-export/backend/database/migrations/disabled/create_finance_accounts_table.php
step83-api-load-testing-export/backend/database/migrations/disabled/create_finance_categories_table.php
step83-api-load-testing-export/backend/database/migrations/disabled/create_finance_transactions_table.php
step83-api-load-testing-export/backend/database/seeders/FinanceCategorySeeder.php
step83-api-load-testing-export/frontend/src/api/financeApi.js
step83-api-load-testing-export/frontend/src/components/finance/FinanceAIInsightsWidget.vue
step83-api-load-testing-export/frontend/src/components/finance/FinanceAddTransactionForm.vue
step83-api-load-testing-export/frontend/src/components/finance/FinanceBudgetProgress.vue
step83-api-load-testing-export/frontend/src/components/finance/FinanceDashboardCards.vue
step83-api-load-testing-export/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step83-api-load-testing-export/frontend/src/components/finance/FinanceTransactionsTable.vue
step83-api-load-testing-export/frontend/src/layouts/FinanceLayout.vue
step83-api-load-testing-export/frontend/src/services/financeService.ts
step83-api-load-testing-export/frontend/src/views/FinanceDashboardView.vue
step83-api-load-testing-export/frontend/src/views/finance/ExpensesView.vue
step83-api-load-testing-export/frontend/src/views/finance/FinanceAIInsightsView.vue
step83-api-load-testing-export/frontend/src/views/finance/FinanceAccountsView.vue
step83-api-load-testing-export/frontend/src/views/finance/FinanceBudgetsView.vue
step83-api-load-testing-export/frontend/src/views/finance/FinanceDashboardView.vue
step83-api-load-testing-export/frontend/src/views/finance/FinanceTransactionsView.vue
step85-frontend-build-optimization-export/frontend/src/api/financeApi.js
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceAIInsightsWidget.vue
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceAddTransactionForm.vue
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceBudgetProgress.vue
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceDashboardCards.vue
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step85-frontend-build-optimization-export/frontend/src/components/finance/FinanceTransactionsTable.vue
step85-frontend-build-optimization-export/frontend/src/layouts/FinanceLayout.vue
step85-frontend-build-optimization-export/frontend/src/services/financeService.ts
step85-frontend-build-optimization-export/frontend/src/views/FinanceDashboardView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/ExpensesView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/FinanceAIInsightsView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/FinanceAccountsView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/FinanceBudgetsView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/FinanceDashboardView.vue
step85-frontend-build-optimization-export/frontend/src/views/finance/FinanceTransactionsView.vue
step85-frontend-build-optimization-patch/frontend/src/views/finance/FinanceDashboardView.vue
step86-security-review-export/backend/app/Console/Commands/GenerateFinanceAlerts.php
step86-security-review-export/backend/app/Http/Controllers/Api/FinanceAccountController.php
step86-security-review-export/backend/app/Http/Controllers/Api/FinanceCategoryController.php
step86-security-review-export/backend/app/Http/Controllers/Api/FinanceTransactionController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceAnomalyController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceForecastController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php
step86-security-review-export/backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php
step86-security-review-export/backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php
step86-security-review-export/backend/app/Http/Requests/StoreFinanceAccountRequest.php
step86-security-review-export/backend/app/Http/Requests/StoreFinanceCategoryRequest.php
step86-security-review-export/backend/app/Http/Requests/StoreFinanceTransactionRequest.php
step86-security-review-export/backend/app/Http/Requests/UpdateFinanceAccountRequest.php
step86-security-review-export/backend/app/Http/Requests/UpdateFinanceCategoryRequest.php
step86-security-review-export/backend/app/Http/Requests/UpdateFinanceTransactionRequest.php
step86-security-review-export/backend/app/Http/Resources/Finance/FinanceAnomalyResource.php
step86-security-review-export/backend/app/Http/Resources/Finance/FinanceBudgetResource.php
step86-security-review-export/backend/app/Http/Resources/Finance/FinanceBudgetSummaryResource.php
step86-security-review-export/backend/app/Http/Resources/Finance/FinanceForecastSummaryResource.php
step86-security-review-export/backend/app/Http/Resources/Finance/FinanceIntelligenceSettingResource.php
step86-security-review-export/backend/app/Http/Resources/FinanceAccountResource.php
step86-security-review-export/backend/app/Http/Resources/FinanceCategoryResource.php
step86-security-review-export/backend/app/Http/Resources/FinanceTransactionResource.php
step86-security-review-export/backend/app/Models/Finance/Expense.php
step86-security-review-export/backend/app/Models/Finance/Income.php
step86-security-review-export/backend/app/Models/FinanceAccount.php
step86-security-review-export/backend/app/Models/FinanceBudget.php
step86-security-review-export/backend/app/Models/FinanceBudgetLine.php
step86-security-review-export/backend/app/Models/FinanceCategory.php
step86-security-review-export/backend/app/Models/FinanceTransaction.php
step86-security-review-export/backend/app/Services/Finance/BudgetCalculationService.php
step86-security-review-export/backend/app/Services/FinanceAIInsightService.php
step86-security-review-export/backend/app/Services/FinanceBalanceService.php
step86-security-review-export/backend/database/migrations/2026_05_04_011800_create_finance_core_tables.php
step86-security-review-export/backend/database/migrations/2026_05_04_012611_create_finance_core_tables.php
step86-security-review-export/backend/database/migrations/2026_05_04_014144_add_description_to_finance_accounts_table.php
step86-security-review-export/backend/database/migrations/2026_05_04_015954_fix_finance_transactions_missing_columns.php
step86-security-review-export/backend/database/migrations/2026_05_04_020126_fix_finance_transactions_missing_columns.php
step86-security-review-export/backend/database/migrations/2026_05_04_022137_create_or_fix_finance_budget_lines_table.php
step86-security-review-export/backend/database/migrations/2026_05_04_023606_fix_finance_budget_tables_columns.php
step86-security-review-export/backend/database/migrations/2026_05_06_011628_add_to_account_id_to_finance_transactions_table.php
step86-security-review-export/backend/database/migrations/2026_05_06_015232_fix_finance_transactions_nullable_optional_columns.php
step86-security-review-export/backend/database/migrations/2026_05_06_015607_fix_finance_transactions_insert_defaults.php
step86-security-review-export/backend/database/migrations/disabled/create_finance_accounts_table.php
step86-security-review-export/backend/database/migrations/disabled/create_finance_categories_table.php
step86-security-review-export/backend/database/migrations/disabled/create_finance_transactions_table.php
step86-security-review-export/backend/database/seeders/FinanceCategorySeeder.php
step86-security-review-export/frontend/src/api/financeApi.js
step86-security-review-export/frontend/src/components/finance/FinanceAIInsightsWidget.vue
step86-security-review-export/frontend/src/components/finance/FinanceAddTransactionForm.vue
step86-security-review-export/frontend/src/components/finance/FinanceBudgetProgress.vue
step86-security-review-export/frontend/src/components/finance/FinanceDashboardCards.vue
step86-security-review-export/frontend/src/components/finance/FinanceIncomeExpenseChart.vue
step86-security-review-export/frontend/src/components/finance/FinanceTransactionsTable.vue
step86-security-review-export/frontend/src/layouts/FinanceLayout.vue
step86-security-review-export/frontend/src/services/financeService.ts
step86-security-review-export/frontend/src/views/FinanceDashboardView.vue
step86-security-review-export/frontend/src/views/finance/ExpensesView.vue
step86-security-review-export/frontend/src/views/finance/FinanceAIInsightsView.vue
step86-security-review-export/frontend/src/views/finance/FinanceAccountsView.vue
step86-security-review-export/frontend/src/views/finance/FinanceBudgetsView.vue
step86-security-review-export/frontend/src/views/finance/FinanceDashboardView.vue
step86-security-review-export/frontend/src/views/finance/FinanceTransactionsView.vue
step86-security-small-export/backend-http/Controllers/Api/FinanceAccountController.php
step86-security-small-export/backend-http/Controllers/Api/FinanceCategoryController.php
step86-security-small-export/backend-http/Controllers/Api/FinanceTransactionController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceAIInsightController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceAnomalyController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceBudgetController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceForecastController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php
step86-security-small-export/backend-http/Requests/Finance/StoreFinanceBudgetRequest.php
step86-security-small-export/backend-http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php
step86-security-small-export/backend-http/Requests/StoreFinanceAccountRequest.php
step86-security-small-export/backend-http/Requests/StoreFinanceCategoryRequest.php
step86-security-small-export/backend-http/Requests/StoreFinanceTransactionRequest.php
step86-security-small-export/backend-http/Requests/UpdateFinanceAccountRequest.php
step86-security-small-export/backend-http/Requests/UpdateFinanceCategoryRequest.php
step86-security-small-export/backend-http/Requests/UpdateFinanceTransactionRequest.php
step86-security-small-export/backend-http/Resources/Finance/FinanceAnomalyResource.php
step86-security-small-export/backend-http/Resources/Finance/FinanceBudgetResource.php
step86-security-small-export/backend-http/Resources/Finance/FinanceBudgetSummaryResource.php
step86-security-small-export/backend-http/Resources/Finance/FinanceForecastSummaryResource.php
step86-security-small-export/backend-http/Resources/Finance/FinanceIntelligenceSettingResource.php
step86-security-small-export/backend-http/Resources/FinanceAccountResource.php
step86-security-small-export/backend-http/Resources/FinanceCategoryResource.php
step86-security-small-export/backend-http/Resources/FinanceTransactionResource.php
step86-security-small-export/backend-models/Finance/Expense.php
step86-security-small-export/backend-models/Finance/Income.php
step86-security-small-export/backend-models/FinanceAccount.php
step86-security-small-export/backend-models/FinanceBudget.php
step86-security-small-export/backend-models/FinanceBudgetLine.php
step86-security-small-export/backend-models/FinanceCategory.php
step86-security-small-export/backend-models/FinanceTransaction.php
step86-security-small-export/frontend-services/financeService.ts
step89_1_frontend_design_review/src/components/finance/FinanceAIInsightsWidget.vue
step89_1_frontend_design_review/src/components/finance/FinanceAddTransactionForm.vue
step89_1_frontend_design_review/src/components/finance/FinanceBudgetProgress.vue
step89_1_frontend_design_review/src/components/finance/FinanceDashboardCards.vue
step89_1_frontend_design_review/src/components/finance/FinanceIncomeExpenseChart.vue
step89_1_frontend_design_review/src/components/finance/FinanceTransactionsTable.vue
step89_1_frontend_design_review/src/layouts/FinanceLayout.vue
step89_1_frontend_design_review/src/views/FinanceDashboardView.vue
step89_1_frontend_design_review/src/views/finance/ExpensesView.vue
step89_1_frontend_design_review/src/views/finance/FinanceAIInsightsView.vue
step89_1_frontend_design_review/src/views/finance/FinanceAccountsView.vue
step89_1_frontend_design_review/src/views/finance/FinanceBudgetsView.vue
step89_1_frontend_design_review/src/views/finance/FinanceDashboardView.vue
step89_1_frontend_design_review/src/views/finance/FinanceTransactionsView.vue
storage/app/step83-load-results/20260517-233731/baseline_finance_accounts.txt
storage/app/step83-load-results/20260517-233731/baseline_finance_ai_insights.txt
storage/app/step83-load-results/20260517-233731/baseline_finance_budgets.txt
storage/app/step83-load-results/20260517-233731/baseline_finance_transactions.txt
storage/app/step83-load-results/20260517-233731/smoke_finance_accounts.txt
storage/app/step83-load-results/20260517-233731/smoke_finance_ai_insights.txt
storage/app/step83-load-results/20260517-233731/smoke_finance_budgets.txt
storage/app/step83-load-results/20260517-233731/smoke_finance_transactions.txt
storage/app/step83-load-results/20260517-233731/stress_finance_accounts.txt
storage/app/step83-load-results/20260517-233731/stress_finance_ai_insights.txt
storage/app/step83-load-results/20260517-233731/stress_finance_budgets.txt
storage/app/step83-load-results/20260517-233731/stress_finance_transactions.txt
storage/app/step83-load-results/20260517-235031/baseline_finance_accounts.txt
storage/app/step83-load-results/20260517-235031/baseline_finance_ai_insights.txt
storage/app/step83-load-results/20260517-235031/baseline_finance_budgets.txt
storage/app/step83-load-results/20260517-235031/baseline_finance_transactions.txt
storage/app/step83-load-results/20260517-235031/smoke_finance_accounts.txt
storage/app/step83-load-results/20260517-235031/smoke_finance_ai_insights.txt
storage/app/step83-load-results/20260517-235031/smoke_finance_budgets.txt
storage/app/step83-load-results/20260517-235031/smoke_finance_transactions.txt
storage/app/step83-load-results/20260517-235031/stress_finance_accounts.txt
storage/app/step83-load-results/20260517-235031/stress_finance_ai_insights.txt
storage/app/step83-load-results/20260517-235031/stress_finance_budgets.txt
storage/app/step83-load-results/20260517-235031/stress_finance_transactions.txt
storage/app/step83-load-results/20260518-000053/baseline_finance_accounts.txt
storage/app/step83-load-results/20260518-000053/baseline_finance_ai_insights.txt
storage/app/step83-load-results/20260518-000053/baseline_finance_budgets.txt
storage/app/step83-load-results/20260518-000053/baseline_finance_transactions.txt
storage/app/step83-load-results/20260518-000053/smoke_finance_accounts.txt
storage/app/step83-load-results/20260518-000053/smoke_finance_ai_insights.txt
storage/app/step83-load-results/20260518-000053/smoke_finance_budgets.txt
storage/app/step83-load-results/20260518-000053/smoke_finance_transactions.txt
storage/app/step83-load-results/20260518-000053/stress_finance_accounts.txt
storage/app/step83-load-results/20260518-000053/stress_finance_ai_insights.txt
storage/app/step83-load-results/20260518-000053/stress_finance_budgets.txt
storage/app/step83-load-results/20260518-000053/stress_finance_transactions.txt
```

## Finance References Detected
```text
api.php:18:use App\Http\Controllers\Api\FinanceAccountController;
api.php:19:use App\Http\Controllers\Api\FinanceTransactionController;
api.php:27:use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
api.php:243:        | Finance Module
api.php:247:        Route::prefix('finance')->group(function () {
api.php:248:            Route::get('/accounts', [FinanceAccountController::class, 'index']);
api.php:249:            Route::post('/accounts', [FinanceAccountController::class, 'store']);
api.php:250:            Route::get('/accounts/{id}', [FinanceAccountController::class, 'show']);
api.php:251:            Route::put('/accounts/{id}', [FinanceAccountController::class, 'update']);
api.php:252:            Route::patch('/accounts/{id}', [FinanceAccountController::class, 'update']);
api.php:253:            Route::delete('/accounts/{id}', [FinanceAccountController::class, 'destroy']);
api.php:255:            Route::get('/transactions', [FinanceTransactionController::class, 'index']);
api.php:256:            Route::post('/transactions', [FinanceTransactionController::class, 'store']);
api.php:257:            Route::get('/transactions/{id}', [FinanceTransactionController::class, 'show']);
api.php:258:            Route::put('/transactions/{id}', [FinanceTransactionController::class, 'update']);
api.php:259:            Route::patch('/transactions/{id}', [FinanceTransactionController::class, 'update']);
api.php:260:            Route::delete('/transactions/{id}', [FinanceTransactionController::class, 'destroy']);
api.php:262:            Route::get('/budgets', [FinanceBudgetController::class, 'index']);
api.php:263:            Route::post('/budgets', [FinanceBudgetController::class, 'store']);
api.php:264:            Route::get('/budgets/{id}', [FinanceBudgetController::class, 'show']);
api.php:265:            Route::put('/budgets/{id}', [FinanceBudgetController::class, 'update']);
api.php:266:            Route::patch('/budgets/{id}', [FinanceBudgetController::class, 'update']);
api.php:267:            Route::delete('/budgets/{id}', [FinanceBudgetController::class, 'destroy']);
backend/app/Console/Commands/GenerateExpenseReminders.php:31:                'finance'
backend/app/Console/Commands/GenerateFinanceAlerts.php:10:class GenerateFinanceAlerts extends Command
backend/app/Console/Commands/GenerateFinanceAlerts.php:12:    protected $signature = 'notifications:finance-alerts';
backend/app/Console/Commands/GenerateFinanceAlerts.php:14:    protected $description = 'Generate finance alert notifications';
backend/app/Console/Commands/GenerateFinanceAlerts.php:18:        $preferences = NotificationPreference::where('finance_alerts_enabled', true)->get();
backend/app/Console/Commands/GenerateFinanceAlerts.php:25:            $todayExpenses = DB::table('nix_life_os.finance_transaction')
backend/app/Console/Commands/GenerateFinanceAlerts.php:34:                    'finance_alert',
backend/app/Console/Commands/GenerateFinanceAlerts.php:38:                    'finance',
backend/app/Console/Commands/GenerateFinanceAlerts.php:47:        $this->info('Finance alerts generated successfully.');
backend/app/Console/Commands/GenerateLifeBalanceAlerts.php:35:                    'Your Life Balance score is ' . $latestScore->overall_score . '. Consider reviewing your health, finance, and productivity balance.',
backend/app/Console/Commands/RunPredictionModels.php:12:                            {--type=all : Prediction type: weight, finance, all}
backend/app/Console/Kernel.php:9:    $schedule->command('notifications:finance-alerts')->dailyAt('21:30');
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:50:        $financeTotals = $this->financeTotals();
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:69:                'finance' => $financeTotals,
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:76:    private function financeTotals(): array
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:78:        if (! Schema::hasTable('finance_transactions')) {
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:91:            'total_transactions' => DB::table('finance_transactions')->count(),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:92:            'total_income' => (float) DB::table('finance_transactions')->where('transaction_type', 'income')->sum('amount'),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:93:            'total_expenses' => (float) DB::table('finance_transactions')->where('transaction_type', 'expense')->sum('amount'),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:94:            'total_transfers' => (float) DB::table('finance_transactions')->where('transaction_type', 'transfer')->sum('amount'),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:95:            'total_accounts' => $this->tableCount('finance_accounts'),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:96:            'total_budgets' => $this->tableCount('finance_budgets'),
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:139:        if (Schema::hasTable('finance_categories')) {
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:140:            return DB::table('finance_categories')->count();
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:143:        if (Schema::hasTable('nix_life_os.finance_category')) {
backend/app/Http/Controllers/Api/Admin/AdminDashboardController.php:144:            return DB::table('nix_life_os.finance_category')->count();
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:408:                'message' => 'User finance and health dashboard loaded successfully.',
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:419:                    'finance' => $this->userFinanceDashboard($id),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:440:    private function userFinanceDashboard(string $userId): array
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:442:        $accounts = $this->countRows('finance_accounts', $userId);
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:443:        $transactions = $this->countRows('finance_transactions', $userId);
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:444:        $budgets = $this->countRows('finance_budgets', $userId);
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:445:        $categories = $this->countRows('finance_categories', $userId);
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:447:        $totalBalance = $this->sumRows('finance_accounts', $userId, 'current_balance');
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:453:        if ($this->hasTable('finance_transactions')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:454:            $income = (float) DB::table('finance_transactions')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:459:            $expenses = (float) DB::table('finance_transactions')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:464:            $transfers = (float) DB::table('finance_transactions')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:482:            'recent_accounts' => $this->recentRows('finance_accounts', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:483:            'recent_transactions' => $this->recentRows('finance_transactions', $userId, 8),
backend/app/Http/Controllers/Api/FinanceAccountController.php:13:class FinanceAccountController extends Controller
backend/app/Http/Controllers/Api/FinanceAccountController.php:19:        $accounts = DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceAccountController.php:28:            'message' => 'Finance accounts loaded successfully.',
backend/app/Http/Controllers/Api/FinanceAccountController.php:41:        $payload = $this->filterExistingColumns('finance_accounts', [
backend/app/Http/Controllers/Api/FinanceAccountController.php:56:        DB::table('finance_accounts')->insert($payload);
backend/app/Http/Controllers/Api/FinanceAccountController.php:62:            'message' => 'Finance account created successfully.',
backend/app/Http/Controllers/Api/FinanceAccountController.php:77:            'message' => 'Finance account loaded successfully.',
backend/app/Http/Controllers/Api/FinanceAccountController.php:93:        $payload = $this->filterExistingColumns('finance_accounts', [
backend/app/Http/Controllers/Api/FinanceAccountController.php:107:        DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceAccountController.php:114:            'message' => 'Finance account updated successfully.',
backend/app/Http/Controllers/Api/FinanceAccountController.php:127:        DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceAccountController.php:134:            'message' => 'Finance account deleted successfully.',
backend/app/Http/Controllers/Api/FinanceAccountController.php:180:        return DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceCategoryController.php:6:use App\Http\Requests\StoreFinanceCategoryRequest;
backend/app/Http/Controllers/Api/FinanceCategoryController.php:7:use App\Http\Requests\UpdateFinanceCategoryRequest;
backend/app/Http/Controllers/Api/FinanceCategoryController.php:8:use App\Models\FinanceCategory;
backend/app/Http/Controllers/Api/FinanceCategoryController.php:12:class FinanceCategoryController extends Controller
backend/app/Http/Controllers/Api/FinanceCategoryController.php:16:        $categories = FinanceCategory::query()
backend/app/Http/Controllers/Api/FinanceCategoryController.php:25:    public function store(StoreFinanceCategoryRequest $request): JsonResponse
backend/app/Http/Controllers/Api/FinanceCategoryController.php:27:        $category = FinanceCategory::query()->create([
backend/app/Http/Controllers/Api/FinanceCategoryController.php:43:        $category = FinanceCategory::query()
backend/app/Http/Controllers/Api/FinanceCategoryController.php:50:    public function update(UpdateFinanceCategoryRequest $request, string $categoryId): JsonResponse
backend/app/Http/Controllers/Api/FinanceCategoryController.php:52:        $category = FinanceCategory::query()
backend/app/Http/Controllers/Api/FinanceCategoryController.php:63:        $category = FinanceCategory::query()
backend/app/Http/Controllers/Api/FinanceTransactionController.php:13:class FinanceTransactionController extends Controller
backend/app/Http/Controllers/Api/FinanceTransactionController.php:22:        $base = DB::table('finance_transactions')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:39:        $accountBalance = DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:49:            'message' => 'Finance summary loaded successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:65:        $query = DB::table('finance_transactions as t')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:66:            ->leftJoin('finance_accounts as a', 'a.id', '=', 't.account_id')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:67:            ->leftJoin('finance_accounts as ta', 'ta.id', '=', 't.transfer_account_id')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:97:            'message' => 'Finance transactions loaded successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:135:            $categoryName = DB::table('finance_categories')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:149:            $payload = $this->filterExistingColumns('finance_transactions', [
backend/app/Http/Controllers/Api/FinanceTransactionController.php:172:            DB::table('finance_transactions')->insert($payload);
backend/app/Http/Controllers/Api/FinanceTransactionController.php:186:            'message' => 'Finance transaction created successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:194:            return $this->notFound('Invalid finance transaction id.');
backend/app/Http/Controllers/Api/FinanceTransactionController.php:205:            'message' => 'Finance transaction loaded successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:213:            return $this->notFound('Invalid finance transaction id.');
backend/app/Http/Controllers/Api/FinanceTransactionController.php:226:            $categoryName = DB::table('finance_categories')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:272:            $payload = $this->filterExistingColumns('finance_transactions', [
backend/app/Http/Controllers/Api/FinanceTransactionController.php:292:            DB::table('finance_transactions')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:302:            'message' => 'Finance transaction updated successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:310:            return $this->notFound('Invalid finance transaction id.');
backend/app/Http/Controllers/Api/FinanceTransactionController.php:329:            DB::table('finance_transactions')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:337:            'message' => 'Finance transaction deleted successfully.',
backend/app/Http/Controllers/Api/FinanceTransactionController.php:390:        return DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:402:        return DB::table('finance_transactions as t')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:403:            ->leftJoin('finance_accounts as a', 'a.id', '=', 't.account_id')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:404:            ->leftJoin('finance_accounts as ta', 'ta.id', '=', 't.transfer_account_id')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:465:        DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:483:            $account = DB::table('finance_accounts')
backend/app/Http/Controllers/Api/FinanceTransactionController.php:496:            $transferAccount = DB::table('finance_accounts')
backend/app/Http/Controllers/Api/LifeBalanceController.php:35:                    $financeScore = $this->calculateFinanceScore($userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:42:                $financeScore +
backend/app/Http/Controllers/Api/LifeBalanceController.php:51:                        'finance_score' => $financeScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:57:                            $financeScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:89:                    'finance_score' => 0,
backend/app/Http/Controllers/Api/LifeBalanceController.php:100:    private function calculateFinanceScore(string $userId): int
backend/app/Http/Controllers/Api/LifeBalanceController.php:103:            $accountsCount = $this->safeCount('finance_accounts', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:104:            $transactionsCount = $this->safeCount('finance_transactions', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:105:            $budgetsCount = $this->safeCount('finance_budgets', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:220:            $financeCount = $this->safeCount('finance_transactions', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:226:            if ($financeCount > 0) {
backend/app/Http/Controllers/Api/LifeBalanceController.php:269:        int $financeScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:277:        if ($financeScore >= 70) {
backend/app/Http/Controllers/Api/LifeBalanceController.php:278:            $recommendations[] = 'Finance balance looks stable.';
backend/app/Http/Controllers/Api/LifeBalanceController.php:280:            $recommendations[] = 'Add more finance accounts, transactions, and budgets to improve financial visibility.';
backend/app/Http/Controllers/Api/LifeBalanceController.php:300:            $recommendations[] = 'Try to update finance, health, and project data every day for better consistency.';
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:47:            'finance_alerts_enabled' => ['nullable', 'boolean'],
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:67:            'finance_alerts_enabled' => true,
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:124:            'finance_alerts_enabled' => true,
backend/app/Http/Controllers/Api/V1/AiPredictionController.php:39:        $finance = AiPrediction::where('user_id', $user->id)
backend/app/Http/Controllers/Api/V1/AiPredictionController.php:48:                'financial_forecast' => $finance,
backend/app/Http/Controllers/Api/V1/AiPredictionController.php:56:            'type' => ['nullable', 'in:weight,finance,all'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:41:                $finance = $this->financeSummary($userId, $monthStart, $monthEnd);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:46:                    'finance' => $finance,
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:52:                    'accounts_count' => $finance['accounts_count'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:53:                    'total_balance' => $finance['total_balance'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:54:                    'income' => $finance['monthly_income'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:55:                    'monthly_income' => $finance['monthly_income'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:56:                    'monthly_expense' => $finance['monthly_expense'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:57:                    'savings_rate' => $finance['savings_rate'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:97:    private function financeSummary(string $userId, string $monthStart, string $monthEnd): array
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:99:        $accountsTable = $this->firstExistingTable(['finance_accounts', 'finance_account']);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:100:        $transactionsTable = $this->firstExistingTable(['finance_transactions', 'finance_transaction']);
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:16:        $totalBalance = $this->tableExists('finance_accounts')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:17:            ? DB::table('finance_accounts')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:22:        $monthlyIncome = $this->tableExists('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:23:            ? DB::table('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:31:        $monthlyExpense = $this->tableExists('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:32:            ? DB::table('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:110:                'finance' => [
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:136:        $financeRows = $this->tableExists('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:137:            ? DB::table('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:200:                'finance_chart' => [
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:201:                    'labels' => $financeRows->pluck('label')->values(),
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:202:                    'values' => $financeRows->pluck('value')->map(fn ($v) => round((float) $v, 2))->values(),
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:226:        if ($this->tableExists('finance_transactions')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:227:            $financeActivities = DB::table('finance_transactions')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:236:                        'id' => 'finance-' . $item->id,
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:237:                        'type' => 'finance',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:238:                        'title' => 'Finance transaction recorded',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:246:            $activities = $activities->merge($financeActivities);
backend/app/Http/Controllers/Api/V1/Finance/BudgetAlertRuleController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:6:use App\Services\FinanceAIInsightService;
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:11:class FinanceAIInsightController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:14:        private readonly FinanceAIInsightService $financeAIInsightService
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:25:            $data = $this->financeAIInsightService->generate(
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:35:                    ? 'Finance AI insights generated successfully.'
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:36:                    : 'No finance data available yet.',
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:40:            Log::error('Finance AI insights generation failed', [
backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php:49:                'message' => 'Failed to generate Finance AI insights.',
backend/app/Http/Controllers/Api/V1/Finance/FinanceAnomalyController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceAnomalyController.php:9:class FinanceAnomalyController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:6:use App\Models\FinanceBudget;
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:7:use App\Models\FinanceBudgetLine;
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:13:class FinanceBudgetController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:86:        $query = FinanceBudget::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:139:            $budget = FinanceBudget::query()->create([
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:154:                FinanceBudgetLine::query()->create([
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:186:        $budget = FinanceBudget::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:212:            $budget = FinanceBudget::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:239:            FinanceBudgetLine::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:244:                FinanceBudgetLine::query()->create([
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:276:        $budget = FinanceBudget::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php:289:            FinanceBudgetLine::query()
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetSummaryController.php:9:class FinanceBudgetSummaryController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceForecastController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceForecastController.php:9:class FinanceForecastController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php:3:namespace App\Http\Controllers\Api\V1\Finance;
backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php:9:class FinanceIntelligenceSettingController extends Controller
backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php:15:            'message' => 'Finance intelligence settings retrieved successfully',
backend/app/Http/Controllers/Api/V1/Finance/FinanceIntelligenceSettingController.php:24:            'message' => 'Finance intelligence settings updated successfully',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:12:class FinanceCategoryController extends Controller
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:21:                'message' => 'Finance categories table is not available yet.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:57:            'message' => 'Finance categories loaded successfully.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:69:                'message' => 'Finance categories table is not available yet.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:109:            'message' => 'Finance category created successfully.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:124:            'message' => 'Finance category loaded successfully.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:173:            'message' => 'Finance category updated successfully.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:191:            'message' => 'Finance category deleted successfully.',
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:246:        if (Schema::hasTable('finance_categories')) {
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:247:            return 'finance_categories';
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:250:        if (Schema::hasTable('finance_category')) {
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:251:            return 'finance_category';
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:254:        if (Schema::hasTable('nix_life_os.finance_category')) {
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:255:            return 'nix_life_os.finance_category';
backend/app/Http/Controllers/Api/V1/FinanceCategoryController.php:277:            'message' => 'Finance category not found.',
backend/app/Http/Controllers/Api/V1/NotificationPreferenceController.php:46:            'finance_alerts_enabled' => ['nullable', 'boolean'],
backend/app/Http/Controllers/Api/V1/NotificationPreferenceController.php:70:            'finance_alerts_enabled' => true,
backend/app/Http/Controllers/Api/V1/NotificationPreferenceController.php:121:            'finance_alerts_enabled' => true,
backend/app/Http/Controllers/Api/V1/ReportController.php:19:                'finance' => $this->financeData($request),
backend/app/Http/Controllers/Api/V1/ReportController.php:27:    public function finance(Request $request): JsonResponse
backend/app/Http/Controllers/Api/V1/ReportController.php:31:            'message' => 'Finance report loaded successfully.',
backend/app/Http/Controllers/Api/V1/ReportController.php:32:            'data' => $this->financeData($request),
backend/app/Http/Controllers/Api/V1/ReportController.php:54:    private function financeData(Request $request): array
backend/app/Http/Controllers/Api/V1/ReportController.php:59:            'accounts_count' => $this->count('finance_accounts', $userId),
backend/app/Http/Controllers/Api/V1/ReportController.php:60:            'transactions_count' => $this->count('finance_transactions', $userId),
backend/app/Http/Controllers/Api/V1/ReportController.php:61:            'budgets_count' => $this->count('finance_budgets', $userId),
backend/app/Http/Controllers/Api/V1/ReportController.php:62:            'total_balance' => $this->sum('finance_accounts', 'current_balance', $userId),
backend/app/Http/Controllers/Api/V1/ReportController.php:114:        if (!Schema::hasTable('finance_transactions')) {
backend/app/Http/Controllers/Api/V1/ReportController.php:118:        return (float) DB::table('finance_transactions')
backend/app/Http/Controllers/ExpenseController.php:5:use App\Models\Finance\Expense;
backend/app/Http/Controllers/FinanceCategoryController.php:5:use App\Http\Requests\StoreFinanceCategoryRequest;
backend/app/Http/Controllers/FinanceCategoryController.php:6:use App\Http\Requests\UpdateFinanceCategoryRequest;
backend/app/Http/Controllers/FinanceCategoryController.php:7:use App\Models\FinanceCategory;
backend/app/Http/Controllers/FinanceCategoryController.php:9:class FinanceCategoryController extends Controller
backend/app/Http/Controllers/FinanceCategoryController.php:30:    public function store(StoreFinanceCategoryRequest $request)
backend/app/Http/Controllers/FinanceCategoryController.php:38:    public function show(FinanceCategory $financeCategory)
backend/app/Http/Controllers/FinanceCategoryController.php:46:    public function edit(FinanceCategory $financeCategory)
backend/app/Http/Controllers/FinanceCategoryController.php:54:    public function update(UpdateFinanceCategoryRequest $request, FinanceCategory $financeCategory)
backend/app/Http/Controllers/FinanceCategoryController.php:62:    public function destroy(FinanceCategory $financeCategory)
backend/app/Http/Controllers/IncomeController.php:5:use App\Models\Finance\Income;
backend/app/Http/Middleware/ApiAuditLogger.php:39:        if (str_contains($path, 'finance')) {
backend/app/Http/Middleware/ApiAuditLogger.php:40:            return 'finance';
backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php:3:namespace App\Http\Requests\Finance;
backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php:7:class StoreFinanceBudgetRequest extends FormRequest
backend/app/Http/Requests/Finance/StoreFinanceBudgetRequest.php:27:            'lines.*.account_id' => ['nullable', 'uuid', 'exists:finance_accounts,id'],
backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php:3:namespace App\Http\Requests\Finance;
backend/app/Http/Requests/Finance/UpdateFinanceIntelligenceSettingRequest.php:7:class UpdateFinanceIntelligenceSettingRequest extends FormRequest
backend/app/Http/Requests/StoreFinanceAccountRequest.php:9:class StoreFinanceAccountRequest extends FormRequest
backend/app/Http/Requests/StoreFinanceCategoryRequest.php:8:class StoreFinanceCategoryRequest extends FormRequest
backend/app/Http/Requests/StoreFinanceTransactionRequest.php:8:class StoreFinanceTransactionRequest extends FormRequest
backend/app/Http/Requests/UpdateFinanceAccountRequest.php:9:class UpdateFinanceAccountRequest extends FormRequest
backend/app/Http/Requests/UpdateFinanceCategoryRequest.php:8:class UpdateFinanceCategoryRequest extends FormRequest
backend/app/Http/Requests/UpdateFinanceTransactionRequest.php:5:class UpdateFinanceTransactionRequest extends StoreFinanceTransactionRequest
backend/app/Http/Resources/Finance/FinanceForecastSummaryResource.php:3:namespace App\Http\Resources\Finance;
backend/app/Http/Resources/Finance/FinanceForecastSummaryResource.php:8:class FinanceForecastSummaryResource extends JsonResource
backend/app/Http/Resources/FinanceAccountResource.php:8:class FinanceAccountResource extends JsonResource
backend/app/Http/Resources/FinanceCategoryResource.php:8:class FinanceCategoryResource extends JsonResource
backend/app/Http/Resources/FinanceTransactionResource.php:9:class FinanceTransactionResource extends JsonResource
backend/app/Models/AIRecommendation.php:83:    public const MODULE_FINANCE = 'finance';
backend/app/Models/AIRecommendation.php:357:            self::MODULE_FINANCE => 'Finance',
backend/app/Models/AIRecommendationRule.php:59:    public const MODULE_FINANCE = 'finance';
backend/app/Models/AIRecommendationRule.php:181:            self::MODULE_FINANCE => 'Finance',
backend/app/Models/AIUserDailyScore.php:25:        'finance_score',
backend/app/Models/AIUserDailyScore.php:39:        'finance_score' => 'decimal:2',
backend/app/Models/AIUserDailyScore.php:135:            'finance' => (float) $this->finance_score,
backend/app/Models/AIUserDailyScore.php:150:            'finance' => (float) $this->finance_score,
backend/app/Models/AiReport.php:21:        'finance_summary',
backend/app/Models/AiReport.php:32:        'finance_summary' => 'array',
backend/app/Models/Finance/Expense.php:3:namespace App\Models\Finance;
backend/app/Models/Finance/Income.php:3:namespace App\Models\Finance;
backend/app/Models/FinanceAccount.php:10:class FinanceAccount extends Model
backend/app/Models/FinanceAccount.php:14:    protected $table = 'finance_accounts';
backend/app/Models/FinanceBudget.php:8:class FinanceBudget extends Model
backend/app/Models/FinanceBudget.php:10:    protected $table = 'finance_budgets';
backend/app/Models/FinanceBudget.php:39:        return $this->hasMany(FinanceBudgetLine::class, 'budget_id', 'id');
backend/app/Models/FinanceBudgetLine.php:8:class FinanceBudgetLine extends Model
backend/app/Models/FinanceBudgetLine.php:10:    protected $table = 'finance_budget_lines';
backend/app/Models/FinanceBudgetLine.php:44:        return $this->belongsTo(FinanceBudget::class, 'budget_id', 'id');
backend/app/Models/FinanceCategory.php:8:class FinanceCategory extends Model
backend/app/Models/FinanceCategory.php:12:    protected $table = 'nix_life_os.finance_category';
backend/app/Models/FinanceTransaction.php:9:class FinanceTransaction extends Model
backend/app/Models/FinanceTransaction.php:14:    protected $table = 'finance_transactions';
backend/app/Models/FinanceTransaction.php:45:        return $this->belongsTo(FinanceAccount::class, 'account_id', 'id');
backend/app/Models/LifeBalanceScore.php:15:        'finance_score',
backend/app/Models/LifeBalanceScore.php:20:        'finance_breakdown',
backend/app/Models/LifeBalanceScore.php:28:        'finance_breakdown' => 'array',
backend/app/Models/NotificationPreference.php:28:        'finance_alerts_enabled',
backend/app/Models/NotificationPreference.php:42:        'finance_alerts_enabled' => 'boolean',
backend/app/Models/Plan.php:18:        'max_finance_accounts',
backend/app/Models/Plan.php:22:        'finance_module_enabled',
backend/app/Models/Plan.php:37:        'finance_module_enabled' => 'boolean',
backend/app/Models/SubscriptionUsage.php:18:        'finance_accounts_count',
backend/app/Policies/FinanceCategoryPolicy.php:5:use App\Models\FinanceCategory;
backend/app/Policies/FinanceCategoryPolicy.php:9:class FinanceCategoryPolicy
backend/app/Policies/FinanceCategoryPolicy.php:22:    public function view(User $user, FinanceCategory $financeCategory): bool
backend/app/Policies/FinanceCategoryPolicy.php:38:    public function update(User $user, FinanceCategory $financeCategory): bool
backend/app/Policies/FinanceCategoryPolicy.php:46:    public function delete(User $user, FinanceCategory $financeCategory): bool
backend/app/Policies/FinanceCategoryPolicy.php:54:    public function restore(User $user, FinanceCategory $financeCategory): bool
backend/app/Policies/FinanceCategoryPolicy.php:62:    public function forceDelete(User $user, FinanceCategory $financeCategory): bool
backend/app/Services/AI/RecommendationRuleService.php:117:                'finance_score' => $scoreResult['finance_score'],
```
