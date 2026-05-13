#!/bin/bash
set -e

echo "=================================================="
echo "STEP 58 - PROJECT TASKS UPDATE"
echo "=================================================="

cp backend/app/Http/Controllers/Api/V1/ProjectTaskController.php backend/app/Http/Controllers/Api/V1/ProjectTaskController.php.bak_step58_$(date +%Y%m%d_%H%M%S)
cp backend/app/Models/ProjectTask.php backend/app/Models/ProjectTask.php.bak_step58_$(date +%Y%m%d_%H%M%S)
cp backend/app/Http/Resources/ProjectTaskResource.php backend/app/Http/Resources/ProjectTaskResource.php.bak_step58_$(date +%Y%m%d_%H%M%S)
cp backend/routes/api.php backend/routes/api.php.bak_step58_$(date +%Y%m%d_%H%M%S)

echo "Updating ProjectTask model..."

cat > backend/app/Models/ProjectTask.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProjectTask extends Model
{
    use HasUuids;

    protected $fillable = [
        'project_id',
        'user_id',
        'task_title',
        'task_description',
        'status',
        'priority',
        'task_order',
        'start_date',
        'due_date',
        'completed_date',
        'progress_percentage',
        'metadata',
    ];

    protected $casts = [
        'start_date' => 'date',
        'due_date' => 'date',
        'completed_date' => 'date',
        'progress_percentage' => 'decimal:2',
        'metadata' => 'array',
    ];

    protected $appends = [
        'is_overdue',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getIsOverdueAttribute(): bool
    {
        if (!$this->due_date) {
            return false;
        }

        if (in_array($this->status, ['completed', 'cancelled'], true)) {
            return false;
        }

        return $this->due_date->isPast() && !$this->due_date->isToday();
    }
}
PHP

echo "Updating ProjectTask resource..."

cat > backend/app/Http/Resources/ProjectTaskResource.php <<'PHP'
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectTaskResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'project_id' => $this->project_id,
            'user_id' => $this->user_id,

            'task_title' => $this->task_title,
            'task_description' => $this->task_description,

            'status' => $this->status,
            'priority' => $this->priority,
            'task_order' => $this->task_order,

            'start_date' => optional($this->start_date)->format('Y-m-d'),
            'due_date' => optional($this->due_date)->format('Y-m-d'),
            'completed_date' => optional($this->completed_date)->format('Y-m-d'),

            'progress_percentage' => $this->progress_percentage,
            'is_overdue' => $this->is_overdue,

            'metadata' => $this->metadata,

            'project' => new ProjectResource($this->whenLoaded('project')),

            'created_at' => optional($this->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => optional($this->updated_at)->format('Y-m-d H:i:s'),
        ];
    }
}
PHP

echo "Updating ProjectTask controller..."

cat > backend/app/Http/Controllers/Api/V1/ProjectTaskController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectTaskResource;
use App\Models\Project;
use App\Models\ProjectTask;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectTaskController extends Controller
{
    private array $statuses = [
        'todo',
        'in_progress',
        'blocked',
        'completed',
        'cancelled',
    ];

    private array $priorities = [
        'low',
        'medium',
        'high',
        'critical',
    ];

    public function index(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],
            'overdue' => ['nullable', 'boolean'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $tasks = ProjectTask::query()
            ->where('project_id', $project->id)
            ->where('user_id', $request->user()->id)
            ->when($validated['search'] ?? null, function ($query, $search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('task_title', 'ILIKE', "%{$search}%")
                        ->orWhere('task_description', 'ILIKE', "%{$search}%");
                });
            })
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['priority'] ?? null, fn ($query, $priority) => $query->where('priority', $priority))
            ->when(array_key_exists('overdue', $validated) && $validated['overdue'], function ($query) {
                $query
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->whereNotNull('due_date')
                    ->whereDate('due_date', '<', now()->toDateString());
            })
            ->orderBy('task_order')
            ->orderByRaw('due_date IS NULL')
            ->orderBy('due_date')
            ->latest()
            ->paginate($validated['per_page'] ?? 15);

        return ProjectTaskResource::collection($tasks)
            ->additional([
                'success' => true,
                'message' => 'Project tasks loaded successfully.',
            ]);
    }

    public function store(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'task_title' => ['required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateTaskDates($validated);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        $validated['project_id'] = $project->id;
        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'todo';
        $validated['priority'] = $validated['priority'] ?? 'medium';
        $validated['task_order'] = $validated['task_order'] ?? $this->nextTaskOrder($project);
        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

        if ($validated['status'] === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();
        }

        $task = ProjectTask::create($validated);

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task created successfully.',
            'data' => new ProjectTaskResource($task->fresh()),
        ], 201);
    }

    public function show(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        return response()->json([
            'success' => true,
            'message' => 'Project task loaded successfully.',
            'data' => new ProjectTaskResource($task),
        ]);
    }

    public function update(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        $validated = $request->validate([
            'task_title' => ['sometimes', 'required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => ['sometimes', Rule::in($this->statuses)],
            'priority' => ['sometimes', Rule::in($this->priorities)],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateTaskDates($validated, $task);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        if (($validated['status'] ?? null) === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();
        }

        if (($validated['status'] ?? null) && $validated['status'] !== 'completed') {
            $validated['completed_date'] = null;

            if (!array_key_exists('progress_percentage', $validated) && $task->status === 'completed') {
                $validated['progress_percentage'] = 0;
            }
        }

        $task->update($validated);

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task updated successfully.',
            'data' => new ProjectTaskResource($task->fresh()),
        ]);
    }

    public function destroy(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        $task->delete();

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task deleted successfully.',
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

    private function authorizeTaskBelongsToProject(Request $request, Project $project, ProjectTask $task): void
    {
        abort_if(
            $task->project_id !== $project->id || $task->user_id !== $request->user()->id,
            403,
            'Unauthorized task access.'
        );
    }

    private function nextTaskOrder(Project $project): int
    {
        return ((int) $project->tasks()->max('task_order')) + 1;
    }

    private function validateTaskDates(array $validated, ?ProjectTask $task = null)
    {
        $startDate = array_key_exists('start_date', $validated)
            ? $validated['start_date']
            : optional($task?->start_date)->format('Y-m-d');

        $dueDate = array_key_exists('due_date', $validated)
            ? $validated['due_date']
            : optional($task?->due_date)->format('Y-m-d');

        $completedDate = array_key_exists('completed_date', $validated)
            ? $validated['completed_date']
            : optional($task?->completed_date)->format('Y-m-d');

        if (!empty($startDate) && !empty($dueDate) && $dueDate < $startDate) {
            return response()->json([
                'message' => 'The due date must be a date after or equal to start date.',
                'errors' => [
                    'due_date' => [
                        'The due date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        if (!empty($startDate) && !empty($completedDate) && $completedDate < $startDate) {
            return response()->json([
                'message' => 'The completed date must be a date after or equal to start date.',
                'errors' => [
                    'completed_date' => [
                        'The completed date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        return null;
    }

    private function refreshProjectProgress(Project $project): void
    {
        $tasks = $project->tasks()->get();

        if ($tasks->count() === 0) {
            $project->update([
                'progress_percentage' => 0,
                'status' => 'not_started',
                'actual_end_date' => null,
            ]);

            return;
        }

        $avgProgress = round((float) $tasks->avg('progress_percentage'), 2);
        $completedTasks = $tasks->where('status', 'completed')->count();

        if ($completedTasks === $tasks->count()) {
            $status = 'completed';
            $actualEndDate = $project->actual_end_date ?? now()->toDateString();
            $avgProgress = 100;
        } elseif ($tasks->where('status', 'blocked')->count() > 0) {
            $status = 'on_hold';
            $actualEndDate = null;
        } elseif ($tasks->where('status', 'in_progress')->count() > 0) {
            $status = 'in_progress';
            $actualEndDate = null;
        } else {
            $status = 'not_started';
            $actualEndDate = null;
        }

        $project->update([
            'progress_percentage' => $avgProgress,
            'status' => $status,
            'actual_end_date' => $actualEndDate,
        ]);
    }
}
PHP

echo "Updating routes/api.php task routes..."

python3 <<'PY'
from pathlib import Path

path = Path("backend/routes/api.php")
text = path.read_text()

old = """            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);
"""

new = """            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
            Route::post('/{project}/tasks', [ProjectTaskController::class, 'store']);
            Route::get('/{project}/tasks/{task}', [ProjectTaskController::class, 'show']);
            Route::put('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::patch('/{project}/tasks/{task}', [ProjectTaskController::class, 'update']);
            Route::delete('/{project}/tasks/{task}', [ProjectTaskController::class, 'destroy']);
"""

if old not in text:
    print("Task route block not found or already updated.")
else:
    text = text.replace(old, new, 1)
    path.write_text(text)
    print("Task routes updated.")
PY

echo "Updating frontend ProjectTasksView.vue..."

cat > frontend/src/views/ProjectTasksView.vue <<'VUE'
<script setup>
import { computed, onMounted, reactive, ref } from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const projects = ref([]);
const tasks = ref([]);
const selectedProjectId = ref("");

const filters = reactive({
  search: "",
  status: "",
  priority: "",
  overdue: false,
});

const form = reactive({
  id: null,
  task_title: "",
  task_description: "",
  status: "todo",
  priority: "medium",
  task_order: 1,
  start_date: "",
  due_date: "",
  progress_percentage: 0,
});

const statusOptions = [
  { value: "todo", label: "Todo" },
  { value: "in_progress", label: "In Progress" },
  { value: "blocked", label: "Blocked" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

const priorityOptions = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const selectedProject = computed(() => {
  return projects.value.find((project) => project.id === selectedProjectId.value) || null;
});

const taskStats = computed(() => {
  const total = tasks.value.length;
  const completed = tasks.value.filter((task) => task.status === "completed").length;
  const overdue = tasks.value.filter((task) => task.is_overdue).length;
  const highPriority = tasks.value.filter((task) =>
    ["high", "critical"].includes(task.priority)
  ).length;

  return {
    total,
    completed,
    overdue,
    highPriority,
  };
});

function getToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

async function apiRequest(path, options = {}) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message =
      data.message ||
      Object.values(data.errors || {})
        .flat()
        .join(" ") ||
      "Request failed.";

    throw new Error(message);
  }

  return data;
}

function resetMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function resetForm() {
  form.id = null;
  form.task_title = "";
  form.task_description = "";
  form.status = "todo";
  form.priority = "medium";
  form.task_order = tasks.value.length + 1;
  form.start_date = "";
  form.due_date = "";
  form.progress_percentage = 0;
}

function formatDate(date) {
  if (!date) return "Not set";

  return new Date(date).toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "2-digit",
  });
}

function cleanLabel(value) {
  if (!value) return "-";

  return String(value)
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function statusClass(status) {
  return {
    todo: "badge-gray",
    in_progress: "badge-blue",
    blocked: "badge-yellow",
    completed: "badge-green",
    cancelled: "badge-red",
  }[status] || "badge-gray";
}

function priorityClass(priority) {
  return {
    low: "badge-gray",
    medium: "badge-blue",
    high: "badge-orange",
    critical: "badge-red",
  }[priority] || "badge-gray";
}

async function loadProjects() {
  loading.value = true;
  resetMessages();

  try {
    const response = await apiRequest("/projects?per_page=100");
    projects.value = response.data || [];

    if (!selectedProjectId.value && projects.value.length > 0) {
      selectedProjectId.value = projects.value[0].id;
      await loadTasks();
    }
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function loadTasks() {
  if (!selectedProjectId.value) {
    tasks.value = [];
    return;
  }

  loading.value = true;
  resetMessages();

  try {
    const params = new URLSearchParams();

    if (filters.search) params.append("search", filters.search);
    if (filters.status) params.append("status", filters.status);
    if (filters.priority) params.append("priority", filters.priority);
    if (filters.overdue) params.append("overdue", "1");

    params.append("per_page", "100");

    const response = await apiRequest(
      `/projects/${selectedProjectId.value}/tasks?${params.toString()}`
    );

    tasks.value = response.data || [];
    resetForm();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function saveTask() {
  if (!selectedProjectId.value) {
    errorMessage.value = "Please select a project first.";
    return;
  }

  saving.value = true;
  resetMessages();

  const payload = {
    task_title: form.task_title,
    task_description: form.task_description || null,
    status: form.status,
    priority: form.priority,
    task_order: Number(form.task_order || 1),
    start_date: form.start_date || null,
    due_date: form.due_date || null,
    progress_percentage: Number(form.progress_percentage || 0),
  };

  try {
    if (form.id) {
      await apiRequest(`/projects/${selectedProjectId.value}/tasks/${form.id}`, {
        method: "PUT",
        body: JSON.stringify(payload),
      });

      successMessage.value = "Task updated successfully.";
    } else {
      await apiRequest(`/projects/${selectedProjectId.value}/tasks`, {
        method: "POST",
        body: JSON.stringify(payload),
      });

      successMessage.value = "Task created successfully.";
    }

    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    saving.value = false;
  }
}

function editTask(task) {
  form.id = task.id;
  form.task_title = task.task_title || "";
  form.task_description = task.task_description || "";
  form.status = task.status || "todo";
  form.priority = task.priority || "medium";
  form.task_order = task.task_order || 1;
  form.start_date = task.start_date || "";
  form.due_date = task.due_date || "";
  form.progress_percentage = Number(task.progress_percentage || 0);

  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
}

async function changeTaskStatus(task, status) {
  resetMessages();

  try {
    await apiRequest(`/projects/${selectedProjectId.value}/tasks/${task.id}`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    });

    successMessage.value = "Task status updated successfully.";
    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  }
}

async function deleteTask(task) {
  const confirmed = window.confirm(`Delete task: ${task.task_title}?`);

  if (!confirmed) return;

  resetMessages();

  try {
    await apiRequest(`/projects/${selectedProjectId.value}/tasks/${task.id}`, {
      method: "DELETE",
    });

    successMessage.value = "Task deleted successfully.";
    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  }
}

onMounted(loadProjects);
</script>

<template>
  <section class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Projects Module</p>
        <h1>Project Tasks</h1>
        <p class="subtitle">
          Create, edit, delete, assign, prioritize, and track project tasks.
        </p>
      </div>

      <button class="btn-secondary" type="button" @click="loadProjects">
        Refresh
      </button>
    </div>

    <div v-if="errorMessage" class="alert alert-error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <div class="grid two-cols">
      <div class="card">
        <h2>{{ form.id ? "Edit Task" : "Create Task" }}</h2>

        <div class="form-grid">
          <label>
            Project
            <select v-model="selectedProjectId" @change="loadTasks">
              <option disabled value="">Select project</option>
              <option v-for="project in projects" :key="project.id" :value="project.id">
                {{ project.project_name }}
              </option>
            </select>
          </label>

          <label>
            Task Title
            <input v-model="form.task_title" type="text" placeholder="Enter task title" />
          </label>

          <label class="full">
            Description
            <textarea
              v-model="form.task_description"
              rows="3"
              placeholder="Enter task description"
            ></textarea>
          </label>

          <label>
            Status
            <select v-model="form.status">
              <option
                v-for="status in statusOptions"
                :key="status.value"
                :value="status.value"
              >
                {{ status.label }}
              </option>
            </select>
          </label>

          <label>
            Priority
            <select v-model="form.priority">
              <option
                v-for="priority in priorityOptions"
                :key="priority.value"
                :value="priority.value"
              >
                {{ priority.label }}
              </option>
            </select>
          </label>

          <label>
            Start Date
            <input v-model="form.start_date" type="date" />
          </label>

          <label>
            Due Date
            <input v-model="form.due_date" type="date" />
          </label>

          <label>
            Order
            <input v-model="form.task_order" type="number" min="1" />
          </label>

          <label>
            Progress %
            <input v-model="form.progress_percentage" type="number" min="0" max="100" />
          </label>
        </div>

        <div class="actions">
          <button class="btn-primary" type="button" :disabled="saving" @click="saveTask">
            {{ saving ? "Saving..." : form.id ? "Update Task" : "Create Task" }}
          </button>

          <button class="btn-secondary" type="button" @click="resetForm">
            Clear
          </button>
        </div>
      </div>

      <div class="card">
        <h2>Task Summary</h2>

        <div class="stats-grid">
          <div class="stat">
            <span>Total Tasks</span>
            <strong>{{ taskStats.total }}</strong>
          </div>

          <div class="stat">
            <span>Completed</span>
            <strong>{{ taskStats.completed }}</strong>
          </div>

          <div class="stat">
            <span>Overdue</span>
            <strong>{{ taskStats.overdue }}</strong>
          </div>

          <div class="stat">
            <span>High Priority</span>
            <strong>{{ taskStats.highPriority }}</strong>
          </div>
        </div>

        <div v-if="selectedProject" class="selected-project">
          <strong>Selected Project:</strong>
          <span>{{ selectedProject.project_name }}</span>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="list-header">
        <div>
          <h2>Task List</h2>
          <p>Filter by search, status, priority, and overdue tasks.</p>
        </div>
      </div>

      <div class="filters">
        <input
          v-model="filters.search"
          type="text"
          placeholder="Search task title or description"
          @keyup.enter="loadTasks"
        />

        <select v-model="filters.status" @change="loadTasks">
          <option value="">All Statuses</option>
          <option v-for="status in statusOptions" :key="status.value" :value="status.value">
            {{ status.label }}
          </option>
        </select>

        <select v-model="filters.priority" @change="loadTasks">
          <option value="">All Priorities</option>
          <option
            v-for="priority in priorityOptions"
            :key="priority.value"
            :value="priority.value"
          >
            {{ priority.label }}
          </option>
        </select>

        <label class="checkbox">
          <input v-model="filters.overdue" type="checkbox" @change="loadTasks" />
          Overdue only
        </label>

        <button class="btn-secondary" type="button" @click="loadTasks">
          Apply
        </button>
      </div>

      <div v-if="loading" class="empty">
        Loading project tasks...
      </div>

      <div v-else-if="!selectedProjectId" class="empty">
        No project selected. Please select or create a project first.
      </div>

      <div v-else-if="tasks.length === 0" class="empty">
        No tasks found for this project.
      </div>

      <div v-else class="task-list">
        <article
          v-for="task in tasks"
          :key="task.id"
          class="task-card"
          :class="{ overdue: task.is_overdue }"
        >
          <div class="task-main">
            <div>
              <h3>{{ task.task_title }}</h3>
              <p>{{ task.task_description || "No description available." }}</p>
            </div>

            <div class="badges">
              <span class="badge" :class="statusClass(task.status)">
                {{ cleanLabel(task.status) }}
              </span>

              <span class="badge" :class="priorityClass(task.priority)">
                {{ cleanLabel(task.priority) }}
              </span>

              <span v-if="task.is_overdue" class="badge badge-red">
                Overdue
              </span>
            </div>
          </div>

          <div class="task-meta">
            <span>Start: {{ formatDate(task.start_date) }}</span>
            <span>Due: {{ formatDate(task.due_date) }}</span>
            <span>Progress: {{ task.progress_percentage }}%</span>
            <span>Order: {{ task.task_order }}</span>
          </div>

          <div class="progress-track">
            <div
              class="progress-bar"
              :style="{ width: `${Number(task.progress_percentage || 0)}%` }"
            ></div>
          </div>

          <div class="task-actions">
            <button type="button" @click="editTask(task)">Edit</button>
            <button type="button" @click="changeTaskStatus(task, 'todo')">Todo</button>
            <button type="button" @click="changeTaskStatus(task, 'in_progress')">
              In Progress
            </button>
            <button type="button" @click="changeTaskStatus(task, 'completed')">
              Complete
            </button>
            <button class="danger" type="button" @click="deleteTask(task)">
              Delete
            </button>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.eyebrow {
  margin: 0 0 6px;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

h1,
h2,
h3,
p {
  margin: 0;
}

h1 {
  color: #0f172a;
  font-size: 32px;
  font-weight: 900;
}

h2 {
  color: #0f172a;
  font-size: 20px;
  font-weight: 800;
  margin-bottom: 16px;
}

h3 {
  color: #0f172a;
  font-size: 17px;
  font-weight: 800;
}

.subtitle {
  margin-top: 8px;
  color: #64748b;
}

.grid.two-cols {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 20px;
}

.card {
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  background: #ffffff;
  padding: 22px;
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.06);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.form-grid .full {
  grid-column: 1 / -1;
}

label {
  display: flex;
  flex-direction: column;
  gap: 7px;
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 10px 12px;
  color: #0f172a;
  font-size: 14px;
  outline: none;
}

input:focus,
select:focus,
textarea:focus {
  border-color: #0f172a;
}

.actions,
.task-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 18px;
}

button {
  cursor: pointer;
  border: 0;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 800;
}

.btn-primary {
  background: #0f172a;
  color: white;
}

.btn-secondary,
.task-actions button {
  background: #f1f5f9;
  color: #0f172a;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.task-actions .danger {
  background: #fee2e2;
  color: #b91c1c;
}

.alert {
  border-radius: 14px;
  padding: 14px 16px;
  font-weight: 700;
}

.alert-error {
  background: #fee2e2;
  color: #991b1b;
}

.alert-success {
  background: #dcfce7;
  color: #166534;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.stat {
  border-radius: 16px;
  background: #f8fafc;
  padding: 16px;
}

.stat span {
  display: block;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.stat strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 28px;
  font-weight: 900;
}

.selected-project {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 18px;
  border-radius: 16px;
  background: #f8fafc;
  padding: 16px;
}

.selected-project span {
  color: #475569;
}

.list-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.list-header p {
  color: #64748b;
}

.filters {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto auto;
  gap: 12px;
  margin: 18px 0;
}

.checkbox {
  flex-direction: row;
  align-items: center;
  white-space: nowrap;
}

.checkbox input {
  width: auto;
}

.empty {
  border: 1px dashed #cbd5e1;
  border-radius: 16px;
  color: #64748b;
  padding: 28px;
  text-align: center;
}

.task-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.task-card {
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  padding: 18px;
  background: #ffffff;
}

.task-card.overdue {
  border-color: #fecaca;
  background: #fff7f7;
}

.task-main {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.task-main p {
  margin-top: 6px;
  color: #64748b;
}

.badges {
  display: flex;
  flex-wrap: wrap;
  align-content: flex-start;
  justify-content: flex-end;
  gap: 8px;
}

.badge {
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 900;
}

.badge-gray {
  background: #f1f5f9;
  color: #475569;
}

.badge-blue {
  background: #dbeafe;
  color: #1d4ed8;
}

.badge-yellow {
  background: #fef3c7;
  color: #92400e;
}

.badge-green {
  background: #dcfce7;
  color: #166534;
}

.badge-orange {
  background: #ffedd5;
  color: #c2410c;
}

.badge-red {
  background: #fee2e2;
  color: #b91c1c;
}

.task-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  margin-top: 14px;
  color: #475569;
  font-size: 13px;
  font-weight: 700;
}

.progress-track {
  height: 10px;
  overflow: hidden;
  border-radius: 999px;
  background: #e2e8f0;
  margin-top: 14px;
}

.progress-bar {
  height: 100%;
  border-radius: 999px;
  background: #0f172a;
  transition: width 0.2s ease;
}

@media (max-width: 1100px) {
  .grid.two-cols,
  .filters {
    grid-template-columns: 1fr;
  }

  .task-main {
    flex-direction: column;
  }

  .badges {
    justify-content: flex-start;
  }
}
</style>
VUE

echo "Clearing Laravel cache..."
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan optimize:clear"

echo "Checking PHP syntax..."
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/V1/ProjectTaskController.php && php -l app/Models/ProjectTask.php && php -l app/Http/Resources/ProjectTaskResource.php && php -l routes/api.php"

echo "Checking routes..."
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -Ei 'projects/.*/tasks|project.*task'"

echo "Checking frontend build..."
cd frontend
npm run build
cd ..

echo "=================================================="
echo "STEP 58 UPDATE COMPLETED SUCCESSFULLY"
echo "=================================================="
