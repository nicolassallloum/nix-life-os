# STEP 81.3 — Final E2E Retest

This package does not replace backend code. It uses the canonical API contract proven by the last retest:

- finance account: `account_name`, `account_type`, `currency_code`
- finance transaction: `transaction_type`, `currency_code`
- project: `project_name`, `project_code`, `in_progress`

Run:

```bash
cd /u01/nix-life-os
chmod +x step81-3-final-e2e-retest/install_step81_3_final_retest.sh
./step81-3-final-e2e-retest/install_step81_3_final_retest.sh

API_BASE="http://127.0.0.1:8000/api/v1" \
TEST_EMAIL="test@nixlifeos.com" \
TEST_PASSWORD="password" \
./step81-3-final-e2e-retest/scripts/step81_3_final_e2e_retest.sh
```
