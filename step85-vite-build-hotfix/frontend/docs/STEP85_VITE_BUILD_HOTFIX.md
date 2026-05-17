# STEP 85 — Vite Build Hotfix

## Fixed Issues

- Removed async `defineConfig` return to satisfy `vue-tsc` and Vite 8 typing.
- Added `manualChunks(id: string)` typing in `vite.config.ts`.
- Removed invalid Rollup/Rolldown output option `compact`.
- Removed explicit `minify: 'esbuild'` to avoid Vite 8 `Cannot find package 'esbuild'` build failure.
- Kept manual vendor chunk splitting for Vue, Vue Router, Pinia, Axios, and chart dependencies.

## Test Commands

```bash
cd /u01/nix-life-os/frontend
rm -rf dist
npm run type-check
npm run build

du -sh dist
find dist -type f -printf "%s %p\n" | sort -nr | head -30
```

## Note

`curl -I http://127.0.0.1/assets/` returning `404` is normal because `/assets/` is a directory and directory listing should remain disabled. Test a real hashed asset file instead.
