#!/bin/bash
set -e

cd /u01/nix-life-os

BACKUP_DIR="backup_step59_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_file () {
  FILE_PATH="$1"
  if [ -f "$FILE_PATH" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$FILE_PATH")"
    cp "$FILE_PATH" "$BACKUP_DIR/$FILE_PATH"
  fi
}

echo "=================================================="
echo "STEP 59 - Updating Project Progress / Status Files"
echo "Backup directory: $BACKUP_DIR"
echo "=================================================="

backup_file "backend/routes/api.php"
backup_file "backend/app/Services/Projects/ProjectProgressService.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectProgressController.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectMilestoneController.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectStatusUpdateController.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php"
backup_file "backend/app/Models/ProjectStatusUpdate.php"
backup_file "frontend/src/views/ProjectProgressView.vue"
backup_file "frontend/src/views/ProjectStatusUpdatesView.vue"

mkdir -p backend/app/Services/Projects
mkdir -p backend/app/Http/Controllers/Api/V1
mkdir -p backend/app/Models

cat > backend/app/Services/Projects/ProjectProgressService.php <<'PHP'
<?php

namespace App\Services\Projects;

use App\Models\Project;
use App\Models\ProjectMilestone;
use App\Models\ProjectStatusUpdate;
use App\Models\ProjectTask;
use Illuminate\Support\Facades\DB;

class ProjectProgressService
{
    public function recalculate(Project $project): array
    {
        return DB::transaction(function () use ($project) {
            $project = $project->fresh();

            $tasks = $project->tasks()->get();
            $milestones = $project->milestones()->get();

            $totalTasks = $tasks->count();
            $completedTasks = $tasks->where('status', 'completed')->count();
            $pendingTasks = $tasks->whereIn('status', ['todo', 'pending'])->count();
            $inProgressTasks = $tasks->where('status', 'in_progress')->count();
            $blockedTasks = $tasks->whereIn('status', ['blocked'])->count();
            $cancelledTasks = $tasks->where('status', 'cancelled')->count();

            $overdueTasks = $tasks
                ->filter(fn ($task) => $task->is_overdue)
                ->count();

            $taskProgress = $totalTasks > 0
                ? round((float) $tasks->avg('progress_percentage'), 2)
                : 0;

            $milestoneWeightTotal = (float) $milestones->sum('weight');

            $milestoneProgress = 0;

            if ($milestones->count() > 0 && $milestoneWeightTotal > 0) {
                $weightedTotal = $milestones->sum(function ($milestone) {
                    return ((float) $milestone->progress_percentage) * ((float) $milestone->weight);
                });

                $milestoneProgress = round($weightedTotal / $milestoneWeightTotal, 2);
            }

            if ($totalTasks > 0 && $milestones->count() > 0) {
                $projectProgress = round(($taskProgress * 0.7) + ($milestoneProgress * 0.3), 2);
            } elseif ($totalTasks > 0) {
                $projectProgress = $taskProgress;
            } elseif ($milestones->count() > 0) {
                $projectProgress = $milestoneProgress;
            } else {
                $projectProgress = 0;
            }

            $newStatus = $this->calculateProjectStatus(
                totalTasks: $totalTasks,
                completedTasks: $completedTasks,
                blockedTasks: $blockedTasks,
                inProgressTasks: $inProgressTasks,
                progress: $projectProgress,
                milestones: $milestones
            );

            $oldStatus = $project->status;
            $oldProgress = (float) ($project->progress_percentage ?? 0);

            $actualEndDate = $newStatus === 'completed'
                ? ($project->actual_end_date ?? now()->toDateString())
                : null;

            $project->update([
                'progress_percentage' => $projectProgress,
                'status' => $newStatus,
                'actual_end_date' => $actualEndDate,
            ]);

            if ($oldStatus !== $newStatus || round($oldProgress, 2) !== round($projectProgress, 2)) {
                ProjectStatusUpdate::create([
                    'project_id' => $project->id,
                    'update_title' => 'Project progress recalculated',
                    'update_description' => 'Project progress and status were recalculated automatically.',
                    'old_status' => $oldStatus,
                    'new_status' => $newStatus,
                    'old_progress_percentage' => (int) round($oldProgress),
                    'new_progress_percentage' => (int) round($projectProgress),
                    'update_type' => 'auto_calculation',
                    'metadata' => [
                        'total_tasks' => $totalTasks,
                        'completed_tasks' => $completedTasks,
                        'pending_tasks' => $pendingTasks,
                        'in_progress_tasks' => $inProgressTasks,
                        'blocked_tasks' => $blockedTasks,
                        'cancelled_tasks' => $cancelledTasks,
                        'overdue_tasks' => $overdueTasks,
                        'task_progress' => $taskProgress,
                        'milestone_progress' => $milestoneProgress,
                    ],
                ]);
            }

            return $this->buildProgressPayload($project->fresh());
        });
    }

    public function updateTaskProgress(ProjectTask $task, int $progressPercentage, ?string $status = null): array
    {
        return DB::transaction(function () use ($task, $progressPercentage, $status) {
            $oldStatus = $task->status;
            $oldProgress = (float) $task->progress_percentage;

            $newStatus = $status ?: $this->statusFromProgress($progressPercentage);

            if ($progressPercentage >= 100) {
                $newStatus = 'completed';
            }

            $task->update([
                'progress_percentage' => $progressPercentage,
                'status' => $newStatus,
                'completed_date' => $newStatus === 'completed' ? now()->toDateString() : null,
            ]);

            ProjectStatusUpdate::create([
                'project_id' => $task->project_id,
                'task_id' => $task->id,
                'update_title' => 'Task progress updated',
                'update_description' => 'Task progress or status was updated.',
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'old_progress_percentage' => (int) round($oldProgress),
                'new_progress_percentage' => $progressPercentage,
                'update_type' => 'task_progress',
                'metadata' => [
                    'task_id' => $task->id,
                    'task_title' => $task->task_title,
                ],
            ]);

            return $this->recalculate($task->project->fresh());
        });
    }

    public function buildProgressPayload(Project $project): array
    {
        $project->load([
            'tasks' => fn ($query) => $query->orderBy('task_order')->orderBy('created_at'),
            'milestones' => fn ($query) => $query->orderBy('target_date')->orderBy('created_at'),
            'statusUpdates' => fn ($query) => $query->latest()->limit(15),
        ]);

        $tasks = $project->tasks;
        $milestones = $project->milestones;

        $totalTasks = $tasks->count();
        $completedTasks = $tasks->where('status', 'completed')->count();
        $pendingTasks = $tasks->whereIn('status', ['todo', 'pending'])->count();
        $inProgressTasks = $tasks->where('status', 'in_progress')->count();
        $blockedTasks = $tasks->where('status', 'blocked')->count();
        $cancelledTasks = $tasks->where('status', 'cancelled')->count();
        $overdueTasks = $tasks->filter(fn ($task) => $task->is_overdue)->count();

        $totalMilestones = $milestones->count();
        $completedMilestones = $milestones->where('status', 'completed')->count();
        $pendingMilestones = $milestones->where('status', 'pending')->count();
        $inProgressMilestones = $milestones->where('status', 'in_progress')->count();
        $blockedMilestones = $milestones->where('status', 'blocked')->count();

        return [
            'project' => [
                'id' => $project->id,
                'project_name' => $project->project_name,
                'project_code' => $project->project_code,
                'status' => $project->status,
                'priority' => $project->priority,
                'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                'start_date' => optional($project->start_date)->format('Y-m-d'),
                'target_end_date' => optional($project->target_end_date)->format('Y-m-d'),
                'actual_end_date' => optional($project->actual_end_date)->format('Y-m-d'),
            ],
            'summary' => [
                'total_tasks' => $totalTasks,
                'completed_tasks' => $completedTasks,
                'pending_tasks' => $pendingTasks,
                'in_progress_tasks' => $inProgressTasks,
                'blocked_tasks' => $blockedTasks,
                'cancelled_tasks' => $cancelledTasks,
                'overdue_tasks' => $overdueTasks,
                'total_milestones' => $totalMilestones,
                'completed_milestones' => $completedMilestones,
                'pending_milestones' => $pendingMilestones,
                'in_progress_milestones' => $inProgressMilestones,
                'blocked_milestones' => $blockedMilestones,
                'empty_progress_state' => $totalTasks === 0 && $totalMilestones === 0,
            ],
            'charts' => [
                'tasks_by_status' => [
                    ['status' => 'todo', 'label' => 'To Do', 'value' => $pendingTasks],
                    ['status' => 'in_progress', 'label' => 'In Progress', 'value' => $inProgressTasks],
                    ['status' => 'blocked', 'label' => 'Blocked', 'value' => $blockedTasks],
                    ['status' => 'completed', 'label' => 'Completed', 'value' => $completedTasks],
                    ['status' => 'cancelled', 'label' => 'Cancelled', 'value' => $cancelledTasks],
                ],
                'milestones_by_status' => [
                    ['status' => 'pending', 'label' => 'Pending', 'value' => $pendingMilestones],
                    ['status' => 'in_progress', 'label' => 'In Progress', 'value' => $inProgressMilestones],
                    ['status' => 'blocked', 'label' => 'Blocked', 'value' => $blockedMilestones],
                    ['status' => 'completed', 'label' => 'Completed', 'value' => $completedMilestones],
                ],
            ],
            'tasks' => $tasks,
            'milestones' => $milestones,
            'recent_updates' => $project->statusUpdates,
            'status_history' => $project->statusUpdates,
        ];
    }

    private function calculateProjectStatus(
        int $totalTasks,
        int $completedTasks,
        int $blockedTasks,
        int $inProgressTasks,
        float $progress,
        $milestones
    ): string {
        if ($totalTasks === 0 && $milestones->count() === 0) {
            return 'not_started';
        }

        if ($progress >= 100) {
            return 'completed';
        }

        if ($blockedTasks > 0 || $milestones->where('status', 'blocked')->count() > 0) {
            return 'on_hold';
        }

        if ($inProgressTasks > 0 || $milestones->where('status', 'in_progress')->count() > 0 || $progress > 0) {
            return 'in_progress';
        }

        return 'not_started';
    }

    private function statusFromProgress(int $progressPercentage): string
    {
        if ($progressPercentage >= 100) {
            return 'completed';
        }

        if ($progressPercentage > 0) {
            return 'in_progress';
        }

        return 'todo';
    }
}
PHP

cat > backend/app/Models/ProjectStatusUpdate.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProjectStatusUpdate extends Model
{
    use HasUuids;

    protected $fillable = [
        'project_id',
        'task_id',
        'milestone_id',
        'update_title',
        'update_description',
        'old_status',
        'new_status',
        'old_progress_percentage',
        'new_progress_percentage',
        'update_type',
        'metadata',
    ];

    protected $casts = [
        'old_progress_percentage' => 'integer',
        'new_progress_percentage' => 'integer',
        'metadata' => 'array',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function task()
    {
        return $this->belongsTo(ProjectTask::class, 'task_id');
    }

    public function milestone()
    {
        return $this->belongsTo(ProjectMilestone::class, 'milestone_id');
    }
}
PHP

cat > backend/app/Http/Controllers/Api/V1/ProjectProgressController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectProgressController extends Controller
{
    public function show(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'success' => true,
            'message' => 'Project progress retrieved successfully.',
            'data' => $service->buildProgressPayload($project),
        ]);
    }

    public function recalculate(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'success' => true,
            'message' => 'Project progress recalculated successfully.',
            'data' => $service->recalculate($project),
        ]);
    }

    public function updateTaskProgress(
        Request $request,
        Project $project,
        ProjectTask $task,
        ProjectProgressService $service
    ) {
        $this->authorizeProject($request, $project);

        abort_if(
            $task->project_id !== $project->id || $task->user_id !== $request->user()->id,
            403,
            'Unauthorized task access.'
        );

        $validated = $request->validate([
            'progress_percentage' => ['required', 'integer', 'min:0', 'max:100'],
            'status' => ['nullable', Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled'])],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Task progress updated successfully.',
            'data' => $service->updateTaskProgress(
                $task,
                (int) $validated['progress_percentage'],
                $validated['status'] ?? null
            ),
        ]);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if(
            $project->user_id !== $request->user()->id,
            403,
            'Unauthorized project access.'
        );
    }
}
PHP

cat > backend/app/Http/Controllers/Api/V1/ProjectMilestoneController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectMilestone;
use App\Models\ProjectStatusUpdate;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProjectMilestoneController extends Controller
{
    private array $statuses = [
        'pending',
        'in_progress',
        'completed',
        'blocked',
        'cancelled',
    ];

    public function index(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'success' => true,
            'message' => 'Project milestones retrieved successfully.',
            'data' => $project->milestones()->orderBy('target_date')->orderBy('created_at')->get(),
        ]);
    }

    public function store(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'milestone_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'target_date' => ['nullable', 'date'],
            'status' => ['nullable', Rule::in($this->statuses)],
            'progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'weight' => ['nullable', 'numeric', 'min:0.1'],
            'metadata' => ['nullable', 'array'],
        ]);

        $result = DB::transaction(function () use ($validated, $project, $service) {
            $progress = (int) ($validated['progress_percentage'] ?? 0);
            $status = $validated['status'] ?? $this->statusFromProgress($progress);

            if ($status === 'completed') {
                $progress = 100;
            }

            $milestone = ProjectMilestone::create([
                'project_id' => $project->id,
                'milestone_name' => $validated['milestone_name'],
                'description' => $validated['description'] ?? null,
                'target_date' => $validated['target_date'] ?? null,
                'status' => $status,
                'progress_percentage' => $progress,
                'weight' => $validated['weight'] ?? 1,
                'metadata' => $validated['metadata'] ?? null,
                'completed_date' => $progress >= 100 ? now()->toDateString() : null,
            ]);

            ProjectStatusUpdate::create([
                'project_id' => $project->id,
                'milestone_id' => $milestone->id,
                'update_title' => 'Milestone created',
                'update_description' => 'A new milestone was added to the project.',
                'new_status' => $milestone->status,
                'new_progress_percentage' => $milestone->progress_percentage,
                'update_type' => 'milestone_progress',
                'metadata' => [
                    'milestone_id' => $milestone->id,
                    'milestone_name' => $milestone->milestone_name,
                ],
            ]);

            return [
                'milestone' => $milestone->fresh(),
                'project_progress' => $service->recalculate($project->fresh()),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Project milestone created successfully.',
            'data' => $result,
        ], 201);
    }

    public function update(
        Request $request,
        Project $project,
        ProjectMilestone $milestone,
        ProjectProgressService $service
    ) {
        $this->authorizeProject($request, $project);
        $this->authorizeMilestoneBelongsToProject($project, $milestone);

        $validated = $request->validate([
            'milestone_name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'target_date' => ['nullable', 'date'],
            'status' => ['sometimes', Rule::in($this->statuses)],
            'progress_percentage' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'weight' => ['sometimes', 'numeric', 'min:0.1'],
            'metadata' => ['nullable', 'array'],
        ]);

        $result = DB::transaction(function () use ($validated, $milestone, $project, $service) {
            $oldStatus = $milestone->status;
            $oldProgress = (int) $milestone->progress_percentage;

            if (array_key_exists('progress_percentage', $validated)) {
                if ((int) $validated['progress_percentage'] >= 100) {
                    $validated['status'] = 'completed';
                    $validated['progress_percentage'] = 100;
                    $validated['completed_date'] = now()->toDateString();
                } elseif ((int) $validated['progress_percentage'] > 0 && !isset($validated['status'])) {
                    $validated['status'] = 'in_progress';
                    $validated['completed_date'] = null;
                } elseif ((int) $validated['progress_percentage'] === 0 && !isset($validated['status'])) {
                    $validated['status'] = 'pending';
                    $validated['completed_date'] = null;
                }
            }

            if (($validated['status'] ?? null) === 'completed') {
                $validated['progress_percentage'] = 100;
                $validated['completed_date'] = now()->toDateString();
            }

            if (($validated['status'] ?? null) && $validated['status'] !== 'completed') {
                $validated['completed_date'] = null;
            }

            $milestone->update($validated);
            $freshMilestone = $milestone->fresh();

            ProjectStatusUpdate::create([
                'project_id' => $project->id,
                'milestone_id' => $freshMilestone->id,
                'update_title' => 'Milestone progress updated',
                'update_description' => 'Milestone status or progress was updated.',
                'old_status' => $oldStatus,
                'new_status' => $freshMilestone->status,
                'old_progress_percentage' => $oldProgress,
                'new_progress_percentage' => $freshMilestone->progress_percentage,
                'update_type' => 'milestone_progress',
                'metadata' => [
                    'milestone_id' => $freshMilestone->id,
                    'milestone_name' => $freshMilestone->milestone_name,
                ],
            ]);

            return [
                'milestone' => $freshMilestone,
                'project_progress' => $service->recalculate($project->fresh()),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Project milestone updated successfully.',
            'data' => $result,
        ]);
    }

    public function destroy(
        Request $request,
        Project $project,
        ProjectMilestone $milestone,
        ProjectProgressService $service
    ) {
        $this->authorizeProject($request, $project);
        $this->authorizeMilestoneBelongsToProject($project, $milestone);

        $result = DB::transaction(function () use ($project, $milestone, $service) {
            ProjectStatusUpdate::create([
                'project_id' => $project->id,
                'milestone_id' => $milestone->id,
                'update_title' => 'Milestone deleted',
                'update_description' => 'A milestone was deleted from the project.',
                'old_status' => $milestone->status,
                'old_progress_percentage' => $milestone->progress_percentage,
                'update_type' => 'milestone_progress',
                'metadata' => [
                    'milestone_id' => $milestone->id,
                    'milestone_name' => $milestone->milestone_name,
                ],
            ]);

            $milestone->delete();

            return $service->recalculate($project->fresh());
        });

        return response()->json([
            'success' => true,
            'message' => 'Project milestone deleted successfully.',
            'data' => $result,
        ]);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if(
            $project->user_id !== $request->user()->id,
            403,
            'Unauthorized project access.'
        );
    }

    private function authorizeMilestoneBelongsToProject(Project $project, ProjectMilestone $milestone): void
    {
        abort_if(
            $milestone->project_id !== $project->id,
            403,
            'Unauthorized milestone access.'
        );
    }

    private function statusFromProgress(int $progress): string
    {
        if ($progress >= 100) {
            return 'completed';
        }

        if ($progress > 0) {
            return 'in_progress';
        }

        return 'pending';
    }
}
PHP

cat > backend/app/Http/Controllers/Api/V1/ProjectStatusUpdateController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectStatusUpdate;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectStatusUpdateController extends Controller
{
    public function index(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'type' => ['nullable', Rule::in(['manual', 'task_progress', 'milestone_progress', 'auto_calculation', 'status_change'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $updates = ProjectStatusUpdate::query()
            ->where('project_id', $project->id)
            ->when($validated['type'] ?? null, fn ($query, $type) => $query->where('update_type', $type))
            ->latest()
            ->paginate($validated['per_page'] ?? 20);

        return response()->json([
            'success' => true,
            'message' => 'Project status updates retrieved successfully.',
            'data' => $updates->items(),
            'meta' => [
                'current_page' => $updates->currentPage(),
                'last_page' => $updates->lastPage(),
                'per_page' => $updates->perPage(),
                'total' => $updates->total(),
            ],
        ]);
    }

    public function store(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'update_title' => ['required', 'string', 'max:255'],
            'update_description' => ['nullable', 'string'],
            'new_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled'])],
            'new_progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'metadata' => ['nullable', 'array'],
        ]);

        $oldStatus = $project->status;
        $oldProgress = (int) round((float) ($project->progress_percentage ?? 0));

        $update = ProjectStatusUpdate::create([
            'project_id' => $project->id,
            'update_title' => $validated['update_title'],
            'update_description' => $validated['update_description'] ?? null,
            'old_status' => $oldStatus,
            'new_status' => $validated['new_status'] ?? $oldStatus,
            'old_progress_percentage' => $oldProgress,
            'new_progress_percentage' => $validated['new_progress_percentage'] ?? $oldProgress,
            'update_type' => 'manual',
            'metadata' => $validated['metadata'] ?? null,
        ]);

        $projectPayload = [];

        if (isset($validated['new_status'])) {
            $projectPayload['status'] = $validated['new_status'];
        }

        if (array_key_exists('new_progress_percentage', $validated)) {
            $projectPayload['progress_percentage'] = $validated['new_progress_percentage'];
        }

        if (($projectPayload['status'] ?? null) === 'completed') {
            $projectPayload['progress_percentage'] = 100;
            $projectPayload['actual_end_date'] = now()->toDateString();
        }

        if (!empty($projectPayload)) {
            $project->update($projectPayload);
        }

        return response()->json([
            'success' => true,
            'message' => 'Project status update created successfully.',
            'data' => [
                'status_update' => $update->fresh(),
                'project_progress' => $service->buildProgressPayload($project->fresh()),
            ],
        ], 201);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if(
            $project->user_id !== $request->user()->id,
            403,
            'Unauthorized project access.'
        );
    }
}
PHP

python3 <<'PY'
from pathlib import Path

path = Path("backend/routes/api.php")
text = path.read_text()

old = """        Route::prefix('projects')->group(function () {
            Route::get('/dashboard', [ProjectDashboardController::class, 'summary']);

            Route::get('/', [ProjectController::class, 'index']);
            Route::post('/', [ProjectController::class, 'store']);
            Route::get('/{project}', [ProjectController::class, 'show']);
            Route::put('/{project}', [ProjectController::class, 'update']);
            Route::patch('/{project}', [ProjectController::class, 'update']);
            Route::delete('/{project}', [ProjectController::class, 'destroy']);

            Route::get('/{project}/progress', [ProjectProgressController::class, 'show']);
            Route::post('/{project}/progress/recalculate', [ProjectProgressController::class, 'recalculate']);

            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);
            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);

            Route::get('/{project}/milestones', [ProjectMilestoneController::class, 'index']);
            Route::post('/{project}/milestones', [ProjectMilestoneController::class, 'store']);

            Route::get('/{project}/status-updates', [ProjectStatusUpdateController::class, 'index']);
            Route::post('/{project}/status-updates', [ProjectStatusUpdateController::class, 'store']);
        });"""

new = """        Route::prefix('projects')->group(function () {
            Route::get('/dashboard', [ProjectDashboardController::class, 'summary']);

            Route::get('/', [ProjectController::class, 'index']);
            Route::post('/', [ProjectController::class, 'store']);
            Route::get('/{project}', [ProjectController::class, 'show']);
            Route::put('/{project}', [ProjectController::class, 'update']);
            Route::patch('/{project}', [ProjectController::class, 'update']);
            Route::delete('/{project}', [ProjectController::class, 'destroy']);

            Route::get('/{project}/progress', [ProjectProgressController::class, 'show']);
            Route::post('/{project}/progress/recalculate', [ProjectProgressController::class, 'recalculate']);
            Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);

            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);
            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);

            Route::get('/{project}/milestones', [ProjectMilestoneController::class, 'index']);
            Route::post('/{project}/milestones', [ProjectMilestoneController::class, 'store']);
            Route::put('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
            Route::patch('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'update']);
            Route::delete('/{project}/milestones/{milestone}', [ProjectMilestoneController::class, 'destroy']);

            Route::get('/{project}/status-updates', [ProjectStatusUpdateController::class, 'index']);
            Route::post('/{project}/status-updates', [ProjectStatusUpdateController::class, 'store']);
        });"""

if old not in text:
    raise SystemExit("Projects route block was not found exactly. Please update api.php manually.")
path.write_text(text.replace(old, new))
PY

cat > frontend/src/views/ProjectProgressView.vue <<'VUE'
<script setup>
import { computed, onMounted, ref } from "vue";
import {
  getProjects,
  getProjectProgress,
  recalculateProjectProgress,
} from "@/services/projectService";

const projects = ref([]);
const selectedProjectId = ref("");
const progress = ref(null);
const loading = ref(false);
const recalculating = ref(false);
const errorMessage = ref("");

function normalizeList(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 });
  projects.value = normalizeList(response);

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id;
  }
}

async function loadProgress() {
  if (!selectedProjectId.value) return;

  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjectProgress(selectedProjectId.value);
    progress.value = response.data;
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load project progress.";
  } finally {
    loading.value = false;
  }
}

async function recalculate() {
  if (!selectedProjectId.value) return;

  recalculating.value = true;
  errorMessage.value = "";

  try {
    const response = await recalculateProjectProgress(selectedProjectId.value);
    progress.value = response.data;
    await loadProjects();
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to recalculate project progress.";
  } finally {
    recalculating.value = false;
  }
}

function cleanText(value) {
  if (!value) return "-";
  return String(value).replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatDate(value) {
  if (!value) return "Not set";
  return new Date(value).toLocaleDateString("en-GB");
}

function barWidth(value, max) {
  if (!max) return "0%";
  return `${Math.round((Number(value || 0) / max) * 100)}%`;
}

const summary = computed(() => progress.value?.summary || {});
const project = computed(() => progress.value?.project || {});
const taskChart = computed(() => progress.value?.charts?.tasks_by_status || []);
const milestoneChart = computed(() => progress.value?.charts?.milestones_by_status || []);
const maxTaskValue = computed(() => Math.max(...taskChart.value.map((item) => Number(item.value || 0)), 1));
const maxMilestoneValue = computed(() => Math.max(...milestoneChart.value.map((item) => Number(item.value || 0)), 1));

onMounted(async () => {
  await loadProjects();
  await loadProgress();
});
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">STEP 59</p>
          <h1 class="mt-1 text-3xl font-black text-gray-900">Project Progress / Status</h1>
          <p class="mt-2 text-gray-500">
            Verify progress calculation, task counts, milestones, recent updates, history, charts, and empty state.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <select
            v-model="selectedProjectId"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-bold outline-none"
            @change="loadProgress"
          >
            <option value="">Select Project</option>
            <option v-for="item in projects" :key="item.id" :value="item.id">
              {{ item.project_name }}
            </option>
          </select>

          <button
            type="button"
            class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
            @click="loadProgress"
          >
            Refresh
          </button>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-sm hover:bg-blue-700"
            :disabled="recalculating"
            @click="recalculate"
          >
            {{ recalculating ? "Recalculating..." : "Recalculate" }}
          </button>
        </div>
      </div>

      <div v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
        {{ errorMessage }}
      </div>

      <div v-if="loading" class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm">
        Loading project progress...
      </div>

      <div
        v-else-if="!selectedProjectId || !progress"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center shadow-sm"
      >
        <h2 class="text-xl font-black text-gray-900">No project selected</h2>
        <p class="mt-2 text-sm text-gray-500">Create or select a project to view progress.</p>
      </div>

      <template v-else>
        <div
          v-if="summary.empty_progress_state"
          class="rounded-2xl border border-dashed border-gray-300 bg-white p-10 text-center shadow-sm"
        >
          <h2 class="text-xl font-black text-gray-900">Empty progress state</h2>
          <p class="mt-2 text-sm text-gray-500">
            This project has no tasks and no milestones yet. Progress is correctly calculated as 0%.
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-2xl font-black text-gray-900">{{ project.project_name }}</h2>
              <p class="mt-1 text-sm text-gray-500">{{ project.project_code || "No Code" }}</p>
              <p class="mt-2 text-sm text-gray-500">
                Status: <strong>{{ cleanText(project.status) }}</strong> —
                Target: <strong>{{ formatDate(project.target_end_date) }}</strong>
              </p>
            </div>

            <div class="text-right">
              <p class="text-sm font-bold text-gray-500">Progress</p>
              <p class="text-4xl font-black text-blue-600">{{ project.progress_percentage || 0 }}%</p>
            </div>
          </div>

          <div class="mt-5 h-4 overflow-hidden rounded-full bg-gray-200">
            <div
              class="h-full rounded-full bg-blue-600 transition-all"
              :style="{ width: `${project.progress_percentage || 0}%` }"
            ></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-4 xl:grid-cols-8">
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Total Tasks</p>
            <p class="mt-2 text-2xl font-black">{{ summary.total_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Completed</p>
            <p class="mt-2 text-2xl font-black text-emerald-600">{{ summary.completed_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Pending</p>
            <p class="mt-2 text-2xl font-black text-gray-700">{{ summary.pending_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">In Progress</p>
            <p class="mt-2 text-2xl font-black text-blue-600">{{ summary.in_progress_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Blocked</p>
            <p class="mt-2 text-2xl font-black text-yellow-600">{{ summary.blocked_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Overdue</p>
            <p class="mt-2 text-2xl font-black text-red-600">{{ summary.overdue_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Milestones</p>
            <p class="mt-2 text-2xl font-black">{{ summary.total_milestones || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Done Milestones</p>
            <p class="mt-2 text-2xl font-black text-emerald-600">{{ summary.completed_milestones || 0 }}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-5 xl:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <h2 class="text-lg font-black text-gray-900">Tasks by Status</h2>
            <div class="mt-4 space-y-4">
              <div v-for="item in taskChart" :key="item.status">
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold">{{ item.label }}</span>
                  <span>{{ item.value }}</span>
                </div>
                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div class="h-full rounded-full bg-blue-600" :style="{ width: barWidth(item.value, maxTaskValue) }"></div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <h2 class="text-lg font-black text-gray-900">Milestones by Status</h2>
            <div class="mt-4 space-y-4">
              <div v-for="item in milestoneChart" :key="item.status">
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold">{{ item.label }}</span>
                  <span>{{ item.value }}</span>
                </div>
                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div class="h-full rounded-full bg-emerald-600" :style="{ width: barWidth(item.value, maxMilestoneValue) }"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <h2 class="text-lg font-black text-gray-900">Recent Updates / Status History</h2>

          <div
            v-if="!progress.recent_updates || progress.recent_updates.length === 0"
            class="mt-4 rounded-xl border border-dashed border-gray-300 p-8 text-center text-sm text-gray-400"
          >
            No status history available.
          </div>

          <div v-else class="mt-4 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead>
                <tr class="bg-gray-50">
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Title</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Type</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Old</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">New</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Progress</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Created</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="update in progress.recent_updates" :key="update.id">
                  <td class="px-4 py-3 text-sm font-bold text-gray-900">{{ update.update_title }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.update_type) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.old_status) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.new_status) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">
                    {{ update.old_progress_percentage ?? "-" }} → {{ update.new_progress_percentage ?? "-" }}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-500">{{ update.created_at }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
VUE

cat > frontend/src/views/ProjectStatusUpdatesView.vue <<'VUE'
<script setup>
import { onMounted, ref } from "vue";
import {
  getProjects,
  getProjectStatusUpdates,
} from "@/services/projectService";

const projects = ref([]);
const selectedProjectId = ref("");
const updates = ref([]);
const loading = ref(false);
const errorMessage = ref("");

function normalizeProjects(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

function cleanText(value) {
  if (!value) return "-";
  return String(value).replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 });
  projects.value = normalizeProjects(response);

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id;
  }
}

async function loadUpdates() {
  if (!selectedProjectId.value) return;

  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjectStatusUpdates(selectedProjectId.value);
    updates.value = Array.isArray(response?.data) ? response.data : [];
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load project status updates.";
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await loadProjects();
  await loadUpdates();
});
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">STEP 59</p>
          <h1 class="mt-1 text-3xl font-black text-gray-900">Project Status Updates</h1>
          <p class="mt-2 text-gray-500">Review recent updates, automatic recalculations, and status history.</p>
        </div>

        <div class="flex flex-wrap gap-3">
          <select
            v-model="selectedProjectId"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-bold outline-none"
            @change="loadUpdates"
          >
            <option value="">Select Project</option>
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.project_name }}
            </option>
          </select>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white"
            @click="loadUpdates"
          >
            Refresh
          </button>
        </div>
      </div>

      <div v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
        {{ errorMessage }}
      </div>

      <div v-if="loading" class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm">
        Loading status updates...
      </div>

      <div
        v-else-if="updates.length === 0"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center shadow-sm"
      >
        <h2 class="text-xl font-black text-gray-900">No status updates found</h2>
        <p class="mt-2 text-sm text-gray-500">
          Recalculate progress, update a task, or create a milestone to generate history.
        </p>
      </div>

      <div v-else class="overflow-hidden rounded-2xl bg-white shadow-sm">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Update</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Type</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Old Status</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">New Status</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Progress</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Created</th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100">
              <tr v-for="update in updates" :key="update.id" class="hover:bg-gray-50">
                <td class="px-5 py-4">
                  <p class="font-black text-gray-900">{{ update.update_title }}</p>
                  <p class="mt-1 text-xs text-gray-500">{{ update.update_description || "No description." }}</p>
                </td>
                <td class="px-5 py-4 text-sm font-bold text-gray-700">{{ cleanText(update.update_type) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{{ cleanText(update.old_status) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{{ cleanText(update.new_status) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">
                  {{ update.old_progress_percentage ?? "-" }} → {{ update.new_progress_percentage ?? "-" }}
                </td>
                <td class="px-5 py-4 text-sm text-gray-500">{{ update.created_at }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
VUE

echo "=================================================="
echo "Clearing Laravel cache"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan optimize:clear && php artisan route:clear && php artisan config:clear"

echo "=================================================="
echo "Checking PHP syntax"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Services/Projects/ProjectProgressService.php"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/V1/ProjectProgressController.php"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/V1/ProjectMilestoneController.php"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/V1/ProjectStatusUpdateController.php"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Models/ProjectStatusUpdate.php"

echo "=================================================="
echo "Checking Project routes"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -Ei 'projects|progress|milestones|status-updates'"

echo "=================================================="
echo "Building frontend"
echo "=================================================="

cd frontend
npm run build

echo "=================================================="
echo "STEP 59 update completed successfully."
echo "Backup saved in: $BACKUP_DIR"
echo "=================================================="
