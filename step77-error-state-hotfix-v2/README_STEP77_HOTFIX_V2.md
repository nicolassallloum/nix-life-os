# STEP 77 Error State Hotfix v2

Fixes:
- Adds `frontend/src/services/api.ts` so TypeScript imports no longer fail on `./services/api`.
- Fixes `frontend/src/main.ts` TypeScript error by safely reading the Vue internal component type through an explicit loose type.
- Reinstalls backend error handling and `/api/v1/security/roles` + `/api/v1/security/permissions` route additions.

Install:

```bash
cd /u01/nix-life-os
mkdir -p /tmp/step77-error-state-hotfix-v2
tar -xzf step77-error-state-hotfix-v2.tar.gz -C /tmp/step77-error-state-hotfix-v2
chmod +x /tmp/step77-error-state-hotfix-v2/install_step77_error_state_hotfix_v2.sh
/tmp/step77-error-state-hotfix-v2/install_step77_error_state_hotfix_v2.sh /u01/nix-life-os
```

Restart using container names:

```bash
docker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend nixlifeos-nginx
```

If the frontend/backend are baked into images and not bind-mounted:

```bash
docker compose -f docker-compose.prod.yml up -d --build
```
