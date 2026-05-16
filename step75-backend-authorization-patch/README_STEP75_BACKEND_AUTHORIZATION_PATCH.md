# STEP 75 Backend Authorization Patch

## Fixes included

1. Replaces strict `email:rfc,dns` registration validation with `email:rfc` so local/project domains such as `nixlifeos.com` do not fail DNS validation during QA.
2. Increases auth QA throttles:
   - login: `throttle:20,1`
   - register: `throttle:10,1`
3. Adds numeric route constraints for task endpoints using `{task}`.
4. Adds safe `Task::resolveRouteBinding()` handling so malformed bigint IDs return 404 instead of PostgreSQL `SQLSTATE[22P02]` / HTTP 500.

## Install

From `/u01/nix-life-os`:

```bash
tar -xzf step75-backend-authorization-patch.tar.gz
chmod +x install_step75_backend_authorization_patch.sh
./install_step75_backend_authorization_patch.sh
```

## Retest

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan optimize:clear"

curl -i -s "$API_BASE/productivity/tasks/invalid-id" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN"

curl -s -X POST "$API_BASE/auth/register" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Step75 User B",
    "email": "step75userb@nixlifeos.com",
    "password": "Password@123",
    "password_confirmation": "Password@123"
  }' | jq .
```

Expected:

- `/productivity/tasks/invalid-id` -> `404 Not Found`, not `500`.
- User B registration -> `201 Created`, unless the email already exists.
