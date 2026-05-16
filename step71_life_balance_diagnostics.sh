#!/usr/bin/env bash

set -e

REPORT="step71-life-balance-diagnostics.txt"

rm -f "$REPORT"

echo "STEP 71 LIFE BALANCE AI DIAGNOSTICS" | tee -a "$REPORT"
echo "Generated at: $(date)" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"

echo "===== Laravel Routes: life =====" | tee -a "$REPORT"
docker exec nixlifeos-backend sh -lc "php artisan route:list | grep -i life || true" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Laravel Routes: ai =====" | tee -a "$REPORT"
docker exec nixlifeos-backend sh -lc "php artisan route:list | grep -i ai || true" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Laravel Routes: recommendation =====" | tee -a "$REPORT"
docker exec nixlifeos-backend sh -lc "php artisan route:list | grep -i recommendation || true" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Backend Life Balance Files =====" | tee -a "$REPORT"
find backend -type f \( -iname "*LifeBalance*" -o -iname "*lifeBalance*" -o -iname "*life-balance*" \) 2>/dev/null | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Frontend Life Balance Files =====" | tee -a "$REPORT"
find frontend/src -type f \( -iname "*LifeBalance*" -o -iname "*lifeBalance*" -o -iname "*life-balance*" \) 2>/dev/null | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Frontend References =====" | tee -a "$REPORT"
grep -R "life-balance\|LifeBalance\|lifeBalance\|recommendation\|Recommendation" frontend/src -n || true | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "===== Backend References =====" | tee -a "$REPORT"
grep -R "life-balance\|LifeBalance\|lifeBalance\|recommendation\|Recommendation" backend/routes backend/app -n || true | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "Diagnostics completed: $REPORT"
