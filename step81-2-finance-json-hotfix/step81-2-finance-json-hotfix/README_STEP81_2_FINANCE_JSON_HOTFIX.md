# STEP 81.2 Finance JSON/Alias Hotfix

Fixes finance E2E account creation when validation receives canonical fields before alias normalization.

Changes:
- Reads both `$request->all()` and raw JSON body via `$request->getContent()`.
- Maps alias payload fields before validation:
  - `name` -> `account_name`
  - `type` -> `account_type` or `transaction_type`
  - `currency` -> `currency_code`
- Keeps invalid UUID handling clean.
