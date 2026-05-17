#!/usr/bin/env bash
set -Eeuo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TOKEN_FILE="${TOKEN_FILE:-.step83_token}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
ENDPOINT="${ENDPOINT:-/dashboard/summary}"
TOTAL="${TOTAL:-100}"
CONCURRENCY="${CONCURRENCY:-10}"

if [ -z "$ADMIN_TOKEN" ] && [ -f "$TOKEN_FILE" ]; then
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

if [ -z "$ADMIN_TOKEN" ]; then
  echo "⚠️  No ADMIN_TOKEN found. Running auth setup first."
  ./scripts/step83_auth_token_setup.sh
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "=================================================="
echo " STEP 83 — curl Concurrent Test"
echo " URL: $API_BASE$ENDPOINT"
echo " TOTAL=$TOTAL CONCURRENCY=$CONCURRENCY"
echo "=================================================="

seq 1 "$TOTAL" | xargs -I{} -P "$CONCURRENCY" sh -c '
  curl -sS -o /dev/null -w "%{http_code},%{time_total}\n" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer '$ADMIN_TOKEN'" \
    "'$API_BASE$ENDPOINT'" >> "'$TMP_DIR'/results.csv"
'

awk -F, '
  { count++; codes[$1]++; total+=$2; if ($2>max) max=$2; times[count]=$2 }
  END {
    asort(times);
    p95_index=int(count*0.95); if (p95_index<1) p95_index=1;
    print "Requests:", count;
    for (code in codes) print "HTTP " code ":", codes[code];
    print "Average seconds:", total/count;
    print "P95 seconds:", times[p95_index];
    print "Max seconds:", max;
  }
' "$TMP_DIR/results.csv"
