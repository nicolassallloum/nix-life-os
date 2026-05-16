# STEP 74 — Sidebar / Navigation Regression Patch

This patch updates the Nix Life OS frontend navigation system.

## Changed files

- `frontend/src/router/index.js`
- `frontend/src/router/index.ts`
- `frontend/src/App.vue`
- `frontend/src/layouts/AppLayout.vue`
- `frontend/src/utils/auth.js`
- `frontend/src/utils/permissions.js`
- `frontend/package.json`

## Main fixes

- Added missing `@/utils/auth` and `@/utils/permissions` helpers.
- Replaced the old hardcoded `App.vue` sidebar with the shared `AppLayout`.
- Added a responsive desktop/mobile sidebar.
- Fixed active sidebar state for exact and nested routes.
- Added route aliases/redirects for older paths.
- Added missing route entries for existing views such as health sleep, mood, nutrition subpages, finance expenses, and monitoring alias.
- Hardened route guards for auth, guest-only pages, role checks, and permission checks.
- Updated `vue-router` dependency to Vue Router 4 for Vue 3 compatibility.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step74-sidebar-navigation-patch.tar.gz
chmod +x install_step74_sidebar_navigation_patch.sh
./install_step74_sidebar_navigation_patch.sh
```

## Validate

```bash
cd /u01/nix-life-os/frontend
npm install
npm run build
```
