# STEP 85 — Frontend Build Optimization Notes

## Main Findings

- Production build is successful.
- Total `dist` output is about 1.1 MB.
- Most route chunks are small and healthy.
- The largest route chunk is `FinanceDashboardView`, around 193 KB raw / 64.56 KB gzip.
- Route-level lazy loading is already implemented in the router.
- The finance dashboard imports multiple heavy child panels synchronously, including the Chart.js panel.
- `chart.js` and `vue-chartjs` should stay route/component-scoped and should not be imported globally.
- `recharts` is a React charting library and should be removed from a Vue project unless there is a confirmed React island. Prefer `chart.js` + `vue-chartjs` or plain CSS charts.
- There are duplicate `.js` and `.ts` entry/config/router files. The current `index.html` uses `src/main.ts`; keep TypeScript as the source of truth and remove unused duplicates later.
- Nginx static asset caching was missing for hashed Vite assets.
- Docker frontend build used `npm install`; production builds should use `npm ci` for deterministic installs.

## Patch Summary

This patch updates:

- `frontend/vite.config.js`
- `frontend/vite.config.ts`
- `frontend/nginx.conf`
- `frontend/Dockerfile`
- `frontend/.dockerignore`
- `frontend/src/views/finance/FinanceDashboardView.vue`

The finance dashboard page now loads the existing all-in-one finance dashboard panel asynchronously and removes duplicate chart/table/budget/form rendering from the route shell. This avoids loading Chart.js on the initial finance dashboard path unless another route/component imports it.

## Recommended Next Optimization

After this patch, the next biggest improvement should be removing duplicated dashboard data loading from finance widgets and passing dashboard data down as props from one parent loader.
