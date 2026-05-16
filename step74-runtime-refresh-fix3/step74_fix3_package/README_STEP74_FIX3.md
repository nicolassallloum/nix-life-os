# STEP 74 Fix 3 — Runtime Refresh + Test User Setup

This package does not change application source code. It clears Laravel caches, restarts backend PHP-FPM/nginx to clear OPcache, creates a normal user and admin user directly through Laravel, and prints the exact final QA command.

Install/run from project root:

```bash
cd /u01/nix-life-os

tar -xzf step74-runtime-refresh-fix3.tar.gz

cd step74_fix3_package

chmod +x step74_runtime_refresh_and_admin_setup.sh

./step74_runtime_refresh_and_admin_setup.sh /u01/nix-life-os
```

Then run:

```bash
cd /u01/nix-life-os

NORMAL_EMAIL=step74.normal@gmail.com \
NORMAL_PASSWORD='Step74@2026!' \
ADMIN_EMAIL=step74.admin@gmail.com \
ADMIN_PASSWORD='Step74@2026!' \
./step74_authorization_regression_test_v3.sh
```
