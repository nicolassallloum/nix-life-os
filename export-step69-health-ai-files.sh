#!/usr/bin/env bash

set -e

EXPORT_DIR="step69-health-ai-files"
ZIP_NAME="step69-health-ai-files.tar.gz"

echo "Creating export folder: $EXPORT_DIR"
rm -rf "$EXPORT_DIR" "$ZIP_NAME"
mkdir -p "$EXPORT_DIR"

copy_file() {
  local file="$1"

  if [ -f "$file" ]; then
    echo "Copying: $file"
    mkdir -p "$EXPORT_DIR/$(dirname "$file")"
    cp "$file" "$EXPORT_DIR/$file"
  else
    echo "MISSING: $file"
  fi
}

echo ""
echo "Exporting backend files..."
copy_file "backend/routes/api.php"
copy_file "backend/app/Models/HealthNutritionLog.php"
copy_file "backend/app/Models/HealthHydrationLog.php"
copy_file "backend/app/Models/HealthWeightLog.php"
copy_file "backend/app/Models/HealthStepLog.php"
copy_file "backend/app/Models/HealthLabTest.php"
copy_file "backend/app/Models/HealthMedication.php"
copy_file "backend/app/Models/HealthMedicationReminder.php"

echo ""
echo "Exporting frontend files..."

if [ -f "frontend/src/router/index.js" ]; then
  copy_file "frontend/src/router/index.js"
elif [ -f "frontend/src/router/index.ts" ]; then
  copy_file "frontend/src/router/index.ts"
else
  echo "MISSING: frontend/src/router/index.js or index.ts"
fi

if [ -f "frontend/src/services/healthService.js" ]; then
  copy_file "frontend/src/services/healthService.js"
elif [ -f "frontend/src/services/healthService.ts" ]; then
  copy_file "frontend/src/services/healthService.ts"
else
  echo "MISSING: frontend/src/services/healthService.js or healthService.ts"
fi

copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/views/health/HealthView.vue"

echo ""
echo "Creating archive: $ZIP_NAME"
tar -czf "$ZIP_NAME" "$EXPORT_DIR"

echo ""
echo "Done."
echo "Archive created:"
ls -lah "$ZIP_NAME"

echo ""
echo "Files included:"
find "$EXPORT_DIR" -type f | sort
