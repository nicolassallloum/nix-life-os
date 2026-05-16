# STEP 74 Fix 2

This fix resolves two remaining issues after the STEP 74 authorization patch:

1. TypeScript build error for `@/utils/auth` by adding `frontend/src/utils/auth.d.ts`.
2. QA registration failure by using a DNS-valid Gmail test address by default in `step74_authorization_regression_test_v3.sh`.

Install:

```bash
cd /u01/nix-life-os
tar -xzf step74-authorization-fix2.tar.gz
cd step74_fix2_package
chmod +x install_step74_fix2.sh
./install_step74_fix2.sh /u01/nix-life-os
```

Run:

```bash
cd /u01/nix-life-os/frontend
npm run build

cd /u01/nix-life-os
./step74_authorization_regression_test_v3.sh
```

If your validator still rejects the generated email, run with your own real test email domain:

```bash
NORMAL_EMAIL=yourtestaccount@gmail.com NORMAL_PASSWORD='Step74@2026!' ./step74_authorization_regression_test_v3.sh
```
