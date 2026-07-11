#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-/u01/nix-life-os}"
cd "$ROOT"

printf '\n== Backend migrations ==\n'
docker compose exec -T backend php artisan migrate:status >/tmp/bundle7_migrations.txt
if grep -q 'Pending' /tmp/bundle7_migrations.txt; then
  cat /tmp/bundle7_migrations.txt
  echo 'FAILED: pending migrations found.' >&2
  exit 1
fi

docker compose exec -T backend php artisan migrate --pretend --force | tee /tmp/bundle7_migrate_pretend.txt

printf '\n== Backend test suite ==\n'
docker compose exec -T backend php artisan test

printf '\n== Backend optimization ==\n'
docker compose exec -T backend php artisan optimize:clear
docker compose exec -T backend php artisan config:cache
docker compose exec -T backend php artisan route:cache
docker compose exec -T backend php artisan view:cache
docker compose exec -T backend php artisan optimize

printf '\n== Backend JavaScript audit/build ==\n'
(
  cd backend
  npm ci
  npm audit --audit-level=high
  npm run build
)

printf '\n== Frontend validation ==\n'
(
  cd frontend
  npm ci
  npm audit --audit-level=high
  npm run type-check
  npm run test:unit -- --run
  npm run lint
  npm run build
)

printf '\nBundle 7 automated production gate: PASS\n'
