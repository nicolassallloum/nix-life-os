<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectStatusUpdate;
use Illuminate\Http\Request;

class ProjectStatusUpdateController extends Controller
{
    public function index(Project $project)
    {
        return response()->json([
            'success' => true,
            'message' => 'Project status updates retrieved successfully.',
            'data' => $project->statusUpdates()
                ->latest()
                ->paginate(20),
        ]);
    }

    public function store(Request $request, Project $project)
    {
        $validated = $request->validate([
            'update_title' => ['required', 'string', 'max:255'],
            'update_description' => ['nullable', 'string'],
            'old_status' => ['nullable', 'string'],
            'new_status' => ['nullable', 'string'],
            'old_progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'new_progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'metadata' => ['nullable', 'array'],
        ]);

        $statusUpdate = ProjectStatusUpdate::create([
            'project_id' => $project->id,
            'update_title' => $validated['update_title'],
            'update_description' => $validated['update_description'] ?? null,
            'old_status' => $validated['old_status'] ?? null,
            'new_status' => $validated['new_status'] ?? null,
            'old_progress_percentage' => $validated['old_progress_percentage'] ?? null,
            'new_progress_percentage' => $validated['new_progress_percentage'] ?? null,
            'update_type' => 'manual',
            'metadata' => $validated['metadata'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project status update created successfully.',
            'data' => $statusUpdate,
        ], 201);
    }
}