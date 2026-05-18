# STEP 89.1 — Tailwind @apply Build Hotfix

## Issue
`npm run build` fails in `frontend/src/assets/main.css` with:

`Cannot apply unknown utility class bg-slate-50`

## Root Cause
The first STEP 89.1 CSS patch used many Tailwind `@apply` rules. The project build pipeline uses `@tailwindcss/vite`, and the CSS compiler rejects these utility references during production generation.

## Fix
Replace `frontend/src/assets/main.css` with a build-safe version that keeps Tailwind directives but converts all project-level `.nix-*` classes to normal CSS declarations.

## Files changed
- `frontend/src/assets/main.css`

## Commands
```bash
cd /u01/nix-life-os

tar -xzf step89_1_tailwind_apply_hotfix.tar.gz
chmod +x step89_1_tailwind_apply_hotfix/scripts/install_step89_1_tailwind_apply_hotfix.sh
./step89_1_tailwind_apply_hotfix/scripts/install_step89_1_tailwind_apply_hotfix.sh /u01/nix-life-os

cd /u01/nix-life-os/frontend
npm run build

cd /u01/nix-life-os
docker compose -f docker-compose.prod.yml up -d --build frontend
docker compose -f docker-compose.prod.yml ps
```
