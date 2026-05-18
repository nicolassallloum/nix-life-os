# STEP 89.1.2 — Layout CSS Independence Hotfix

Fixes the post-Step 89.1 browser issue where the sidebar/header layout appears broken because AppLayout.vue still depends on Tailwind utility classes that are not being generated/applied in the running UI.

Changed files:
- frontend/src/layouts/AppLayout.vue
- frontend/src/assets/main.css

Install:
```bash
cd /u01/nix-life-os
tar -xzf step89_1_2_layout_css_hotfix.tar.gz
chmod +x step89_1_2_layout_css_hotfix/scripts/install_step89_1_2_layout_css_hotfix.sh
./step89_1_2_layout_css_hotfix/scripts/install_step89_1_2_layout_css_hotfix.sh /u01/nix-life-os
cd /u01/nix-life-os/frontend
npm run build
cd /u01/nix-life-os
docker compose -f docker-compose.prod.yml up -d --build frontend
```

If testing on Vite dev server `127.0.0.1:5173`, restart it after installing this hotfix.
