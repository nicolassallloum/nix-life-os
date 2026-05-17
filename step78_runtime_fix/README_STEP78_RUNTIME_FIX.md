# STEP 78 Runtime Fix

This package fixes the browser console error:

`Failed to load module script: Expected a JavaScript-or-Wasm module script but the server responded with a MIME type of text/html.`

Root cause: the browser requested hashed Vite chunks under `/assets/*.js`, but the server returned `index.html` instead of the JS file. This usually happens when the deployed `dist/assets` is stale/missing or the Nginx SPA fallback is also applied to asset files.

Apply:

```bash
cd /u01/nix-life-os
cp step78-runtime-fix/frontend-vite.config.js frontend/vite.config.js
./step78-runtime-fix/scripts/fix_step78_frontend_deploy.sh /u01/nix-life-os
```

If you control the frontend Nginx config, replace it with `nginx/frontend-spa.conf` or merge the `/assets/` rule:

```nginx
location /assets/ {
    add_header Cache-Control "public, max-age=31536000, immutable" always;
    try_files $uri =404;
}
```

The important rule is: missing `/assets/*.js` must return `404`, not `/index.html`.
