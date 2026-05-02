#!/bin/bash

set -e


cd /u01/nix-life-os

echo "Stopping containers..."
docker compose -f /u01/nix-life-os/docker-compose.prod.yml down

echo "Building containers..."
docker compose -f /u01/nix-life-os/docker-compose.prod.yml build --no-cache

echo "Starting containers..."
docker compose -f /u01/nix-life-os/docker-compose.prod.yml up -d

echo "Running Laravel optimization..."
docker exec nixlifeos-backend php artisan config:cache
docker exec nixlifeos-backend php artisan route:cache
docker exec nixlifeos-backend php artisan view:cache
docker exec nixlifeos-backend php artisan migrate --force

echo "Production restart completed."
docker ps