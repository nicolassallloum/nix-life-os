#!/bin/bash
set -e

cd /u01/nix-life-os

cp backend/routes/api.php backend/routes/api.php.bak_step59_task_progress_route_$(date +%Y%m%d_%H%M%S)

python3 <<'PY'
from pathlib import Path

path = Path("backend/routes/api.php")
text = path.read_text()

old = """            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);
            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);"""

new = """            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);

            /*
            |--------------------------------------------------------------------------
            | Task Progress Update
            |--------------------------------------------------------------------------
            | Keep this route before /tasks/{task} update routes.
            */
            Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);
            Route::put('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);

            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);"""

if old not in text:
    print("Original task route block not found exactly.")
    print("Adding PUT progress route after existing PATCH progress route if possible.")

    if "Route::patch('/{project}/tasks/{task}/progress'" in text and "Route::put('/{project}/tasks/{task}/progress'" not in text:
        text = text.replace(
            "Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);",
            "Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);\n            Route::put('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);"
        )
    else:
        raise SystemExit("Could not safely patch api.php. Please send backend/routes/api.php.")
else:
    text = text.replace(old, new)

path.write_text(text)
PY

echo "=================================================="
echo "Clear Laravel cache"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan optimize:clear && php artisan route:clear && php artisan config:clear"

echo "=================================================="
echo "Show exact task progress routes"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list --path='api/v1/projects' | grep -Ei 'tasks.*/progress|Method|URI'"

echo "=================================================="
echo "Restart backend nginx and backend container"
echo "=================================================="

docker restart nixlifeos-backend nixlifeos-backend-nginx

echo "=================================================="
echo "Wait and re-check route"
echo "=================================================="

sleep 5

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list --path='api/v1/projects' | grep -Ei 'tasks.*/progress|Method|URI'"

echo "=================================================="
echo "Done"
echo "=================================================="
