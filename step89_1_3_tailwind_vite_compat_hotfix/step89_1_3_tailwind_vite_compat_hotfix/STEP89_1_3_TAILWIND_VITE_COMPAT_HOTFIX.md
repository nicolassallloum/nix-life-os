# STEP 89.1.3 — Tailwind Vite Compatibility Hotfix

## Root cause
The frontend has `tailwindcss` v3 and a PostCSS Tailwind config, but `vite.config.js` also uses `@tailwindcss/vite`, which is the Tailwind v4 Vite plugin path. This can prevent the existing Tailwind v3 utility classes used inside Vue templates from being generated correctly.

## Symptom
The global layout shell is improved, but pages using Tailwind utility classes such as `rounded-2xl`, `grid`, `px-6`, `bg-gray-50`, `text-3xl`, and `shadow-sm` render like raw/default HTML.

## Fix
Remove `@tailwindcss/vite` from `vite.config.js` and let PostCSS process Tailwind v3 through `postcss.config.js`.

## Changed file
- `frontend/vite.config.js`

## Commands
```bash
cd /u01/nix-life-os

tar -xzf step89_1_3_tailwind_vite_compat_hotfix.tar.gz
chmod +x step89_1_3_tailwind_vite_compat_hotfix/scripts/install_step89_1_3_tailwind_vite_compat_hotfix.sh
./step89_1_3_tailwind_vite_compat_hotfix/scripts/install_step89_1_3_tailwind_vite_compat_hotfix.sh /u01/nix-life-os

cd /u01/nix-life-os/frontend
npm run build

cd /u01/nix-life-os
docker compose -f docker-compose.prod.yml up -d --build frontend
```

## Expected result
- Tailwind utility classes render correctly across views.
- Life Balance, Logging & Monitoring, Dashboard, Finance, Health, and Productivity pages should stop looking like raw/default HTML.
- The Step 89.1 layout shell remains fixed.
