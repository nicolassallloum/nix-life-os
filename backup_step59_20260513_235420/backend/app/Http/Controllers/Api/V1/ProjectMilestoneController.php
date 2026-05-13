<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectMilestone;
use App\Models\ProjectStatusUpdate;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProjectMilestoneController extends Controller
{
    public function index(Project $project)
    {
        return response()->json([
            'success' => true,
            'message' => 'Project milestones retrieved successfully.',
            'data' => $project->milestones()->orderBy('target_date')->get(),
        ]);
    }

    public function store(Request $request, Project $project, ProjectProgressService $service)
    {
        $validated = $request->validate([
            'milestone_name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'target_date' => ['nullable', 'date'],
            'status' => ['nullable', 'string', 'in:pending,in_progress,completed,blocked,cancelled'],
            'progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'weight' => ['nullable', 'numeric', 'min:0.1'],
            'metadata' => ['nullable', 'array'],
        ]);

        $milestone = DB::transaction(function () use ($validated, $project, $service) {
            $milestone = ProjectMilestone::create([
                'project_id' => $project->id,
                'milestone_name' => $validated['milestone_name'],
                'description' => $validated['description'] ?? null,
                'target_date' => $validated['target_date'] ?? null,
                'status' => $validated['status'] ?? 'pending',
                'progress_percentage' => $validated['progress_percentage'] ?? 0,
                'weight' => $validated['weight'] ?? 1,
                'metadata' => $validated['metadata'] ?? null,
                'completed_date' => (($validated['progress_percentage'] ?? 0) >= 100) ? now()->toDateString() : null,
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

            $service->recalculate($project->fresh());

            return $milestone;
        });

        return response()->json([
            'success' => true,
            'message' => 'Project milestone created successfully.',
            'data' => $milestone,
        ], 201);
    }

    public function update(Request $request, ProjectMilestone $milestone, ProjectProgressService $service)
    {
        $validated = $request->validate([
            'milestone_name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'target_date' => ['nullable', 'date'],
            'status' => ['sometimes', 'string', 'in:pending,in_progress,completed,blocked,cancelled'],
            'progress_percentage' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'weight' => ['sometimes', 'numeric', 'min:0.1'],
            'metadata' => ['nullable', 'array'],
        ]);

        $result = DB::transaction(function () use ($validated, $milestone, $service) {
            $oldStatus = $milestone->status;
            $oldProgress = $milestone->progress_percentage;

            if (array_key_exists('progress_percentage', $validated)) {
                if ($validated['progress_percentage'] >= 100) {
                    $validated['status'] = 'completed';
                    $validated['completed_date'] = now()->toDateString();
                } elseif ($validated['progress_percentage'] > 0 && !isset($validated['status'])) {
                    $validated['status'] = 'in_progress';
                    $validated['completed_date'] = null;
                }
            }

            if (($validated['status'] ?? null) === 'completed') {
                $validated['progress_percentage'] = 100;
                $validated['completed_date'] = now()->toDateString();
            }

            $milestone->update($validated);

            ProjectStatusUpdate::create([
                'project_id' => $milestone->project_id,
                'milestone_id' => $milestone->id,
                'update_title' => 'Milestone progress updated',
                'update_description' => 'Milestone status or progress was updated.',
                'old_status' => $oldStatus,
                'new_status' => $milestone->fresh()->status,
                'old_progress_percentage' => $oldProgress,
                'new_progress_percentage' => $milestone->fresh()->progress_percentage,
                'update_type' => 'milestone_progress',
                'metadata' => [
                    'milestone_id' => $milestone->id,
                    'milestone_name' => $milestone->milestone_name,
                ],
            ]);

            $projectProgress = $service->recalculate($milestone->project->fresh());

            return [
                'milestone' => $milestone->fresh(),
                'project_progress' => $projectProgress,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Project milestone updated successfully.',
            'data' => $result,
        ]);
    }

    public function destroy(ProjectMilestone $milestone, ProjectProgressService $service)
    {
        $project = $milestone->project;

        $milestone->delete();

        $progress = $service->recalculate($project->fresh());

        return response()->json([
            'success' => true,
            'message' => 'Project milestone deleted successfully.',
            'data' => $progress,
        ]);
    }
}