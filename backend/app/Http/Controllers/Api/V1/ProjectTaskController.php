<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ProjectTaskController extends Controller
{
    private string $schema = 'public';
    private string $table = 'project_tasks';

    private function tableName(): string
    {
        return $this->schema . '.' . $this->table;
    }

    private function columns(): array
    {
        return DB::table('information_schema.columns')
            ->where('table_schema', $this->schema)
            ->where('table_name', $this->table)
            ->pluck('column_name')
            ->toArray();
    }

    private function firstExistingColumn(array $columns, array $candidates): ?string
    {
        foreach ($candidates as $candidate) {
            if (in_array($candidate, $columns, true)) {
                return $candidate;
            }
        }

        return null;
    }

    public function index(Request $request)
    {
        try {
            $userId = (string) $request->user()->id;
            $columns = $this->columns();

            $titleColumn = $this->firstExistingColumn($columns, [
                'task_title',
                'title',
                'task_name',
                'name',
            ]);

            $descriptionColumn = $this->firstExistingColumn($columns, [
                'task_description',
                'description',
                'details',
            ]);

            $dueDateColumn = $this->firstExistingColumn($columns, [
                'due_date',
                'target_date',
                'end_date',
                'created_at',
            ]);

            $query = DB::table($this->tableName())
                ->where('user_id', $userId);

            $projectId = null;

            if ($request->route('project')) {
                $routeProject = $request->route('project');
                $projectId = is_object($routeProject) && isset($routeProject->id)
                    ? $routeProject->id
                    : $routeProject;
            }

            if (!$projectId && preg_match('#/projects/([^/]+)/tasks#', $request->path(), $matches)) {
                $projectId = $matches[1];
            }

            if (!$projectId && $request->filled('project_id')) {
                $projectId = $request->project_id;
            }

            if ($projectId && in_array('project_id', $columns, true)) {
                $projectExists = DB::table('projects')
                    ->where('id', $projectId)
                    ->where('user_id', $userId)
                    ->exists();

                abort_if(!$projectExists, 403, 'Unauthorized project access.');

                $query->where('project_id', $projectId);
            }

            if ($request->filled('status') && in_array('status', $columns, true)) {
                $query->where('status', $request->status);
            }

            if ($request->filled('priority') && in_array('priority', $columns, true)) {
                $query->where('priority', $request->priority);
            }

            if ($request->filled('search')) {
                $search = $request->search;

                $query->where(function ($subQuery) use ($search, $titleColumn, $descriptionColumn) {
                    if ($titleColumn) {
                        $subQuery->orWhere($titleColumn, 'ILIKE', "%{$search}%");
                    }

                    if ($descriptionColumn) {
                        $subQuery->orWhere($descriptionColumn, 'ILIKE', "%{$search}%");
                    }
                });
            }

            if (in_array('task_order', $columns, true)) {
                $query->orderBy('task_order');
            } elseif ($dueDateColumn) {
                $query->orderByRaw("CASE WHEN {$dueDateColumn} IS NULL THEN 1 ELSE 0 END");
                $query->orderBy($dueDateColumn);
            } elseif ($titleColumn) {
                $query->orderBy($titleColumn);
            } elseif (in_array('created_at', $columns, true)) {
                $query->orderByDesc('created_at');
            }

            $tasks = $query->paginate((int) $request->get('per_page', 30));

            return response()->json([
                'success' => true,
                'data' => $tasks,
            ]);
        } catch (\Throwable $e) {
            Log::error('Project tasks index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project tasks index failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function byProject(Request $request, $project)
    {
        try {
            $userId = (string) $request->user()->id;
            $columns = $this->columns();

            $projectId = is_object($project) && isset($project->id)
                ? $project->id
                : $project;

            $projectExists = DB::table('projects')
                ->where('id', $projectId)
                ->where('user_id', $userId)
                ->exists();

            abort_if(!$projectExists, 403, 'Unauthorized project access.');

            $query = DB::table($this->tableName())
                ->where('user_id', $userId)
                ->where('project_id', $projectId);

            if ($request->filled('status') && in_array('status', $columns, true)) {
                $query->where('status', $request->status);
            }

            if ($request->filled('priority') && in_array('priority', $columns, true)) {
                $query->where('priority', $request->priority);
            }

            if ($request->filled('search')) {
                $search = $request->search;

                $query->where(function ($subQuery) use ($search, $columns) {
                    if (in_array('title', $columns, true)) {
                        $subQuery->orWhere('title', 'ILIKE', "%{$search}%");
                    }

                    if (in_array('description', $columns, true)) {
                        $subQuery->orWhere('description', 'ILIKE', "%{$search}%");
                    }
                });
            }

            if (in_array('task_order', $columns, true)) {
                $query->orderBy('task_order');
            } elseif (in_array('due_date', $columns, true)) {
                $query->orderByRaw('CASE WHEN due_date IS NULL THEN 1 ELSE 0 END');
                $query->orderBy('due_date');
            } elseif (in_array('created_at', $columns, true)) {
                $query->orderByDesc('created_at');
            }

            return response()->json([
                'success' => true,
                'data' => $query->paginate((int) $request->get('per_page', 30)),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project tasks byProject failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project tasks by project failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $routeProjectId = $request->route('project');

            if ($routeProjectId && !$request->filled('project_id')) {
                $request->merge([
                    'project_id' => is_object($routeProjectId) && isset($routeProjectId->id)
                        ? $routeProjectId->id
                        : $routeProjectId,
                ]);
            }

            $validated = $request->validate([
                'project_id' => ['required', 'exists:projects,id'],
                'title' => ['required', 'string', 'max:200'],
                'description' => ['nullable', 'string'],
                'priority' => ['nullable', Rule::in(['low', 'medium', 'high', 'critical'])],
                'status' => ['nullable', Rule::in(['todo', 'in_progress', 'done', 'blocked'])],
                'start_date' => ['nullable', 'date'],
                'due_date' => ['nullable', 'date'],
                'assigned_to' => ['nullable', 'string', 'max:150'],
                'notes' => ['nullable', 'string'],
            ]);

            $userId = (string) $request->user()->id;

            $projectExists = DB::table('projects')
                ->where('id', $validated['project_id'])
                ->where('user_id', $userId)
                ->exists();

            abort_if(!$projectExists, 403, 'Unauthorized project access.');

            $columns = $this->columns();

            $titleColumn = $this->firstExistingColumn($columns, [
                'task_title',
                'title',
                'task_name',
                'name',
            ]);

            $descriptionColumn = $this->firstExistingColumn($columns, [
                'task_description',
                'description',
                'details',
            ]);

            if (!$titleColumn) {
                return response()->json([
                    'success' => false,
                    'message' => 'No task title column found in project_tasks table.',
                    'available_columns' => $columns,
                ], 422);
            }

            $insert = [];

            if (in_array('id', $columns, true)) {
                $insert['id'] = (string) Str::uuid();
            }

            if (in_array('project_id', $columns, true)) {
                $insert['project_id'] = $validated['project_id'];
            }

            if (in_array('user_id', $columns, true)) {
                $insert['user_id'] = $userId;
            }

            $insert[$titleColumn] = $validated['title'];

            if ($descriptionColumn) {
                $insert[$descriptionColumn] = $validated['description'] ?? null;
            }

            if (in_array('priority', $columns, true)) {
                $insert['priority'] = $validated['priority'] ?? 'medium';
            }

            if (in_array('status', $columns, true)) {
                $insert['status'] = $validated['status'] ?? 'todo';
            }

            if (in_array('task_order', $columns, true)) {
                $insert['task_order'] = 0;
            }

            if (in_array('start_date', $columns, true)) {
                $insert['start_date'] = $validated['start_date'] ?? null;
            }

            if (in_array('due_date', $columns, true)) {
                $insert['due_date'] = $validated['due_date'] ?? null;
            }

            if (in_array('assigned_to', $columns, true)) {
                $insert['assigned_to'] = $validated['assigned_to'] ?? null;
            }

            if (in_array('notes', $columns, true)) {
                $insert['notes'] = $validated['notes'] ?? null;
            }

            if (in_array('progress_percentage', $columns, true)) {
                $insert['progress_percentage'] = 0;
            }

            if (in_array('weight', $columns, true)) {
                $insert['weight'] = 1;
            }

            if (in_array('metadata', $columns, true)) {
                $insert['metadata'] = null;
            }

            if (in_array('created_at', $columns, true)) {
                $insert['created_at'] = now();
            }

            if (in_array('updated_at', $columns, true)) {
                $insert['updated_at'] = now();
            }

            DB::table($this->tableName())->insert($insert);

            $task = in_array('id', $columns, true)
                ? DB::table($this->tableName())->where('id', $insert['id'])->first()
                : DB::table($this->tableName())
                    ->where('project_id', $validated['project_id'])
                    ->where('user_id', $userId)
                    ->orderByDesc('created_at')
                    ->first();

            return response()->json([
                'success' => true,
                'message' => 'Project task created successfully.',
                'data' => $task,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Project tasks store failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task creation failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function show(Request $request, $task)
    {
        try {
            $userId = (string) $request->user()->id;

            $row = DB::table($this->tableName())
                ->where('id', $task)
                ->where('user_id', $userId)
                ->first();

            abort_if(!$row, 404, 'Task not found.');

            return response()->json([
                'success' => true,
                'data' => $row,
            ]);
        } catch (\Throwable $e) {
            Log::error('Project tasks show failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task show failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $task)
    {
        try {
            $userId = (string) $request->user()->id;
            $columns = $this->columns();

            $titleColumn = $this->firstExistingColumn($columns, [
                'task_title',
                'title',
                'task_name',
                'name',
            ]);

            $descriptionColumn = $this->firstExistingColumn($columns, [
                'task_description',
                'description',
                'details',
            ]);

            $update = [];

            if ($titleColumn && $request->filled('title')) {
                $update[$titleColumn] = $request->title;
            }

            if ($descriptionColumn && $request->has('description')) {
                $update[$descriptionColumn] = $request->description;
            }

            foreach ([
                'priority',
                'status',
                'start_date',
                'due_date',
                'assigned_to',
                'notes',
                'progress_percentage',
                'task_order',
                'completed_date',
                'completed_at',
                'weight',
            ] as $column) {
                if (in_array($column, $columns, true) && $request->has($column)) {
                    $update[$column] = $request->{$column};
                }
            }

            if (in_array('updated_at', $columns, true)) {
                $update['updated_at'] = now();
            }

            DB::table($this->tableName())
                ->where('id', $task)
                ->where('user_id', $userId)
                ->update($update);

            return response()->json([
                'success' => true,
                'message' => 'Project task updated successfully.',
                'data' => DB::table($this->tableName())
                    ->where('id', $task)
                    ->where('user_id', $userId)
                    ->first(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project tasks update failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task update failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, $task)
    {
        try {
            $userId = (string) $request->user()->id;

            DB::table($this->tableName())
                ->where('id', $task)
                ->where('user_id', $userId)
                ->delete();

            return response()->json([
                'success' => true,
                'message' => 'Project task deleted successfully.',
            ]);
        } catch (\Throwable $e) {
            Log::error('Project tasks delete failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task delete failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}