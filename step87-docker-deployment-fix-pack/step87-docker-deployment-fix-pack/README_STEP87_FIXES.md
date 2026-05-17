# STEP 87 — Docker Deployment Fix Pack

This fix pack updates the Docker deployment baseline and adds a validation script.

## Install

```bash
cd /u01/nix-life-os
tar -xzf step87-docker-deployment-fix-pack.tar.gz
chmod +x step87-docker-deployment-fix-pack/install_step87_docker_fixes.sh
./step87-docker-deployment-fix-pack/install_step87_docker_fixes.sh /u01/nix-life-os
```

## Rebuild and validate

```bash
cd /u01/nix-life-os
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build
docker exec nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan config:cache && php artisan route:cache && php artisan migrate --force'
./scripts/step87_deployment_validation.sh
```

## Important

Use `docker compose -f docker-compose.prod.yml ...` for production. Avoid plain `docker compose ...` if an old `compose.yaml` exists in the project root.
