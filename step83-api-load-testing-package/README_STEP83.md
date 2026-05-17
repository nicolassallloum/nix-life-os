# STEP 83 — API Load Testing Package

This package adds load-testing scripts, a k6 scenario, endpoint matrix, bottleneck checklist, and SQL index recommendations for Nix Life OS.

## Install

From project root:

```bash
cd /u01/nix-life-os
tar -xzf step83-api-load-testing-package.tar.gz
chmod +x install_step83_load_testing_package.sh
./install_step83_load_testing_package.sh
```

## Run

```bash
cd /u01/nix-life-os
export API_BASE="http://127.0.0.1:8000/api/v1"
export ADMIN_EMAIL="step74.admin@gmail.com"
export ADMIN_PASSWORD="Password@123"
./scripts/step83_endpoint_health_check.sh
./scripts/step83_api_load_test.sh
```

Optional k6:

```bash
k6 run tests/load/step83-k6-load-test.js
```
