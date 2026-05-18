# STEP 89.1 — Global UI/Layout Design Fix

## Root Cause
The main frontend design issue is in the global app shell. `AppLayout.vue` mixed mobile fixed positioning with desktop static sidebar positioning, while desktop pages did not have a unified header/title area. This allowed different screens to control their own spacing and made header alignment, sidebar behavior, and mobile responsiveness inconsistent.

Network/API errors are expected when Docker/backend is down and are not counted as UI design failures.

## Files Changed
- `frontend/src/layouts/AppLayout.vue`
- `frontend/src/assets/main.css`
- `frontend/src/components/ui/BaseButton.vue`
- `frontend/src/components/ui/BaseCard.vue`
- `frontend/src/components/ui/BaseAlert.vue`
- `frontend/src/components/ui/LoadingState.vue`
- `frontend/src/components/ui/EmptyState.vue`

## Fix Summary
- Rebuilt the app shell with a fixed sidebar and content offset.
- Added desktop sidebar collapse behavior.
- Added mobile sidebar overlay with backdrop and close behavior.
- Added a unified sticky header for all private screens.
- Added route-based header title/subtitle support.
- Added standardized global UI classes for pages, cards, buttons, forms, tables, alerts, empty states, and loading states.
- Added a safety style for old plain buttons/inputs that still have no classes.

## Install
```bash
cd /u01/nix-life-os

tar -xzf step89_1_global_ui_layout_fix.tar.gz
chmod +x step89_1_global_ui_layout_fix/install_step89_1_global_ui_layout_fix.sh
./step89_1_global_ui_layout_fix/install_step89_1_global_ui_layout_fix.sh /u01/nix-life-os
```

## Build
```bash
cd /u01/nix-life-os/frontend
npm run build
```

## Redeploy Frontend
```bash
cd /u01/nix-life-os
docker compose -f docker-compose.prod.yml up -d --build frontend
docker compose -f docker-compose.prod.yml ps
```

## QA Screens
- Login
- Dashboard
- Life Balance
- AI Recommendations
- Finance Dashboard
- Finance Accounts
- Finance Transactions
- Health Dashboard
- Nutrition
- Hydration
- Lab Tests
- Productivity Dashboard
- Projects
- Security/Admin screens

## Desktop Checklist
- Sidebar is fixed on the left.
- Main content starts after sidebar.
- Header title is not clipped.
- Sidebar collapse works.
- Cards, buttons, forms, tables are visually consistent.
- No content hides under sidebar.

## Tablet Checklist
- Page spacing remains clean.
- Cards wrap into sensible columns.
- Tables scroll horizontally.
- Header remains readable.

## Mobile Checklist
- Sidebar hidden by default.
- Menu button opens sidebar.
- Backdrop closes sidebar.
- Clicking a sidebar link closes sidebar.
- Cards stack vertically.
- No horizontal page scroll.

## Screenshots Needed
- `01-login-desktop.png`
- `02-login-mobile.png`
- `03-dashboard-desktop.png`
- `04-dashboard-mobile.png`
- `05-sidebar-expanded-desktop.png`
- `06-sidebar-collapsed-desktop.png`
- `07-sidebar-mobile-open.png`
- `08-finance-dashboard-desktop.png`
- `09-finance-transactions-mobile.png`
- `10-health-dashboard-desktop.png`
- `11-lab-tests-mobile.png`
- `12-security-admin-desktop.png`
- `13-network-error-state.png`

## Final Approval Status
Status after file review: Patch prepared. Requires local `npm run build` and browser validation before final UI approval.
