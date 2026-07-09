# Bundle 5 — To-Do Task Organization Features

This patch package adds persistent task section movement, manual ordering, and finished-task points summaries for the Nix Life OS To-Do module.

## Files included

- `database/migrations/2026_07_09_000005_update_todo_tasks_for_bundle5_organization.php`
- `app/Services/TodoPointsService.php`
- `app/Services/TodoTaskOrderingService.php`
- `app/Http/Controllers/Api/TodoTaskOrganizationController.php`
- `app/Http/Controllers/Api/TodoDashboardSummaryController.php`
- `app/Http/Controllers/Api/TodoProjectDetailsController.php`
- `resources/js/pages/todo/TodoBoard.vue`
- `resources/js/components/todo/TodoPointsSummary.vue`
- `docs/routes_api_bundle5_snippet.php`
- `docs/router_bundle5_snippet.js`
- `docs/package_bundle5_snippet.json`

## Apply

From your real project root:

```bash
cd /home/nix/u01/nix-life-os
cp -R /path/to/bundle5_todo_patch/* .
```

Then manually merge `docs/routes_api_bundle5_snippet.php` into `routes/api.php`.
If the project already has matching routes, do not duplicate them. Merge the controller methods/response fields instead.

Add the Vue route from `docs/router_bundle5_snippet.js` if your router does not already expose a To-Do board page.

Install drag-and-drop package if missing:

```bash
npm install vuedraggable@next sortablejs
```

## Run

```bash
php artisan migrate
php artisan route:clear
php artisan config:clear
php artisan test
npm install
npm run build
git status
git add .
git commit -m "Implement Bundle 5 task organization drag drop ordering and points system"
git push
```

## Backend endpoints added

- `GET /api/todo/tasks/grouped`
- `PATCH /api/todo/tasks/{task}/move`
- `PATCH /api/todo/tasks/reorder`
- `PATCH /api/todo/tasks/{task}/status`
- `PATCH /api/todo/tasks/{task}`
- `GET /api/todo/dashboard`
- `GET /api/todo/projects/{project}`

## Ordering rule

Tasks are always returned by:

1. `sort_order ASC`
2. `due_date ASC NULLS LAST`
3. `created_at DESC`

Manual drag/reorder writes unique sequential `sort_order` values so the order persists after refresh.

## Points rules

Only tasks with `status = finished` count toward points.
Pending and in-progress tasks are excluded.
Changing a finished task back to pending/in-progress removes its points immediately because totals are recalculated from PostgreSQL each response.
Updating points after completion recalculates totals immediately.

## Movement rules enforced in Vue

Allowed:

- General → Monthly
- General → Weekly
- General → Daily
- Monthly → Weekly
- Weekly → Daily
- Any section → General
- Reorder inside same section

Blocked:

- Daily → Weekly/Monthly
- Weekly → Monthly
- Monthly → Daily directly

## Notes

The code assumes the Laravel model is `App\Models\TodoTask` and that tasks have `user_id`.
If your project uses a different model name or namespace, update imports in:

- `TodoTaskOrderingService.php`
- `TodoTaskOrganizationController.php`

The Vue files assume your Axios wrapper is available at `@/services/api`.
If your project uses `@/api`, `@/lib/api`, or a different file, update the import in `TodoBoard.vue`.
