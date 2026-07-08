# Health Module Inventory

Health Module must remain unchanged.

## Protected Rule

No Health routes, APIs, models, controllers, pages, components, UI, or logic were changed in Bundle 1.

## Health Files Detected
```text
"STEP 45 \342\200\224 Health Module Stabilization.bash"
"STEP 52 \342\200\224 Health Alerts Engine.bash"
"STEP 53 \342\200\224 Health Reports Screen.bash"
analytics/app/schemas/health_analytics_schema.py
analytics/app/services/health_analytics_service.py
backend/app/Console/Commands/RunHealthAlertsEngine.php
backend/app/Console/Commands/RunSystemHealthCheck.php
backend/app/Exports/HealthReportExport.php
backend/app/Http/Controllers/Api/HealthNutritionLogController.php
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php
backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php
backend/app/Http/Controllers/Api/V1/Health/HealthMealLogController.php
backend/app/Http/Controllers/Api/V1/Health/HealthMoodLogController.php
backend/app/Http/Controllers/Api/V1/Health/HealthNutritionProfileController.php
backend/app/Http/Controllers/Api/V1/Health/HealthNutritionSummaryController.php
backend/app/Http/Controllers/Api/V1/Health/HealthProfileController.php
backend/app/Http/Controllers/Api/V1/Health/HealthSportController.php
backend/app/Http/Controllers/Api/V1/Health/HealthStepLogController.php
backend/app/Http/Controllers/Api/V1/Health/HydrationReminderController.php
backend/app/Http/Controllers/Api/V1/Health/MedicationController.php
backend/app/Http/Controllers/Api/V1/Health/MedicationDoseController.php
backend/app/Http/Controllers/Api/V1/Health/MedicationReminderController.php
backend/app/Http/Controllers/Api/V1/Health/SleepLogController.php
backend/app/Http/Controllers/Api/V1/HealthAlertController.php
backend/app/Http/Controllers/Api/V1/HealthDashboardController.php
backend/app/Http/Controllers/Api/V1/HealthGoalController.php
backend/app/Http/Controllers/Api/V1/HealthHydrationController.php
backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php
backend/app/Http/Controllers/Api/V1/HealthLabTestController.php
backend/app/Http/Controllers/Api/V1/HealthMedicationController.php
backend/app/Http/Controllers/Api/V1/HealthMoodController.php
backend/app/Http/Controllers/Api/V1/HealthReportController.php
backend/app/Http/Controllers/Api/V1/HealthSleepController.php
backend/app/Http/Controllers/Api/V1/HealthStepController.php
backend/app/Http/Controllers/Api/V1/HealthWaterController.php
backend/app/Http/Controllers/Api/V1/HealthWeightController.php
backend/app/Http/Controllers/Api/V1/HealthWeightLogController.php
backend/app/Http/Controllers/HealthMedicationController.php
backend/app/Http/Controllers/HealthWeightLogController.php
backend/app/Http/Requests/StoreHealthHydrationLogRequest.php
backend/app/Http/Requests/StoreHealthMedicationRequest.php
backend/app/Http/Requests/StoreHealthMoodLogRequest.php
backend/app/Http/Requests/StoreHealthSleepLogRequest.php
backend/app/Http/Requests/StoreHealthWeightLogRequest.php
backend/app/Http/Requests/UpdateHealthHydrationLogRequest.php
backend/app/Http/Requests/UpdateHealthMedicationRequest.php
backend/app/Http/Requests/UpdateHealthMoodLogRequest.php
backend/app/Http/Requests/UpdateHealthSleepLogRequest.php
backend/app/Http/Requests/UpdateHealthWeightLogRequest.php
backend/app/Http/Resources/HealthFoodItemResource.php
backend/app/Http/Resources/HealthHydrationLogResource.php
backend/app/Http/Resources/HealthMealLogItemResource.php
backend/app/Http/Resources/HealthMealLogResource.php
backend/app/Http/Resources/HealthMealResource.php
backend/app/Http/Resources/HealthNutritionProfileResource.php
backend/app/Http/Resources/HealthProfileResource.php
backend/app/Http/Resources/HealthReportResource.php
backend/app/Http/Resources/HealthStepLogResource.php
backend/app/Http/Resources/HealthWeightLogResource.php
backend/app/Jobs/CheckHealthWarningsJob.php
backend/app/Models/Health/CalorieEntry.php
backend/app/Models/Health/StepEntry.php
backend/app/Models/Health/WeightEntry.php
backend/app/Models/HealthAlert.php
backend/app/Models/HealthAlertRule.php
backend/app/Models/HealthFoodItem.php
backend/app/Models/HealthHydrationLog.php
backend/app/Models/HealthLabTest.php
backend/app/Models/HealthLabTestResult.php
backend/app/Models/HealthMealLog.php
backend/app/Models/HealthMealLogItem.php
backend/app/Models/HealthMedication.php
backend/app/Models/HealthMedicationDoseLog.php
backend/app/Models/HealthMedicationReminder.php
backend/app/Models/HealthMedicationTime.php
backend/app/Models/HealthMoodLog.php
backend/app/Models/HealthNutritionLog.php
backend/app/Models/HealthNutritionProfile.php
backend/app/Models/HealthProfile.php
backend/app/Models/HealthSleepLog.php
backend/app/Models/HealthSport.php
backend/app/Models/HealthStep.php
backend/app/Models/HealthStepLog.php
backend/app/Models/HealthTestCategory.php
backend/app/Models/HealthUserGoal.php
backend/app/Models/HealthWaterLog.php
backend/app/Models/HealthWeightLog.php
backend/app/Policies/HealthMedicationPolicy.php
backend/app/Policies/HealthMoodLogPolicy.php
backend/app/Policies/HealthSleepLogPolicy.php
backend/app/Policies/HealthWeightLogPolicy.php
backend/app/Services/Health/HealthAIInsightService.php
backend/app/Services/Health/HealthAlertEngineService.php
backend/app/Services/Health/HealthReportService.php
backend/app/Services/Notifications/HealthNotificationService.php
backend/core[health_score],
backend/database/factories/HealthMedicationFactory.php
backend/database/factories/HealthMoodLogFactory.php
backend/database/factories/HealthSleepLogFactory.php
backend/database/factories/HealthWeightLogFactory.php
backend/database/migrations/2026_04_24_081534_create_health_profiles_table.php
backend/database/migrations/2026_04_24_081534_create_health_step_logs_table.php
backend/database/migrations/2026_04_26_015704_create_health_meal_logs_table.php
backend/database/migrations/2026_04_26_015705_create_health_food_items_table.php
backend/database/migrations/2026_04_26_015705_create_health_meal_log_items_table.php
backend/database/migrations/2026_04_26_015705_create_health_nutrition_profiles_table.php
backend/database/migrations/2026_04_26_040332_create_health_hydration_logs_table.php
backend/database/migrations/2026_05_07_214204_create_health_nutrition_logs_table.php
backend/database/migrations/2026_05_09_141443_add_daily_dose_and_dose_times_to_health_medications_table.php
backend/database/migrations/2026_05_09_141651_create_health_lab_tests_table.php
backend/database/migrations/2026_05_10_113754_add_custom_food_id_to_health_nutrition_logs_table.php
backend/database/migrations/2026_05_10_175906_add_ckd_fields_to_health_lab_tests_table.php
backend/database/migrations/2026_05_10_180203_add_ckd_fields_to_health_lab_tests_table.php
backend/database/migrations/2026_05_10_190351_create_health_medication_reminders_table.php
backend/database/migrations/2026_05_10_190352_create_health_medication_dose_logs_table.php
backend/database/migrations/2026_05_10_200003_upgrade_health_lab_tests_for_step_51.php
backend/database/migrations/2026_05_10_201805_upgrade_health_lab_tests_for_step_51.php
backend/database/migrations/2026_05_10_210000_add_ckd_fields_to_health_lab_tests_table.php
backend/database/migrations/2026_05_10_214636_create_health_alerts_table.php
backend/database/migrations/2026_05_10_214724_create_health_alert_rules_table.php
backend/database/migrations/2026_05_10_232815_add_status_to_health_lab_tests_table.php
backend/database/migrations/2026_05_25_232219_create_health_metrics_compatibility_table.php
backend/database/migrations/2026_06_07_191500_upgrade_health_module_full_updates.php
backend/database/migrations/2026_06_08_000006_create_or_update_health_hydration_logs_table.php
backend/database/migrations/2026_06_09_090001_create_health_test_categories_table.php
backend/database/migrations/2026_06_09_090002_create_health_lab_tests_table.php
backend/database/migrations/2026_06_09_090003_create_health_lab_test_results_table.php
backend/database/migrations/2026_06_10_230000_create_health_weight_logs_table.php
backend/database/migrations/2026_06_10_230500_fix_health_medications_user_id_uuid.php
backend/database/migrations/2026_06_14_130000_create_health_sleep_logs_table_if_missing.php
backend/database/migrations/2026_06_14_130100_create_health_mood_logs_table_if_missing.php
backend/database/migrations/2026_06_14_131500_repair_health_sleep_mood_logs_schema.php
backend/database/migrations/2026_06_14_132000_recreate_health_sleep_mood_uuid_ids_if_empty.php
backend/database/migrations/2026_06_14_140000_repair_health_medications_schema.php
backend/database/migrations/2026_06_14_141000_repair_health_medications_report_pdf_columns.php
backend/database/migrations/2026_06_14_231000_fix_health_alerts_source_id_text.php
backend/database/migrations/2026_06_16_203900_create_health_sleep_logs_table_if_missing.php
backend/database/migrations/2026_06_16_213000_create_health_mood_logs_table_if_missing.php
backend/database/migrations/2026_06_16_214500_create_health_medication_times_table_if_missing.php
backend/database/migrations/2026_06_20_095500_add_height_columns_to_health_weight_logs_table.php
backend/database/migrations/2026_06_20_102500_repair_health_sleep_logs_active_schema.php
backend/database/migrations/2026_06_20_105500_add_name_column_to_health_medications_table.php
backend/database/migrations/2026_06_22_174000_create_health_sports_table.php
backend/database/migrations_disabled_existing_tables/2026_04_26_011352_create_health_weight_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_09_091704_create_health_sleep_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_09_120356_create_health_mood_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_09_131453_create_health_medications_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_medications_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_mood_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_sleep_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_steps_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_water_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_040709_create_health_weight_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_041516_create_health_weight_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_041521_create_health_sleep_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_041527_create_health_mood_logs_table.php
backend/database/migrations_disabled_existing_tables/2026_05_30_041532_create_health_medications_table.php
backend/database/seeders/HealthMedicationSeeder.php
backend/database/seeders/HealthMoodLogSeeder.php
backend/database/seeders/HealthSleepLogSeeder.php
backend/database/seeders/HealthWeightLogSeeder.php
backend/resources/views/pdf/health-report.blade.php
backend/ult[health_score],
backups/manual-fix-patches/before_dashboard_finance_health_fix_20260616_184610.patch
backups/monitoring/archive/health-check-corrupted-before-step90-15-20260520_065302.log
backups/monitoring/health-check.log
backups/step-sport-section-20260622_173445/HealthDashboard.vue
backups/step-sport-section-20260622_173445/healthService.js
backups/step54_health_regression_20260511_222855/HealthDashboardController.php
backups/step54_health_regression_20260511_222855/HealthHydrationLogController.php
backups/step54_health_regression_20260511_222855/api.php
backups/step54_health_regression_20260511_222855/healthReportsService.js
backups/step54_health_regression_20260511_222855/healthService.js
backups/step54_health_regression_20260511_222855/healthWeightApi.js
backups/step82-dashboard-performance-20260517-224851/backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
backups/step90-6-frontend-api-cleanup/src-backup/components/health/HealthAlertsPanel.vue
backups/step90-6-frontend-api-cleanup/src-backup/services/healthAlertService.js
backups/step90-6-frontend-api-cleanup/src-backup/services/healthReportsService.js
backups/step90-6-frontend-api-cleanup/src-backup/services/healthService.js
backups/step90-6-frontend-api-cleanup/src-backup/services/healthWeightApi.js
backups/step90-6-frontend-api-cleanup/src-backup/src/components/health/HealthAlertsPanel.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/services/healthAlertService.js
backups/step90-6-frontend-api-cleanup/src-backup/src/services/healthReportsService.js
backups/step90-6-frontend-api-cleanup/src-backup/src/services/healthService.js
backups/step90-6-frontend-api-cleanup/src-backup/src/services/healthWeightApi.js
backups/step90-6-frontend-api-cleanup/src-backup/src/views/HealthHydrationView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/CustomFoodsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthAIInsightsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthAlertsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthNutritionView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthReportsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthStepsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HealthWeightView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/HydrationTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/LabTestsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/MedicamentsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/MedicationTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/MoodTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/NutritionTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/SleepTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/StepsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/WeightTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/nutrition/FoodItemsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/nutrition/MealLoggerView.vue
backups/step90-6-frontend-api-cleanup/src-backup/src/views/health/nutrition/NutritionDashboardView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/HealthHydrationView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/CustomFoodsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthAIInsightsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthAlertsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthNutritionView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthReportsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthStepsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HealthWeightView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/HydrationTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/LabTestsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/MedicamentsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/MedicationTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/MoodTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/NutritionTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/SleepTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/StepsTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/WeightTrackingView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/nutrition/FoodItemsView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/nutrition/MealLoggerView.vue
backups/step90-6-frontend-api-cleanup/src-backup/views/health/nutrition/NutritionDashboardView.vue
docker-compose.prod.yml.step87-healthcheck-backup
docker-compose.prod.yml.step87-nginx-health-final-backup
export-step69-health-ai-files.sh
export_step54_health_files.sh
frontend/src/components/health/HealthAlertsPanel.vue
frontend/src/components/health/HealthQuickActionModal.vue
frontend/src/services/healthAlertService.js
frontend/src/services/healthReportsService.js
frontend/src/services/healthService.js
frontend/src/services/healthService.ts
frontend/src/services/healthWeightApi.js
frontend/src/views/HealthHydrationView.vue
frontend/src/views/health/CustomFoodsView.vue
frontend/src/views/health/HealthAIInsightsView.vue
frontend/src/views/health/HealthAlertsView.vue
frontend/src/views/health/HealthDashboard.vue
frontend/src/views/health/HealthNutritionView.vue
frontend/src/views/health/HealthReportsView.vue
frontend/src/views/health/HealthStepsView.vue
frontend/src/views/health/HealthView.vue
frontend/src/views/health/HealthWeightView.vue
frontend/src/views/health/HydrationTrackingView.vue
frontend/src/views/health/HydrationView.vue
frontend/src/views/health/LabTestPreviewView.vue
frontend/src/views/health/LabTestUploadView.vue
frontend/src/views/health/LabTestsTrackingView.vue
frontend/src/views/health/LabTestsView.vue
frontend/src/views/health/MedicamentsTrackingView.vue
frontend/src/views/health/MedicationTrackingView.vue
frontend/src/views/health/MoodTrackingView.vue
frontend/src/views/health/NutritionTrackingView.vue
frontend/src/views/health/SleepTrackingView.vue
frontend/src/views/health/SportTrackingView.vue
frontend/src/views/health/StepsTrackingView.vue
frontend/src/views/health/StepsView.vue
frontend/src/views/health/WeightTrackingView.vue
frontend/src/views/health/nutrition/FoodItemsView.vue
frontend/src/views/health/nutrition/MealLoggerView.vue
frontend/src/views/health/nutrition/NutritionDashboardView.vue
scripts/health-check.sh
scripts/step83_endpoint_health_check.sh
step54_apply_health_regression_fixes.sh
step54_health_module_export_20260511_212103.txt
step69-health-ai-files.tar.gz
step69-health-ai-files/backend/app/Models/HealthHydrationLog.php
step69-health-ai-files/backend/app/Models/HealthLabTest.php
step69-health-ai-files/backend/app/Models/HealthMedication.php
step69-health-ai-files/backend/app/Models/HealthMedicationReminder.php
step69-health-ai-files/backend/app/Models/HealthNutritionLog.php
step69-health-ai-files/backend/app/Models/HealthStepLog.php
step69-health-ai-files/backend/app/Models/HealthWeightLog.php
step69-health-ai-files/backend/routes/api.php
step69-health-ai-files/frontend/src/layouts/AppLayout.vue
step69-health-ai-files/frontend/src/router/index.js
step69-health-ai-files/frontend/src/services/healthService.js
step69-health-ai-files/frontend/src/views/health/HealthView.vue
step69-health-ai-updated-files.tar.gz
step69-health-ai-updated-files/backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php
step69-health-ai-updated-files/backend/app/Models/HealthHydrationLog.php
step69-health-ai-updated-files/backend/app/Models/HealthLabTest.php
step69-health-ai-updated-files/backend/app/Models/HealthMedication.php
step69-health-ai-updated-files/backend/app/Models/HealthMedicationReminder.php
step69-health-ai-updated-files/backend/app/Models/HealthNutritionLog.php
step69-health-ai-updated-files/backend/app/Models/HealthStepLog.php
step69-health-ai-updated-files/backend/app/Models/HealthWeightLog.php
step69-health-ai-updated-files/backend/app/Services/Health/HealthAIInsightService.php
step69-health-ai-updated-files/backend/routes/api.php
step69-health-ai-updated-files/frontend/src/layouts/AppLayout.vue
step69-health-ai-updated-files/frontend/src/router/index.js
step69-health-ai-updated-files/frontend/src/services/healthService.js
step69-health-ai-updated-files/frontend/src/views/health/HealthAIInsightsView.vue
step69-health-ai-updated-files/frontend/src/views/health/HealthView.vue
step69-health-ai-updated-files/install-step69-health-ai.sh
step71-life-balance-ai-export/backend/app/Models/HealthHydrationLog.php
step71-life-balance-ai-export/backend/app/Models/HealthNutritionLog.php
step71-life-balance-ai-export/backend/app/Models/HealthStepLog.php
step71-life-balance-ai-export/backend/app/Models/HealthWeightLog.php
step71-life-balance-ai-files/backend/app/Models/HealthHydrationLog.php
step71-life-balance-ai-files/backend/app/Models/HealthNutritionLog.php
step71-life-balance-ai-files/backend/app/Models/HealthStepLog.php
step71-life-balance-ai-files/backend/app/Models/HealthWeightLog.php
step73_auth_export/backend/database/migrations/2026_04_24_081534_create_health_profiles_table.php
step73_auth_export/backend/database/migrations/2026_04_24_081534_create_health_step_logs_table.php
step73_auth_export/backend/database/migrations/2026_04_26_011352_create_health_weight_logs_table.php
step73_auth_export/backend/database/migrations/2026_04_26_015704_create_health_meal_logs_table.php
step73_auth_export/backend/database/migrations/2026_04_26_015705_create_health_food_items_table.php
step73_auth_export/backend/database/migrations/2026_04_26_015705_create_health_meal_log_items_table.php
step73_auth_export/backend/database/migrations/2026_04_26_015705_create_health_nutrition_profiles_table.php
step73_auth_export/backend/database/migrations/2026_04_26_040332_create_health_hydration_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_07_214204_create_health_nutrition_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_09_091704_create_health_sleep_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_09_120356_create_health_mood_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_09_131453_create_health_medications_table.php
step73_auth_export/backend/database/migrations/2026_05_09_141443_add_daily_dose_and_dose_times_to_health_medications_table.php
step73_auth_export/backend/database/migrations/2026_05_09_141651_create_health_lab_tests_table.php
step73_auth_export/backend/database/migrations/2026_05_10_113754_add_custom_food_id_to_health_nutrition_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_10_175906_add_ckd_fields_to_health_lab_tests_table.php
step73_auth_export/backend/database/migrations/2026_05_10_180203_add_ckd_fields_to_health_lab_tests_table.php
step73_auth_export/backend/database/migrations/2026_05_10_190351_create_health_medication_reminders_table.php
step73_auth_export/backend/database/migrations/2026_05_10_190352_create_health_medication_dose_logs_table.php
step73_auth_export/backend/database/migrations/2026_05_10_200003_upgrade_health_lab_tests_for_step_51.php
step73_auth_export/backend/database/migrations/2026_05_10_201805_upgrade_health_lab_tests_for_step_51.php
step73_auth_export/backend/database/migrations/2026_05_10_210000_add_ckd_fields_to_health_lab_tests_table.php
step73_auth_export/backend/database/migrations/2026_05_10_214636_create_health_alerts_table.php
step73_auth_export/backend/database/migrations/2026_05_10_214724_create_health_alert_rules_table.php
step73_auth_export/backend/database/migrations/2026_05_10_232815_add_status_to_health_lab_tests_table.php
step77-error-state-review-files/backend/app/Http/Requests/StoreHealthHydrationLogRequest.php
step77-error-state-review-files/backend/app/Http/Requests/UpdateHealthHydrationLogRequest.php
step77-error-state-review-files/frontend/src/components/health/HealthAlertsPanel.vue
step77-error-state-review-files/frontend/src/services/healthService.js
step77-error-state-review-files/frontend/src/views/HealthHydrationView.vue
step77-error-state-review-files/frontend/src/views/health/CustomFoodsView.vue
step77-error-state-review-files/frontend/src/views/health/HealthAIInsightsView.vue
step77-error-state-review-files/frontend/src/views/health/HealthAlertsView.vue
step77-error-state-review-files/frontend/src/views/health/HealthNutritionView.vue
step77-error-state-review-files/frontend/src/views/health/HealthReportsView.vue
step77-error-state-review-files/frontend/src/views/health/HealthStepsView.vue
step77-error-state-review-files/frontend/src/views/health/HealthView.vue
step77-error-state-review-files/frontend/src/views/health/HealthWeightView.vue
step77-error-state-review-files/frontend/src/views/health/HydrationTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/LabTestsTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/MedicamentsTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/MedicationTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/MoodTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/NutritionTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/SleepTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/StepsTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/WeightTrackingView.vue
step77-error-state-review-files/frontend/src/views/health/nutrition/FoodItemsView.vue
step77-error-state-review-files/frontend/src/views/health/nutrition/MealLoggerView.vue
step77-error-state-review-files/frontend/src/views/health/nutrition/NutritionDashboardView.vue
step81-e2e-export/backend/app/Models/HealthHydrationLog.php
step81-e2e-export/backend/app/Models/HealthLabTest.php
step81-e2e-export/backend/app/Models/HealthMedication.php
step81-e2e-export/backend/app/Models/HealthNutritionLog.php
step81-e2e-export/backend/app/Models/HealthStepLog.php
step81-e2e-export/backend/app/Models/HealthWeightLog.php
step81-e2e-export/backend/app/Services/Health/HealthAIInsightService.php
step81-e2e-export/backend/app/Services/Health/HealthAlertEngineService.php
step81-e2e-export/backend/app/Services/Health/HealthReportService.php
step81-e2e-export/backend/database/migrations/2026_04_24_081534_create_health_profiles_table.php
step81-e2e-export/backend/database/migrations/2026_04_24_081534_create_health_step_logs_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_011352_create_health_weight_logs_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_015704_create_health_meal_logs_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_015705_create_health_food_items_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_015705_create_health_meal_log_items_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_015705_create_health_nutrition_profiles_table.php
step81-e2e-export/backend/database/migrations/2026_04_26_040332_create_health_hydration_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_07_214204_create_health_nutrition_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_09_091704_create_health_sleep_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_09_120356_create_health_mood_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_09_131453_create_health_medications_table.php
step81-e2e-export/backend/database/migrations/2026_05_09_141443_add_daily_dose_and_dose_times_to_health_medications_table.php
step81-e2e-export/backend/database/migrations/2026_05_09_141651_create_health_lab_tests_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_113754_add_custom_food_id_to_health_nutrition_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_175906_add_ckd_fields_to_health_lab_tests_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_180203_add_ckd_fields_to_health_lab_tests_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_190351_create_health_medication_reminders_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_190352_create_health_medication_dose_logs_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_200003_upgrade_health_lab_tests_for_step_51.php
step81-e2e-export/backend/database/migrations/2026_05_10_201805_upgrade_health_lab_tests_for_step_51.php
step81-e2e-export/backend/database/migrations/2026_05_10_210000_add_ckd_fields_to_health_lab_tests_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_214636_create_health_alerts_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_214724_create_health_alert_rules_table.php
step81-e2e-export/backend/database/migrations/2026_05_10_232815_add_status_to_health_lab_tests_table.php
step81-e2e-export/frontend/src/components/health/HealthAlertsPanel.vue
step81-e2e-export/frontend/src/services/healthService.js
step81-e2e-export/frontend/src/views/health/CustomFoodsView.vue
step81-e2e-export/frontend/src/views/health/HealthAIInsightsView.vue
step81-e2e-export/frontend/src/views/health/HealthAlertsView.vue
step81-e2e-export/frontend/src/views/health/HealthNutritionView.vue
step81-e2e-export/frontend/src/views/health/HealthReportsView.vue
step81-e2e-export/frontend/src/views/health/HealthStepsView.vue
step81-e2e-export/frontend/src/views/health/HealthView.vue
step81-e2e-export/frontend/src/views/health/HealthWeightView.vue
step81-e2e-export/frontend/src/views/health/HydrationTrackingView.vue
step81-e2e-export/frontend/src/views/health/LabTestsTrackingView.vue
step81-e2e-export/frontend/src/views/health/MedicamentsTrackingView.vue
step81-e2e-export/frontend/src/views/health/MedicationTrackingView.vue
step81-e2e-export/frontend/src/views/health/MoodTrackingView.vue
step81-e2e-export/frontend/src/views/health/NutritionTrackingView.vue
step81-e2e-export/frontend/src/views/health/SleepTrackingView.vue
step81-e2e-export/frontend/src/views/health/StepsTrackingView.vue
step81-e2e-export/frontend/src/views/health/WeightTrackingView.vue
step81-e2e-export/frontend/src/views/health/nutrition/FoodItemsView.vue
step81-e2e-export/frontend/src/views/health/nutrition/MealLoggerView.vue
step81-e2e-export/frontend/src/views/health/nutrition/NutritionDashboardView.vue
step82-dashboard-performance-patch/backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
step82-dashboard-performance-patch/step82-dashboard-performance-patch/backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/HealthNutritionLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthMealLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthMoodLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthNutritionProfileController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthNutritionSummaryController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthProfileController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/HealthStepLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/MedicationController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/MedicationDoseController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/MedicationReminderController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/Health/SleepLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/HealthAlertController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/HealthReportController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/HealthWeightLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthAIInsightController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthAnalyticsController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthDashboardController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthFoodItemController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthLabTestController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthMealLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthMoodLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthNutritionProfileController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthNutritionSummaryController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthProfileController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/HealthStepLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/MedicationController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/MedicationDoseController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/MedicationReminderController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/Health/SleepLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/HealthAlertController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/HealthHydrationLogController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/HealthReportController.php
step83-api-load-testing-export/backend/app/Http/Controllers/Api/V1/V1/HealthWeightLogController.php
step83-api-load-testing-export/backend/app/Http/Requests/StoreHealthHydrationLogRequest.php
step83-api-load-testing-export/backend/app/Http/Requests/UpdateHealthHydrationLogRequest.php
step83-api-load-testing-export/backend/app/Models/Health/CalorieEntry.php
step83-api-load-testing-export/backend/app/Models/Health/StepEntry.php
step83-api-load-testing-export/backend/app/Models/Health/WeightEntry.php
step83-api-load-testing-export/backend/app/Models/HealthAlert.php
step83-api-load-testing-export/backend/app/Models/HealthAlertRule.php
step83-api-load-testing-export/backend/app/Models/HealthFoodItem.php
step83-api-load-testing-export/backend/app/Models/HealthHydrationLog.php
step83-api-load-testing-export/backend/app/Models/HealthLabTest.php
step83-api-load-testing-export/backend/app/Models/HealthMealLog.php
step83-api-load-testing-export/backend/app/Models/HealthMealLogItem.php
step83-api-load-testing-export/backend/app/Models/HealthMedication.php
step83-api-load-testing-export/backend/app/Models/HealthMedicationDoseLog.php
step83-api-load-testing-export/backend/app/Models/HealthMedicationReminder.php
step83-api-load-testing-export/backend/app/Models/HealthMoodLog.php
step83-api-load-testing-export/backend/app/Models/HealthNutritionLog.php
step83-api-load-testing-export/backend/app/Models/HealthNutritionProfile.php
step83-api-load-testing-export/backend/app/Models/HealthProfile.php
step83-api-load-testing-export/backend/app/Models/HealthSleepLog.php
step83-api-load-testing-export/backend/app/Models/HealthStepLog.php
step83-api-load-testing-export/backend/app/Models/HealthWeightLog.php
step83-api-load-testing-export/backend/app/Services/Health/HealthAIInsightService.php
step83-api-load-testing-export/backend/app/Services/Health/HealthAlertEngineService.php
step83-api-load-testing-export/backend/app/Services/Health/HealthReportService.php
step83-api-load-testing-export/backend/database/migrations/2026_04_24_081534_create_health_profiles_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_24_081534_create_health_step_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_011352_create_health_weight_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_015704_create_health_meal_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_015705_create_health_food_items_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_015705_create_health_meal_log_items_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_015705_create_health_nutrition_profiles_table.php
step83-api-load-testing-export/backend/database/migrations/2026_04_26_040332_create_health_hydration_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_07_214204_create_health_nutrition_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_09_091704_create_health_sleep_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_09_120356_create_health_mood_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_09_131453_create_health_medications_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_09_141443_add_daily_dose_and_dose_times_to_health_medications_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_09_141651_create_health_lab_tests_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_113754_add_custom_food_id_to_health_nutrition_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_175906_add_ckd_fields_to_health_lab_tests_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_180203_add_ckd_fields_to_health_lab_tests_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_190351_create_health_medication_reminders_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_190352_create_health_medication_dose_logs_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_200003_upgrade_health_lab_tests_for_step_51.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_201805_upgrade_health_lab_tests_for_step_51.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_210000_add_ckd_fields_to_health_lab_tests_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_214636_create_health_alerts_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_214724_create_health_alert_rules_table.php
step83-api-load-testing-export/backend/database/migrations/2026_05_10_232815_add_status_to_health_lab_tests_table.php
step83-api-load-testing-export/frontend/src/components/health/HealthAlertsPanel.vue
step83-api-load-testing-export/frontend/src/services/healthAlertService.js
step83-api-load-testing-export/frontend/src/services/healthReportsService.js
step83-api-load-testing-export/frontend/src/services/healthService.js
step83-api-load-testing-export/frontend/src/services/healthWeightApi.js
step83-api-load-testing-export/frontend/src/views/HealthHydrationView.vue
step83-api-load-testing-export/frontend/src/views/health/CustomFoodsView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthAIInsightsView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthAlertsView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthNutritionView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthReportsView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthStepsView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthView.vue
step83-api-load-testing-export/frontend/src/views/health/HealthWeightView.vue
step83-api-load-testing-export/frontend/src/views/health/HydrationTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/LabTestsTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/MedicamentsTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/MedicationTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/MoodTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/NutritionTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/SleepTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/StepsTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/WeightTrackingView.vue
step83-api-load-testing-export/frontend/src/views/health/nutrition/FoodItemsView.vue
step83-api-load-testing-export/frontend/src/views/health/nutrition/MealLoggerView.vue
step83-api-load-testing-export/frontend/src/views/health/nutrition/NutritionDashboardView.vue
step83-api-load-testing-package/scripts/step83_endpoint_health_check.sh
step83-api-load-testing-package/step83-api-load-testing-package/scripts/step83_endpoint_health_check.sh
step85-frontend-build-optimization-export/frontend/src/components/health/HealthAlertsPanel.vue
step85-frontend-build-optimization-export/frontend/src/services/healthAlertService.js
step85-frontend-build-optimization-export/frontend/src/services/healthReportsService.js
step85-frontend-build-optimization-export/frontend/src/services/healthService.js
step85-frontend-build-optimization-export/frontend/src/services/healthWeightApi.js
step85-frontend-build-optimization-export/frontend/src/views/HealthHydrationView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/CustomFoodsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthAIInsightsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthAlertsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthNutritionView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthReportsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthStepsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HealthWeightView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/HydrationTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/LabTestsTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/MedicamentsTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/MedicationTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/MoodTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/NutritionTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/SleepTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/StepsTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/WeightTrackingView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/nutrition/FoodItemsView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/nutrition/MealLoggerView.vue
step85-frontend-build-optimization-export/frontend/src/views/health/nutrition/NutritionDashboardView.vue
step86-security-review-export/backend/app/Console/Commands/RunHealthAlertsEngine.php
step86-security-review-export/backend/app/Console/Commands/RunSystemHealthCheck.php
step86-security-review-export/backend/app/Exports/HealthReportExport.php
step86-security-review-export/backend/app/Http/Controllers/Api/HealthNutritionLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthMealLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthMoodLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthNutritionProfileController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthNutritionSummaryController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthProfileController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/HealthStepLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/MedicationController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/MedicationDoseController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/MedicationReminderController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/Health/SleepLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/HealthAlertController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/HealthReportController.php
step86-security-review-export/backend/app/Http/Controllers/Api/V1/HealthWeightLogController.php
step86-security-review-export/backend/app/Http/Requests/StoreHealthHydrationLogRequest.php
step86-security-review-export/backend/app/Http/Requests/UpdateHealthHydrationLogRequest.php
step86-security-review-export/backend/app/Http/Resources/HealthFoodItemResource.php
step86-security-review-export/backend/app/Http/Resources/HealthHydrationLogResource.php
step86-security-review-export/backend/app/Http/Resources/HealthMealLogItemResource.php
step86-security-review-export/backend/app/Http/Resources/HealthMealLogResource.php
step86-security-review-export/backend/app/Http/Resources/HealthMealResource.php
step86-security-review-export/backend/app/Http/Resources/HealthNutritionProfileResource.php
step86-security-review-export/backend/app/Http/Resources/HealthProfileResource.php
step86-security-review-export/backend/app/Http/Resources/HealthReportResource.php
step86-security-review-export/backend/app/Http/Resources/HealthStepLogResource.php
step86-security-review-export/backend/app/Http/Resources/HealthWeightLogResource.php
step86-security-review-export/backend/app/Models/Health/CalorieEntry.php
step86-security-review-export/backend/app/Models/Health/StepEntry.php
step86-security-review-export/backend/app/Models/Health/WeightEntry.php
step86-security-review-export/backend/app/Models/HealthAlert.php
step86-security-review-export/backend/app/Models/HealthAlertRule.php
step86-security-review-export/backend/app/Models/HealthFoodItem.php
step86-security-review-export/backend/app/Models/HealthHydrationLog.php
step86-security-review-export/backend/app/Models/HealthLabTest.php
step86-security-review-export/backend/app/Models/HealthMealLog.php
step86-security-review-export/backend/app/Models/HealthMealLogItem.php
step86-security-review-export/backend/app/Models/HealthMedication.php
step86-security-review-export/backend/app/Models/HealthMedicationDoseLog.php
step86-security-review-export/backend/app/Models/HealthMedicationReminder.php
step86-security-review-export/backend/app/Models/HealthMoodLog.php
step86-security-review-export/backend/app/Models/HealthNutritionLog.php
step86-security-review-export/backend/app/Models/HealthNutritionProfile.php
step86-security-review-export/backend/app/Models/HealthProfile.php
step86-security-review-export/backend/app/Models/HealthSleepLog.php
step86-security-review-export/backend/app/Models/HealthStepLog.php
step86-security-review-export/backend/app/Models/HealthWeightLog.php
step86-security-review-export/backend/app/Services/Health/HealthAIInsightService.php
step86-security-review-export/backend/app/Services/Health/HealthAlertEngineService.php
step86-security-review-export/backend/app/Services/Health/HealthReportService.php
step86-security-review-export/backend/database/migrations/2026_04_24_081534_create_health_profiles_table.php
step86-security-review-export/backend/database/migrations/2026_04_24_081534_create_health_step_logs_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_011352_create_health_weight_logs_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_015704_create_health_meal_logs_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_015705_create_health_food_items_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_015705_create_health_meal_log_items_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_015705_create_health_nutrition_profiles_table.php
step86-security-review-export/backend/database/migrations/2026_04_26_040332_create_health_hydration_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_07_214204_create_health_nutrition_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_09_091704_create_health_sleep_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_09_120356_create_health_mood_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_09_131453_create_health_medications_table.php
step86-security-review-export/backend/database/migrations/2026_05_09_141443_add_daily_dose_and_dose_times_to_health_medications_table.php
step86-security-review-export/backend/database/migrations/2026_05_09_141651_create_health_lab_tests_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_113754_add_custom_food_id_to_health_nutrition_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_175906_add_ckd_fields_to_health_lab_tests_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_180203_add_ckd_fields_to_health_lab_tests_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_190351_create_health_medication_reminders_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_190352_create_health_medication_dose_logs_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_200003_upgrade_health_lab_tests_for_step_51.php
step86-security-review-export/backend/database/migrations/2026_05_10_201805_upgrade_health_lab_tests_for_step_51.php
step86-security-review-export/backend/database/migrations/2026_05_10_210000_add_ckd_fields_to_health_lab_tests_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_214636_create_health_alerts_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_214724_create_health_alert_rules_table.php
step86-security-review-export/backend/database/migrations/2026_05_10_232815_add_status_to_health_lab_tests_table.php
step86-security-review-export/frontend/src/components/health/HealthAlertsPanel.vue
step86-security-review-export/frontend/src/services/healthAlertService.js
step86-security-review-export/frontend/src/services/healthReportsService.js
step86-security-review-export/frontend/src/services/healthService.js
step86-security-review-export/frontend/src/services/healthWeightApi.js
step86-security-review-export/frontend/src/views/HealthHydrationView.vue
step86-security-review-export/frontend/src/views/health/CustomFoodsView.vue
step86-security-review-export/frontend/src/views/health/HealthAIInsightsView.vue
step86-security-review-export/frontend/src/views/health/HealthAlertsView.vue
step86-security-review-export/frontend/src/views/health/HealthNutritionView.vue
step86-security-review-export/frontend/src/views/health/HealthReportsView.vue
step86-security-review-export/frontend/src/views/health/HealthStepsView.vue
step86-security-review-export/frontend/src/views/health/HealthView.vue
step86-security-review-export/frontend/src/views/health/HealthWeightView.vue
step86-security-review-export/frontend/src/views/health/HydrationTrackingView.vue
step86-security-review-export/frontend/src/views/health/LabTestsTrackingView.vue
step86-security-review-export/frontend/src/views/health/MedicamentsTrackingView.vue
step86-security-review-export/frontend/src/views/health/MedicationTrackingView.vue
step86-security-review-export/frontend/src/views/health/MoodTrackingView.vue
step86-security-review-export/frontend/src/views/health/NutritionTrackingView.vue
step86-security-review-export/frontend/src/views/health/SleepTrackingView.vue
step86-security-review-export/frontend/src/views/health/StepsTrackingView.vue
step86-security-review-export/frontend/src/views/health/WeightTrackingView.vue
step86-security-review-export/frontend/src/views/health/nutrition/FoodItemsView.vue
step86-security-review-export/frontend/src/views/health/nutrition/MealLoggerView.vue
step86-security-review-export/frontend/src/views/health/nutrition/NutritionDashboardView.vue
step86-security-small-export/backend-http/Controllers/Api/HealthNutritionLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthAIInsightController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthAnalyticsController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthDashboardController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthFoodItemController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthLabTestController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthMealLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthMoodLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthNutritionProfileController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthNutritionSummaryController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthProfileController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/HealthStepLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/MedicationController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/MedicationDoseController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/MedicationReminderController.php
step86-security-small-export/backend-http/Controllers/Api/V1/Health/SleepLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/HealthAlertController.php
step86-security-small-export/backend-http/Controllers/Api/V1/HealthHydrationLogController.php
step86-security-small-export/backend-http/Controllers/Api/V1/HealthReportController.php
step86-security-small-export/backend-http/Controllers/Api/V1/HealthWeightLogController.php
step86-security-small-export/backend-http/Requests/StoreHealthHydrationLogRequest.php
step86-security-small-export/backend-http/Requests/UpdateHealthHydrationLogRequest.php
step86-security-small-export/backend-http/Resources/HealthFoodItemResource.php
step86-security-small-export/backend-http/Resources/HealthHydrationLogResource.php
step86-security-small-export/backend-http/Resources/HealthMealLogItemResource.php
step86-security-small-export/backend-http/Resources/HealthMealLogResource.php
step86-security-small-export/backend-http/Resources/HealthMealResource.php
step86-security-small-export/backend-http/Resources/HealthNutritionProfileResource.php
step86-security-small-export/backend-http/Resources/HealthProfileResource.php
step86-security-small-export/backend-http/Resources/HealthReportResource.php
step86-security-small-export/backend-http/Resources/HealthStepLogResource.php
step86-security-small-export/backend-http/Resources/HealthWeightLogResource.php
step86-security-small-export/backend-models/Health/CalorieEntry.php
step86-security-small-export/backend-models/Health/StepEntry.php
step86-security-small-export/backend-models/Health/WeightEntry.php
step86-security-small-export/backend-models/HealthAlert.php
step86-security-small-export/backend-models/HealthAlertRule.php
step86-security-small-export/backend-models/HealthFoodItem.php
step86-security-small-export/backend-models/HealthHydrationLog.php
step86-security-small-export/backend-models/HealthLabTest.php
step86-security-small-export/backend-models/HealthMealLog.php
step86-security-small-export/backend-models/HealthMealLogItem.php
step86-security-small-export/backend-models/HealthMedication.php
step86-security-small-export/backend-models/HealthMedicationDoseLog.php
step86-security-small-export/backend-models/HealthMedicationReminder.php
step86-security-small-export/backend-models/HealthMoodLog.php
step86-security-small-export/backend-models/HealthNutritionLog.php
step86-security-small-export/backend-models/HealthNutritionProfile.php
step86-security-small-export/backend-models/HealthProfile.php
step86-security-small-export/backend-models/HealthSleepLog.php
step86-security-small-export/backend-models/HealthStepLog.php
step86-security-small-export/backend-models/HealthWeightLog.php
step86-security-small-export/frontend-services/healthAlertService.js
step86-security-small-export/frontend-services/healthReportsService.js
step86-security-small-export/frontend-services/healthService.js
step86-security-small-export/frontend-services/healthWeightApi.js
step89_1_frontend_design_review/src/components/health/HealthAlertsPanel.vue
step89_1_frontend_design_review/src/views/HealthHydrationView.vue
step89_1_frontend_design_review/src/views/health/CustomFoodsView.vue
step89_1_frontend_design_review/src/views/health/HealthAIInsightsView.vue
step89_1_frontend_design_review/src/views/health/HealthAlertsView.vue
step89_1_frontend_design_review/src/views/health/HealthNutritionView.vue
step89_1_frontend_design_review/src/views/health/HealthReportsView.vue
step89_1_frontend_design_review/src/views/health/HealthStepsView.vue
step89_1_frontend_design_review/src/views/health/HealthView.vue
step89_1_frontend_design_review/src/views/health/HealthWeightView.vue
step89_1_frontend_design_review/src/views/health/HydrationTrackingView.vue
step89_1_frontend_design_review/src/views/health/LabTestsTrackingView.vue
step89_1_frontend_design_review/src/views/health/MedicamentsTrackingView.vue
step89_1_frontend_design_review/src/views/health/MedicationTrackingView.vue
step89_1_frontend_design_review/src/views/health/MoodTrackingView.vue
step89_1_frontend_design_review/src/views/health/NutritionTrackingView.vue
step89_1_frontend_design_review/src/views/health/SleepTrackingView.vue
step89_1_frontend_design_review/src/views/health/StepsTrackingView.vue
step89_1_frontend_design_review/src/views/health/WeightTrackingView.vue
step89_1_frontend_design_review/src/views/health/nutrition/FoodItemsView.vue
step89_1_frontend_design_review/src/views/health/nutrition/MealLoggerView.vue
step89_1_frontend_design_review/src/views/health/nutrition/NutritionDashboardView.vue
storage/app/step83-load-results/20260517-233731/baseline_health_ai_insights.txt
storage/app/step83-load-results/20260517-233731/baseline_health_dashboard.txt
storage/app/step83-load-results/20260517-233731/baseline_health_hydration_daily.txt
storage/app/step83-load-results/20260517-233731/baseline_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-233731/baseline_health_steps.txt
storage/app/step83-load-results/20260517-233731/smoke_health_ai_insights.txt
storage/app/step83-load-results/20260517-233731/smoke_health_dashboard.txt
storage/app/step83-load-results/20260517-233731/smoke_health_hydration_daily.txt
storage/app/step83-load-results/20260517-233731/smoke_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-233731/smoke_health_steps.txt
storage/app/step83-load-results/20260517-233731/stress_health_ai_insights.txt
storage/app/step83-load-results/20260517-233731/stress_health_dashboard.txt
storage/app/step83-load-results/20260517-233731/stress_health_hydration_daily.txt
storage/app/step83-load-results/20260517-233731/stress_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-233731/stress_health_steps.txt
storage/app/step83-load-results/20260517-235031/baseline_health_ai_insights.txt
storage/app/step83-load-results/20260517-235031/baseline_health_dashboard.txt
storage/app/step83-load-results/20260517-235031/baseline_health_hydration_daily.txt
storage/app/step83-load-results/20260517-235031/baseline_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-235031/baseline_health_steps.txt
storage/app/step83-load-results/20260517-235031/smoke_health_ai_insights.txt
storage/app/step83-load-results/20260517-235031/smoke_health_dashboard.txt
storage/app/step83-load-results/20260517-235031/smoke_health_hydration_daily.txt
storage/app/step83-load-results/20260517-235031/smoke_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-235031/smoke_health_steps.txt
storage/app/step83-load-results/20260517-235031/stress_health_ai_insights.txt
storage/app/step83-load-results/20260517-235031/stress_health_dashboard.txt
storage/app/step83-load-results/20260517-235031/stress_health_hydration_daily.txt
storage/app/step83-load-results/20260517-235031/stress_health_nutrition_summary.txt
storage/app/step83-load-results/20260517-235031/stress_health_steps.txt
storage/app/step83-load-results/20260518-000053/baseline_health_ai_insights.txt
storage/app/step83-load-results/20260518-000053/baseline_health_dashboard.txt
storage/app/step83-load-results/20260518-000053/baseline_health_hydration_daily.txt
storage/app/step83-load-results/20260518-000053/baseline_health_nutrition_summary.txt
storage/app/step83-load-results/20260518-000053/baseline_health_steps.txt
storage/app/step83-load-results/20260518-000053/smoke_health_ai_insights.txt
storage/app/step83-load-results/20260518-000053/smoke_health_dashboard.txt
storage/app/step83-load-results/20260518-000053/smoke_health_hydration_daily.txt
storage/app/step83-load-results/20260518-000053/smoke_health_nutrition_summary.txt
storage/app/step83-load-results/20260518-000053/smoke_health_steps.txt
storage/app/step83-load-results/20260518-000053/stress_health_ai_insights.txt
storage/app/step83-load-results/20260518-000053/stress_health_dashboard.txt
storage/app/step83-load-results/20260518-000053/stress_health_hydration_daily.txt
storage/app/step83-load-results/20260518-000053/stress_health_nutrition_summary.txt
storage/app/step83-load-results/20260518-000053/stress_health_steps.txt
```

## Health References Detected
```text
api.php:20:use App\Http\Controllers\Api\HealthNutritionLogController;
api.php:21:use App\Http\Controllers\Api\V1\HealthAlertController;
api.php:22:use App\Http\Controllers\Api\V1\HealthReportController;
api.php:29:use App\Http\Controllers\Api\V1\Health\HealthDashboardController;
api.php:30:use App\Http\Controllers\Api\V1\Health\HealthLabTestController;
api.php:31:use App\Http\Controllers\Api\V1\Health\MedicationController;
api.php:32:use App\Http\Controllers\Api\V1\Health\MedicationReminderController;
api.php:33:use App\Http\Controllers\Api\V1\Health\MedicationDoseController;
api.php:34:use App\Http\Controllers\Api\V1\Health\SleepLogController;
api.php:35:use App\Http\Controllers\Api\V1\Health\HealthStepLogController;
api.php:36:use App\Http\Controllers\Api\V1\Health\HealthMoodLogController;
api.php:38:use App\Http\Controllers\Api\V1\HealthWeightLogController;
api.php:39:use App\Http\Controllers\Api\V1\HealthHydrationLogController;
api.php:54:| Public API Health Check
api.php:58:Route::get('/health', function () {
api.php:295:        | Health Module
api.php:299:        Route::prefix('health')->group(function () {
api.php:301:            Route::get('/reports/daily', [HealthReportController::class, 'daily']);
api.php:302:            Route::get('/reports/weekly', [HealthReportController::class, 'weekly']);
api.php:303:            Route::get('/reports/monthly', [HealthReportController::class, 'monthly']);
api.php:304:            Route::get('/reports/export-preview', [HealthReportController::class, 'exportPreview']);
api.php:305:            Route::get('/alerts', [HealthAlertController::class, 'index']);
api.php:306:            Route::get('/alerts/summary', [HealthAlertController::class, 'summary']);
api.php:307:            Route::post('/alerts/run', [HealthAlertController::class, 'run']);
api.php:309:            Route::patch('/alerts/{id}/read', [HealthAlertController::class, 'markAsRead']);
api.php:310:            Route::patch('/alerts/{id}/resolve', [HealthAlertController::class, 'resolve']);
api.php:311:            Route::patch('/alerts/{id}/dismiss', [HealthAlertController::class, 'dismiss']);
api.php:313:            Route::delete('/alerts/{id}', [HealthAlertController::class, 'destroy']);
api.php:316:            | Health Dashboard
api.php:320:            Route::get('/dashboard', [HealthDashboardController::class, 'summary']);
api.php:369:            Route::get('/lab-tests/categories', [HealthLabTestController::class, 'categories']);
api.php:370:            Route::get('/lab-tests/trends', [HealthLabTestController::class, 'trends']);
api.php:371:            Route::get('/lab-tests', [HealthLabTestController::class, 'index']);
api.php:372:            Route::post('/lab-tests', [HealthLabTestController::class, 'store']);
api.php:373:            Route::get('/lab-tests/{id}', [HealthLabTestController::class, 'show']);
api.php:374:            Route::put('/lab-tests/{id}', [HealthLabTestController::class, 'update']);
api.php:375:            Route::patch('/lab-tests/{id}', [HealthLabTestController::class, 'update']);
api.php:376:            Route::delete('/lab-tests/{id}', [HealthLabTestController::class, 'destroy']);
api.php:384:            Route::get('/mood', [HealthMoodLogController::class, 'index']);
api.php:385:            Route::post('/mood', [HealthMoodLogController::class, 'store']);
api.php:386:            Route::get('/mood/{id}', [HealthMoodLogController::class, 'show']);
api.php:387:            Route::put('/mood/{id}', [HealthMoodLogController::class, 'update']);
api.php:388:            Route::patch('/mood/{id}', [HealthMoodLogController::class, 'update']);
api.php:389:            Route::delete('/mood/{id}', [HealthMoodLogController::class, 'destroy']);
api.php:417:            Route::get('/steps', [HealthStepLogController::class, 'index']);
api.php:418:            Route::post('/steps', [HealthStepLogController::class, 'store']);
api.php:419:            Route::get('/steps/summary', [HealthStepLogController::class, 'summary']);
api.php:420:            Route::get('/steps/{id}', [HealthStepLogController::class, 'show']);
api.php:421:            Route::put('/steps/{id}', [HealthStepLogController::class, 'update']);
api.php:422:            Route::patch('/steps/{id}', [HealthStepLogController::class, 'update']);
api.php:423:            Route::delete('/steps/{id}', [HealthStepLogController::class, 'destroy']);
api.php:431:            Route::get('/weight', [HealthWeightLogController::class, 'index']);
api.php:432:            Route::post('/weight', [HealthWeightLogController::class, 'store']);
api.php:433:            Route::get('/weight/summary', [HealthWeightLogController::class, 'summary']);
api.php:434:            Route::get('/weight/{id}', [HealthWeightLogController::class, 'show']);
api.php:435:            Route::put('/weight/{id}', [HealthWeightLogController::class, 'update']);
api.php:436:            Route::patch('/weight/{id}', [HealthWeightLogController::class, 'update']);
api.php:437:            Route::delete('/weight/{id}', [HealthWeightLogController::class, 'destroy']);
api.php:445:            Route::get('/nutrition/summary', [HealthNutritionLogController::class, 'summary']);
api.php:446:            Route::get('/nutrition', [HealthNutritionLogController::class, 'index']);
api.php:447:            Route::post('/nutrition', [HealthNutritionLogController::class, 'store']);
api.php:448:            Route::get('/nutrition/{id}', [HealthNutritionLogController::class, 'show']);
api.php:449:            Route::put('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
api.php:450:            Route::patch('/nutrition/{id}', [HealthNutritionLogController::class, 'update']);
api.php:451:            Route::delete('/nutrition/{id}', [HealthNutritionLogController::class, 'destroy']);
api.php:459:            Route::get('/hydration', [HealthHydrationLogController::class, 'index']);
api.php:460:            Route::post('/hydration', [HealthHydrationLogController::class, 'store']);
api.php:461:            Route::get('/hydration/summary/daily', [HealthHydrationLogController::class, 'dailySummary']);
api.php:462:            Route::get('/hydration/summary/weekly', [HealthHydrationLogController::class, 'weeklySummary']);
api.php:463:            Route::post('/hydration/quick-add', [HealthHydrationLogController::class, 'quickAdd']);
api.php:464:            Route::get('/hydration/{id}', [HealthHydrationLogController::class, 'show']);
api.php:465:            Route::put('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
api.php:466:            Route::patch('/hydration/{id}', [HealthHydrationLogController::class, 'update']);
api.php:467:            Route::delete('/hydration/{id}', [HealthHydrationLogController::class, 'destroy']);
backend/app/Console/Commands/GenerateLifeBalanceAlerts.php:35:                    'Your Life Balance score is ' . $latestScore->overall_score . '. Consider reviewing your health, finance, and productivity balance.',
backend/app/Console/Commands/GenerateMealReminders.php:30:                    'health',
backend/app/Console/Commands/GenerateMealReminders.php:42:                    'health',
backend/app/Console/Commands/GenerateMealReminders.php:54:                    'health',
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:5:use App\Models\HealthMedicationDoseLog;
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:6:use App\Models\HealthMedicationReminder;
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:20:            ! Schema::hasTable('health_medication_reminders') ||
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:21:            ! Schema::hasTable('health_medication_dose_logs')
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:29:        $reminders = HealthMedicationReminder::query()
backend/app/Console/Commands/GenerateMedicationDoseLogs.php:53:            $log = HealthMedicationDoseLog::firstOrCreate(
backend/app/Console/Commands/GenerateWeightReminders.php:31:                'health'
backend/app/Console/Commands/ProcessMissedMedicationDoses.php:5:use App\Models\HealthMedicationDoseLog;
backend/app/Console/Commands/ProcessMissedMedicationDoses.php:18:        if (! Schema::hasTable('health_medication_dose_logs')) {
backend/app/Console/Commands/ProcessMissedMedicationDoses.php:19:            $this->warn('health_medication_dose_logs table does not exist yet.');
backend/app/Console/Commands/ProcessMissedMedicationDoses.php:26:        $updated = HealthMedicationDoseLog::query()
backend/app/Console/Commands/RunHealthAlertsEngine.php:7:use App\Services\Health\HealthAlertEngineService;
backend/app/Console/Commands/RunHealthAlertsEngine.php:9:class RunHealthAlertsEngine extends Command
backend/app/Console/Commands/RunHealthAlertsEngine.php:11:    protected $signature = 'health:generate-alerts {--user_id=} {--date=}';
backend/app/Console/Commands/RunHealthAlertsEngine.php:13:    protected $description = 'Generate health alerts for users';
backend/app/Console/Commands/RunHealthAlertsEngine.php:15:    public function handle(HealthAlertEngineService $engine): int
backend/app/Console/Commands/RunSystemHealthCheck.php:10:class RunSystemHealthCheck extends Command
backend/app/Console/Commands/RunSystemHealthCheck.php:12:    protected $signature = 'system:health-check';
backend/app/Console/Commands/RunSystemHealthCheck.php:14:    protected $description = 'Run NIX LIFE OS system health check';
backend/app/Console/Commands/RunSystemHealthCheck.php:20:        $status = 'healthy';
backend/app/Console/Commands/RunSystemHealthCheck.php:21:        $message = 'System health check completed successfully';
backend/app/Console/Commands/RunSystemHealthCheck.php:26:            $status = 'unhealthy';
backend/app/Console/Commands/RunSystemHealthCheck.php:33:            'service_name' => 'scheduled-health-check',
backend/app/Console/Commands/RunSystemHealthCheck.php:44:        $this->info("Health check completed: {$status}");
backend/app/Console/Commands/SendMedicationReminderNotifications.php:5:use App\Models\HealthMedicationDoseLog;
backend/app/Console/Commands/SendMedicationReminderNotifications.php:18:        if (! Schema::hasTable('health_medication_dose_logs')) {
backend/app/Console/Commands/SendMedicationReminderNotifications.php:19:            $this->warn('health_medication_dose_logs table does not exist yet.');
backend/app/Console/Commands/SendMedicationReminderNotifications.php:26:        $doses = HealthMedicationDoseLog::query()
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:408:                'message' => 'User finance and health dashboard loaded successfully.',
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:420:                    'health' => $this->userHealthDashboard($id, $today),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:487:    private function userHealthDashboard(string $userId, string $today): array
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:490:        if ($this->hasTable('health_step_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:491:            $todaySteps = (int) DB::table('health_step_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:498:        if ($this->hasTable('health_hydration_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:499:            $hydrationColumn = $this->hasColumn('health_hydration_logs', 'quantity_ml') ? 'quantity_ml' : 'amount_ml';
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:500:            $dateColumn = $this->hasColumn('health_hydration_logs', 'log_date') ? 'log_date' : 'created_at';
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:502:            $todayWater = (int) DB::table('health_hydration_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:514:        if ($this->hasTable('health_nutrition_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:515:            $dateColumn = $this->hasColumn('health_nutrition_logs', 'meal_date') ? 'meal_date' : 'created_at';
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:517:            $base = DB::table('health_nutrition_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:522:            $todayProtein = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'protein_g') ? 'protein_g' : 'protein');
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:523:            $todaySodium = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'sodium_mg') ? 'sodium_mg' : 'sodium');
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:524:            $todayPotassium = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'potassium_mg') ? 'potassium_mg' : 'potassium');
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:525:            $todayPhosphorus = (float) (clone $base)->sum($this->hasColumn('health_nutrition_logs', 'phosphorus_mg') ? 'phosphorus_mg' : 'phosphorus');
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:530:        if ($this->hasTable('health_weight_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:531:            $weight = DB::table('health_weight_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:533:                ->orderByDesc($this->hasColumn('health_weight_logs', 'log_date') ? 'log_date' : 'created_at')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:541:        if ($this->hasTable('health_sleep_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:542:            $sleep = DB::table('health_sleep_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:556:        if ($this->hasTable('health_mood_logs')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:557:            $todayMood = DB::table('health_mood_logs')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:565:        if ($this->hasTable('health_medications')) {
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:566:            $activeMedications = DB::table('health_medications')
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:586:                'lab_tests_count' => $this->countRows('health_lab_tests', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:587:                'active_alerts_count' => $this->countRowsWhere('health_alerts', $userId, 'status', 'active'),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:590:                'step_logs' => $this->countRows('health_step_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:591:                'hydration_logs' => $this->countRows('health_hydration_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:592:                'nutrition_logs' => $this->countRows('health_nutrition_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:593:                'weight_logs' => $this->countRows('health_weight_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:594:                'sleep_logs' => $this->countRows('health_sleep_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:595:                'mood_logs' => $this->countRows('health_mood_logs', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:596:                'medications' => $this->countRows('health_medications', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:597:                'lab_tests' => $this->countRows('health_lab_tests', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:598:                'alerts' => $this->countRows('health_alerts', $userId),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:600:            'recent_steps' => $this->recentRows('health_step_logs', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:601:            'recent_nutrition' => $this->recentRows('health_nutrition_logs', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:602:            'recent_weight' => $this->recentRows('health_weight_logs', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:603:            'recent_sleep' => $this->recentRows('health_sleep_logs', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:604:            'recent_mood' => $this->recentRows('health_mood_logs', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:605:            'recent_medications' => $this->recentRows('health_medications', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:606:            'recent_lab_tests' => $this->recentRows('health_lab_tests', $userId, 5),
backend/app/Http/Controllers/Api/Admin/AdminUserController.php:607:            'recent_alerts' => $this->recentRows('health_alerts', $userId, 5),
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:6:use App\Models\HealthNutritionLog;
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:9:class HealthNutritionLogController extends Controller
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:15:        $query = HealthNutritionLog::query()
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:41:        $log = HealthNutritionLog::create([
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:55:        $log = HealthNutritionLog::where('user_id', $request->user()->id)
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:68:        $log = HealthNutritionLog::where('user_id', $request->user()->id)
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:85:        $log = HealthNutritionLog::where('user_id', $request->user()->id)
backend/app/Http/Controllers/Api/HealthNutritionLogController.php:101:        $totals = HealthNutritionLog::query()
backend/app/Http/Controllers/Api/LifeBalanceController.php:36:            $healthScore = $this->calculateHealthScore($userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:43:                $healthScore +
backend/app/Http/Controllers/Api/LifeBalanceController.php:52:                        'health_score' => $healthScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:58:                            $healthScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:90:                    'health_score' => 0,
backend/app/Http/Controllers/Api/LifeBalanceController.php:131:    private function calculateHealthScore(string $userId): int
backend/app/Http/Controllers/Api/LifeBalanceController.php:134:            $stepsCount = $this->safeCount('health_step_logs', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:135:            $weightCount = $this->safeCount('health_weight_logs', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:136:            $nutritionCount = $this->safeCount('health_nutrition_logs', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:137:            $hydrationCount = $this->safeCount('health_hydration_logs', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:221:            $healthCount = $this->safeCount('health_step_logs', $userId);
backend/app/Http/Controllers/Api/LifeBalanceController.php:230:            if ($healthCount > 0) {
backend/app/Http/Controllers/Api/LifeBalanceController.php:270:        int $healthScore,
backend/app/Http/Controllers/Api/LifeBalanceController.php:283:        if ($healthScore >= 70) {
backend/app/Http/Controllers/Api/LifeBalanceController.php:284:            $recommendations[] = 'Health tracking is improving.';
backend/app/Http/Controllers/Api/LifeBalanceController.php:290:            $recommendations[] = 'Project activity looks healthy.';
backend/app/Http/Controllers/Api/LifeBalanceController.php:300:            $recommendations[] = 'Try to update finance, health, and project data every day for better consistency.';
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:48:            'health_alerts_enabled' => ['nullable', 'boolean'],
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:68:            'health_alerts_enabled' => true,
backend/app/Http/Controllers/Api/NotificationPreferenceController.php:125:            'health_alerts_enabled' => true,
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:42:                $health = $this->healthSummary($userId, $today);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:47:                    'health' => $health,
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:59:                    'today_steps' => $health['today_steps'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:60:                    'today_calories' => $health['today_calories'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:61:                    'water_intake_ml' => $health['today_water_ml'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:62:                    'current_weight_kg' => $health['latest_weight'],
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:154:    private function healthSummary(string $userId, string $today): array
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:156:        $weightTable = $this->firstExistingTable(['health_weight_logs', 'weight_entries']);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:157:        $stepsTable = $this->firstExistingTable(['health_step_logs', 'step_entries']);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:158:        $hydrationTable = $this->firstExistingTable(['health_hydration_logs']);
backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php:159:        $nutritionTable = $this->firstExistingTable(['health_nutrition_logs', 'health_meal_logs']);
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:44:        $todaySteps = $this->tableExists('health_step_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:45:            ? DB::table('health_step_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:53:        if ($this->tableExists('health_meal_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:54:            $todayCalories += (float) DB::table('health_meal_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:60:        if ($this->tableExists('health_nutrition_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:61:            $todayCalories += (float) DB::table('health_nutrition_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:67:        $todayWaterMl = $this->tableExists('health_hydration_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:68:            ? DB::table('health_hydration_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:74:        $weightKg = $this->tableExists('health_weight_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:75:            ? DB::table('health_weight_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:116:                'health' => [
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:155:        $stepsRows = $this->tableExists('health_step_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:156:            ? DB::table('health_step_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:168:        if ($this->tableExists('health_meal_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:169:            $calorieRows = DB::table('health_meal_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:177:        } elseif ($this->tableExists('health_nutrition_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:178:            $calorieRows = DB::table('health_nutrition_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:268:        if ($this->tableExists('health_step_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:269:            $stepActivities = DB::table('health_step_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:277:                        'type' => 'health',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:287:        if ($this->tableExists('health_hydration_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:288:            $hydrationActivities = DB::table('health_hydration_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:296:                        'type' => 'health',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:306:        if ($this->tableExists('health_nutrition_logs')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:307:            $nutritionActivities = DB::table('health_nutrition_logs')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:315:                        'type' => 'health',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:325:        if ($this->tableExists('health_alerts')) {
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:326:            $alertActivities = DB::table('health_alerts')
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:333:                        'id' => 'health-alert-' . $item->id,
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:334:                        'type' => 'health_alert',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:335:                        'module' => 'Health',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:336:                        'title' => $item->title ?? 'Health alert',
backend/app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php:337:                        'description' => $item->message ?? ucfirst((string) ($item->category ?? 'health')) . ' alert',
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:3:namespace App\Http\Controllers\Api\V1\Health;
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:6:use App\Services\Health\HealthAIInsightService;
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:12:class HealthAIInsightController extends Controller
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:15:        private readonly HealthAIInsightService $healthAIInsightService
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:26:            $payload = $this->healthAIInsightService->generateForUser((string) $user->id);
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:30:                'message' => ($payload['summary']['has_health_data'] ?? false)
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:31:                    ? 'Health AI insights generated successfully.'
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:32:                    : 'No health data available yet.',
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:36:            Log::error('Health AI insights generation failed', [
backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php:45:                'message' => 'Unable to generate Health AI insights.',
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:3:namespace App\Http\Controllers\Api\V1\Health;
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:11:class HealthAnalyticsController extends Controller
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:34:            $baseUrl = rtrim(config('services.health_analytics.url'), '/');
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:38:                ->post($baseUrl . '/api/v1/analytics/health/daily', $payload);
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:41:                Log::error('Health analytics service failed', [
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:48:                    'message' => 'Health analytics service returned an error.',
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:55:                'message' => 'Health analytics generated successfully.',
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:60:            Log::error('Health analytics service unavailable', [
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:66:                'message' => 'Health analytics service is unavailable.',
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:75:         | You can later replace this with a real health_profiles table.
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:93:        if (!DB::getSchemaBuilder()->hasTable('health_weight_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:97:        return DB::table('health_weight_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:117:            !DB::getSchemaBuilder()->hasTable('health_meal_logs') ||
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:118:            !DB::getSchemaBuilder()->hasTable('health_meal_log_items')
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:123:        $row = DB::table('health_meal_logs as ml')
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:124:            ->join('health_meal_log_items as mli', 'mli.meal_log_id', '=', 'ml.id')
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:159:        if (!DB::getSchemaBuilder()->hasTable('health_hydration_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:163:        $row = DB::table('health_hydration_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:188:        if (!DB::getSchemaBuilder()->hasTable('health_step_log')) {
backend/app/Http/Controllers/Api/V1/Health/HealthAnalyticsController.php:192:        $row = DB::table('health_step_log')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:3:namespace App\Http\Controllers\Api\V1\Health;
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:12:class HealthDashboardController extends Controller
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:21:            "health_dashboard_user_{$userId}_{$today}",
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:53:            'message' => 'Health dashboard loaded successfully.',
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:68:        if (! Schema::hasTable('health_step_log')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:74:        if (Schema::hasTable('health_profile')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:75:            $profile = DB::table('health_profile')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:84:        $todayLog = DB::table('health_step_log')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:89:        $latestLog = DB::table('health_step_log')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:116:        if (! Schema::hasTable('health_weight_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:120:        $logs = DB::table('health_weight_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:157:        if (Schema::hasTable('health_nutrition_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:158:            $row = DB::table('health_nutrition_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:179:        if (Schema::hasTable('health_meal_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:180:            $row = DB::table('health_meal_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:210:        if (! Schema::hasTable('health_hydration_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:219:        $row = DB::table('health_hydration_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:244:        if (! Schema::hasTable('health_sleep_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:248:        $latest = DB::table('health_sleep_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:255:        $weeklyAverageMinutes = DB::table('health_sleep_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:276:        if (! Schema::hasTable('health_mood_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:280:        $latest = DB::table('health_mood_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:305:        if (Schema::hasTable('health_medications')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:306:            $summary['active_count'] = DB::table('health_medications')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:313:        if (Schema::hasTable('health_medication_dose_logs')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:316:            $logs = DB::table('health_medication_dose_logs')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:336:        if (! Schema::hasTable('health_lab_tests')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:343:        $latest = DB::table('health_lab_tests')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:350:        $abnormalCount = DB::table('health_lab_tests')
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:363:        if (! Schema::hasTable('health_alerts')) {
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:373:            'active_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->count(),
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:374:            'critical_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'critical')->count(),
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:375:            'warning_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'warning')->count(),
backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php:376:            'unread_count' => DB::table('health_alerts')->where('user_id', $userId)->whereNull('read_at')->count(),
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:3:namespace App\Http\Controllers\Api\V1\Health;
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:6:use App\Http\Resources\HealthFoodItemResource;
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:7:use App\Models\HealthFoodItem;
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:10:class HealthFoodItemController extends Controller
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:14:        $query = HealthFoodItem::query()
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:35:        return HealthFoodItemResource::collection($foods);
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:58:        $food = HealthFoodItem::create([
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:68:            'data' => new HealthFoodItemResource($food),
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:72:    public function show(Request $request, HealthFoodItem $healthFoodItem)
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:75:            $healthFoodItem->user_id !== null && $healthFoodItem->user_id !== $request->user()->id,
backend/app/Http/Controllers/Api/V1/Health/HealthFoodItemController.php:79:        return new HealthFoodItemResource($healthFoodItem);
backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php:3:namespace App\Http\Controllers\Api\V1\Health;
backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php:6:use App\Models\HealthLabTest;
backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php:7:use App\Models\HealthLabTestResult;
```
