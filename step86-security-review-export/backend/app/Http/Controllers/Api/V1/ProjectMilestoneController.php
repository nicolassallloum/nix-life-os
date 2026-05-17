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
