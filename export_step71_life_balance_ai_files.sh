#!/usr/bin/env bash

set -e

BASE_DIR="/u01/nix-life-os"
EXPORT_DIR="$BASE_DIR/step71-life-balance-ai-export"
ARCHIVE_NAME="step71-life-balance-ai-files.tar.gz"
MISSING_FILE="$EXPORT_DIR/MISSING_FILES.txt"

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"
touch "$MISSING_FILE"

FILES=(
"backend/routes/api.php"

"backend/app/Http/Controllers/Api/V1/LifeBalanceController.php"
"backend/app/Http/Controllers/Api/V1/LifeBalanceAiRecommendationController.php"

"backend/app/Services/LifeBalanceAiRecommendationService.php"
"backend/app/Services/LifeBalanceService.php"

"backend/app/Models/User.php"
"backend/app/Models/FinanceAccount.php"
"backend/app/Models/FinanceTransaction.php"
"backend/app/Models/FinanceBudget.php"
"backend/app/Models/HealthNutritionLog.php"
"backend/app/Models/HealthHydrationLog.php"
"backend/app/Models/HealthWeightLog.php"
"backend/app/Models/HealthStepLog.php"
"backend/app/Models/Project.php"
"backend/app/Models/ProductivityTask.php"
"backend/app/Models/ProductivityHabit.php"
"backend/app/Models/ProductivityGoal.php"
"backend/app/Models/ProductivityCalendarEvent.php"

"frontend/src/router/index.js"
"frontend/src/router/index.ts"

"frontend/src/services/lifeBalanceService.js"
"frontend/src/services/lifeBalanceService.ts"

"frontend/src/views/life-balance/LifeBalanceView.vue"
"frontend/src/views/life-balance/LifeBalanceRecommendationsView.vue"

"frontend/src/components/life-balance/LifeBalanceAiRecommendations.vue"

"frontend/src/layouts/AppLayout.vue"
"frontend/src/views/dashboard/DashboardView.vue"
)

cd "$BASE_DIR"

echo "Exporting STEP 71 Life Balance AI files..."
echo ""

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$FILE")"
    cp "$FILE" "$EXPORT_DIR/$FILE"
    echo "FOUND: $FILE"
  else
    echo "MISSING: $FILE" | tee -a "$MISSING_FILE"
  fi
done

echo ""
echo "Searching for additional Life Balance related files..."

{
  echo ""
  echo "===== LIFE BALANCE FILE SEARCH RESULTS ====="
  find backend frontend -type f \( \
    -iname "*LifeBalance*" -o \
    -iname "*lifeBalance*" -o \
    -iname "*life-balance*" -o \
    -iname "*Recommendation*" -o \
    -iname "*recommendation*" \
  \) 2>/dev/null
} >> "$EXPORT_DIR/SEARCH_RESULTS.txt"

tar -czf "$BASE_DIR/$ARCHIVE_NAME" -C "$EXPORT_DIR" .

echo ""
echo "Export completed."
echo "Archive created:"
echo "$BASE_DIR/$ARCHIVE_NAME"
echo ""
echo "Missing files report:"
echo "$MISSING_FILE"
