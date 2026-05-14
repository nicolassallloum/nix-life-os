#!/bin/bash

set -e

echo "=================================================="
echo "STEP 60 - PROJECTS MODULE FINAL STABILIZATION"
echo "=================================================="

BACKUP_DIR="step60_projects_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_file () {
  FILE="$1"
  if [ -f "$FILE" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$FILE")"
    cp "$FILE" "$BACKUP_DIR/$FILE"
    echo "Backed up: $FILE"
  fi
}

backup_file "backend/routes/api.php"
backup_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
backup_file "backend/database/migrations/2026_04_26_055613_add_progress_fields_to_project_tasks_table.php"
backup_file "frontend/src/services/projectService.js"
backup_file "frontend/src/views/ProjectMilestonesView.vue"

echo ""
echo "=================================================="
echo "1) Updating ProjectDashboardController.php"
echo "=================================================="

cat > backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class ProjectDashboardController extends Controller
{
    public function summary(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated.',
                ], 401);
            }

            $userId = $user->id;

            $baseProjects = Project::query()
                ->where('user_id', $userId);

            $totalProjects = (clone $baseProjects)->count();

            $activeProjects = (clone $baseProjects)
                ->where('status', 'in_progress')
                ->count();

            $completedProjects = (clone $baseProjects)
                ->where('status', 'completed')
                ->count();

            $onHoldProjects = (clone $baseProjects)
                ->where('status', 'on_hold')
                ->count();

            $cancelledProjects = (clone $baseProjects)
                ->where('status', 'cancelled')
                ->count();

            $notStartedProjects = (clone $baseProjects)
                ->where('status', 'not_started')
                ->count();

            $averageProgress = (clone $baseProjects)
                ->avg('progress_percentage');

            /*
             |--------------------------------------------------------------------------
             | Important:
             |--------------------------------------------------------------------------
             | project_tasks does NOT have target_end_date.
             | Overdue task logic must use project_tasks.due_date.
             */
            $overdueTasks = ProjectTask::query()
                ->join('projects', 'projects.id', '=', 'project_tasks.project_id')
                ->where('projects.user_id', $userId)
                ->whereNotIn('project_tasks.status', ['completed', 'cancelled'])
                ->whereNotNull('project_tasks.due_date')
                ->whereDate('project_tasks.due_date', '<', now()->toDateString())
                ->count();

            $totalTasks = ProjectTask::query()
                ->join('projects', 'projects.id', '=', 'project_tasks.project_id')
                ->where('projects.user_id', $userId)
                ->count();

            $completedTasks = ProjectTask::query()
                ->join('projects', 'projects.id', '=', 'project_tasks.project_id')
                ->where('projects.user_id', $userId)
                ->where('project_tasks.status', 'completed')
                ->count();

            $statusChart = (clone $baseProjects)
                ->select('status', DB::raw('COUNT(*) as total'))
                ->groupBy('status')
                ->orderBy('status')
                ->get()
                ->map(fn ($item) => [
                    'label' => $this->formatLabel($item->status),
                    'status' => $item->status,
                    'value' => (int) $item->total,
                ])
                ->values();

            $priorityChart = (clone $baseProjects)
                ->select('priority', DB::raw('COUNT(*) as total'))
                ->groupBy('priority')
                ->orderBy('priority')
                ->get()
                ->map(fn ($item) => [
                    'label' => $this->formatLabel($item->priority),
                    'priority' => $item->priority,
                    'value' => (int) $item->total,
                ])
                ->values();

            $progressCards = (clone $baseProjects)
                ->withCount([
                    'tasks as total_tasks',
                    'tasks as completed_tasks' => fn ($query) => $query->where('status', 'completed'),
                ])
                ->latest()
                ->limit(8)
                ->get()
                ->map(fn ($project) => [
                    'id' => $project->id,
                    'project_name' => $project->project_name,
                    'project_code' => $project->project_code,
                    'status' => $project->status,
                    'priority' => $project->priority,
                    'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                    'total_tasks' => (int) ($project->total_tasks ?? 0),
                    'completed_tasks' => (int) ($project->completed_tasks ?? 0),
                    'target_end_date' => $project->target_end_date
                        ? $project->target_end_date->toDateString()
                        : null,
                ])
                ->values();

            $recentProjects = (clone $baseProjects)
                ->latest()
                ->limit(10)
                ->get()
                ->map(fn ($project) => [
                    'id' => $project->id,
                    'project_name' => $project->project_name,
                    'project_code' => $project->project_code,
                    'status' => $project->status,
                    'priority' => $project->priority,
                    'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                    'start_date' => $project->start_date
                        ? $project->start_date->toDateString()
                        : null,
                    'target_end_date' => $project->target_end_date
                        ? $project->target_end_date->toDateString()
                        : null,
                ])
                ->values();

            return response()->json([
                'success' => true,
                'message' => 'Projects dashboard loaded successfully.',
                'data' => [
                    'summary' => [
                        'total_projects' => $totalProjects,
                        'active_projects' => $activeProjects,
                        'completed_projects' => $completedProjects,
                        'on_hold_projects' => $onHoldProjects,
                        'cancelled_projects' => $cancelledProjects,
                        'not_started_projects' => $notStartedProjects,
                        'overdue_tasks' => $overdueTasks,
                        'total_tasks' => $totalTasks,
                        'completed_tasks' => $completedTasks,
                        'average_progress' => round((float) ($averageProgress ?? 0), 2),
                    ],
                    'progress_cards' => $progressCards,
                    'recent_projects' => $recentProjects,
                    'charts' => [
                        'status' => $statusChart,
                        'priority' => $priorityChart,
                    ],
                    'empty_state' => [
                        'has_projects' => $totalProjects > 0,
                        'has_tasks' => $totalTasks > 0,
                    ],
                ],
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Projects dashboard failed to load.',
                'error' => config('app.debug') ? $exception->getMessage() : 'Server Error',
            ], 500);
        }
    }

    private function formatLabel(?string $value): string
    {
        if (!$value) {
            return 'Unknown';
        }

        return ucwords(str_replace('_', ' ', $value));
    }
}
PHP

echo ""
echo "=================================================="
echo "2) Fixing dangerous migration reference"
echo "=================================================="

cat > backend/database/migrations/2026_04_26_055613_add_progress_fields_to_project_tasks_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('project_tasks')) {
            return;
        }

        Schema::table('project_tasks', function (Blueprint $table) {
            if (!Schema::hasColumn('project_tasks', 'progress_percentage')) {
                $table->decimal('progress_percentage', 5, 2)->default(0)->after('completed_date');
            }

            if (!Schema::hasColumn('project_tasks', 'weight')) {
                $table->decimal('weight', 8, 2)->default(1)->after('progress_percentage');
            }

            /*
             |--------------------------------------------------------------------------
             | Important:
             |--------------------------------------------------------------------------
             | project_tasks has due_date and completed_date.
             | It does not have target_end_date.
             */
            if (!Schema::hasColumn('project_tasks', 'completed_at')) {
                $table->timestamp('completed_at')->nullable()->after('completed_date');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('project_tasks')) {
            return;
        }

        Schema::table('project_tasks', function (Blueprint $table) {
            if (Schema::hasColumn('project_tasks', 'completed_at')) {
                $table->dropColumn('completed_at');
            }

            if (Schema::hasColumn('project_tasks', 'weight')) {
                $table->dropColumn('weight');
            }

            if (Schema::hasColumn('project_tasks', 'progress_percentage')) {
                $table->dropColumn('progress_percentage');
            }
        });
    }
};
PHP

echo ""
echo "=================================================="
echo "3) Updating projectService.js"
echo "=================================================="

cat > frontend/src/services/projectService.js <<'JS'
import api from "./api";

export async function getProjectDashboard() {
  const response = await api.get("/projects/dashboard");
  return response.data;
}

export async function getProjects(params = {}) {
  const response = await api.get("/projects", { params });
  return response.data;
}

export async function getProject(projectId) {
  const response = await api.get(`/projects/${projectId}`);
  return response.data;
}

export async function createProject(payload) {
  const response = await api.post("/projects", payload);
  return response.data;
}

export async function updateProject(projectId, payload) {
  const response = await api.put(`/projects/${projectId}`, payload);
  return response.data;
}

export async function patchProject(projectId, payload) {
  const response = await api.patch(`/projects/${projectId}`, payload);
  return response.data;
}

export async function deleteProject(projectId) {
  const response = await api.delete(`/projects/${projectId}`);
  return response.data;
}

export async function getProjectTasks(projectId, params = {}) {
  const response = await api.get(`/projects/${projectId}/tasks`, { params });
  return response.data;
}

export async function createProjectTask(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/tasks`, payload);
  return response.data;
}

export async function updateProjectTask(projectId, taskId, payload) {
  const response = await api.put(`/projects/${projectId}/tasks/${taskId}`, payload);
  return response.data;
}

export async function patchProjectTask(projectId, taskId, payload) {
  const response = await api.patch(`/projects/${projectId}/tasks/${taskId}`, payload);
  return response.data;
}

export async function deleteProjectTask(projectId, taskId) {
  const response = await api.delete(`/projects/${projectId}/tasks/${taskId}`);
  return response.data;
}

export async function updateProjectTaskProgress(projectId, taskId, payload) {
  const response = await api.patch(`/projects/${projectId}/tasks/${taskId}/progress`, payload);
  return response.data;
}

export async function getProjectProgress(projectId) {
  const response = await api.get(`/projects/${projectId}/progress`);
  return response.data;
}

export async function recalculateProjectProgress(projectId) {
  const response = await api.post(`/projects/${projectId}/progress/recalculate`);
  return response.data;
}

export async function getProjectMilestones(projectId) {
  const response = await api.get(`/projects/${projectId}/milestones`);
  return response.data;
}

export async function createProjectMilestone(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/milestones`, payload);
  return response.data;
}

export async function updateProjectMilestone(projectId, milestoneId, payload) {
  const response = await api.put(`/projects/${projectId}/milestones/${milestoneId}`, payload);
  return response.data;
}

export async function deleteProjectMilestone(projectId, milestoneId) {
  const response = await api.delete(`/projects/${projectId}/milestones/${milestoneId}`);
  return response.data;
}

export async function getProjectStatusUpdates(projectId, params = {}) {
  const response = await api.get(`/projects/${projectId}/status-updates`, { params });
  return response.data;
}

export async function createProjectStatusUpdate(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/status-updates`, payload);
  return response.data;
}

export async function updateProjectStatus(projectId, status) {
  const response = await api.patch(`/projects/${projectId}`, { status });
  return response.data;
}
JS

echo ""
echo "=================================================="
echo "4) Replacing placeholder ProjectMilestonesView.vue"
echo "=================================================="

cat > frontend/src/views/ProjectMilestonesView.vue <<'VUE'
<script setup>
import { computed, onMounted, ref } from "vue";
import {
  getProjects,
  getProjectMilestones,
  createProjectMilestone,
  updateProjectMilestone,
  deleteProjectMilestone,
} from "@/services/projectService";

const projects = ref([]);
const milestones = ref([]);
const selectedProjectId = ref("");
const loadingProjects = ref(false);
const loadingMilestones = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const validationErrors = ref({});
const formMode = ref("create");
const selectedMilestoneId = ref(null);

const form = ref({
  milestone_name: "",
  description: "",
  target_date: "",
  status: "pending",
  progress_percentage: 0,
  weight: 1,
});

const selectedProject = computed(() => {
  return projects.value.find((project) => project.id === selectedProjectId.value) || null;
});

const hasMilestones = computed(() => milestones.value.length > 0);

function normalizeProjects(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

function normalizeMilestones(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

function cleanText(value) {
  if (!value) return "-";
  return String(value)
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatDate(value) {
  if (!value) return "Not set";
  return new Date(value).toLocaleDateString("en-GB");
}

function normalizeDateForInput(value) {
  if (!value) return "";
  return String(value).slice(0, 10);
}

function statusClass(status) {
  const classes = {
    pending: "bg-gray-100 text-gray-700",
    in_progress: "bg-blue-100 text-blue-700",
    completed: "bg-emerald-100 text-emerald-700",
    blocked: "bg-yellow-100 text-yellow-700",
    cancelled: "bg-red-100 text-red-700",
  };

  return classes[status] || "bg-gray-100 text-gray-700";
}

function resetForm() {
  formMode.value = "create";
  selectedMilestoneId.value = null;
  validationErrors.value = {};
  form.value = {
    milestone_name: "",
    description: "",
    target_date: "",
    status: "pending",
    progress_percentage: 0,
    weight: 1,
  };
}

function openEditForm(milestone) {
  formMode.value = "edit";
  selectedMilestoneId.value = milestone.id;
  validationErrors.value = {};

  form.value = {
    milestone_name: milestone.milestone_name || "",
    description: milestone.description || "",
    target_date: normalizeDateForInput(milestone.target_date),
    status: milestone.status || "pending",
    progress_percentage: Number(milestone.progress_percentage || 0),
    weight: Number(milestone.weight || 1),
  };

  window.scrollTo({ top: 0, behavior: "smooth" });
}

function buildPayload() {
  return {
    milestone_name: form.value.milestone_name,
    description: form.value.description || null,
    target_date: form.value.target_date || null,
    status: form.value.status,
    progress_percentage: Number(form.value.progress_percentage || 0),
    weight: Number(form.value.weight || 1),
  };
}

function getFieldError(field) {
  return validationErrors.value?.[field]?.[0] || "";
}

async function loadProjects() {
  loadingProjects.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjects({ per_page: 100 });
    projects.value = normalizeProjects(response);

    if (!selectedProjectId.value && projects.value.length > 0) {
      selectedProjectId.value = projects.value[0].id;
    }

    await loadMilestones();
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load projects.";
  } finally {
    loadingProjects.value = false;
  }
}

async function loadMilestones() {
  if (!selectedProjectId.value) {
    milestones.value = [];
    return;
  }

  loadingMilestones.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjectMilestones(selectedProjectId.value);
    milestones.value = normalizeMilestones(response);
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load project milestones.";
  } finally {
    loadingMilestones.value = false;
  }
}

async function submitForm() {
  if (!selectedProjectId.value) {
    errorMessage.value = "Please select a project first.";
    return;
  }

  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  validationErrors.value = {};

  try {
    const payload = buildPayload();

    if (formMode.value === "edit" && selectedMilestoneId.value) {
      await updateProjectMilestone(selectedProjectId.value, selectedMilestoneId.value, payload);
      successMessage.value = "Milestone updated successfully.";
    } else {
      await createProjectMilestone(selectedProjectId.value, payload);
      successMessage.value = "Milestone created successfully.";
    }

    resetForm();
    await loadMilestones();
  } catch (error) {
    console.error(error);
    validationErrors.value = error.response?.data?.errors || {};
    errorMessage.value =
      error.response?.data?.message || "Failed to save milestone.";
  } finally {
    saving.value = false;
  }
}

async function removeMilestone(milestone) {
  const confirmed = window.confirm(`Delete milestone "${milestone.milestone_name}"?`);
  if (!confirmed) return;

  errorMessage.value = "";
  successMessage.value = "";

  try {
    await deleteProjectMilestone(selectedProjectId.value, milestone.id);
    successMessage.value = "Milestone deleted successfully.";
    await loadMilestones();
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to delete milestone.";
  }
}

onMounted(loadProjects);
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">
            Projects Module
          </p>
          <h1 class="mt-1 text-3xl font-black text-gray-900">
            Project Milestones
          </h1>
          <p class="mt-2 text-gray-500">
            Create, update, delete, and track project milestones.
          </p>
        </div>

        <button
          type="button"
          class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
          @click="loadProjects"
        >
          Refresh
        </button>
      </div>

      <div v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
        {{ errorMessage }}
      </div>

      <div v-if="successMessage" class="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-bold text-emerald-700">
        {{ successMessage }}
      </div>

      <div class="rounded-2xl bg-white p-6 shadow-sm">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
          <label class="block">
            <span class="text-sm font-bold text-gray-700">Project</span>
            <select
              v-model="selectedProjectId"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
              @change="loadMilestones"
            >
              <option value="">Select Project</option>
              <option v-for="project in projects" :key="project.id" :value="project.id">
                {{ project.project_name }}
              </option>
            </select>
          </label>

          <div v-if="selectedProject" class="rounded-xl bg-gray-50 p-4 md:col-span-2">
            <p class="text-xs font-bold uppercase text-gray-500">Selected Project</p>
            <p class="mt-1 font-black text-gray-900">{{ selectedProject.project_name }}</p>
            <p class="mt-1 text-sm text-gray-500">
              {{ selectedProject.project_code || "No Code" }} —
              {{ cleanText(selectedProject.status) }}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 shadow-sm">
        <h2 class="text-xl font-black text-gray-900">
          {{ formMode === "create" ? "Create Milestone" : "Edit Milestone" }}
        </h2>

        <form class="mt-5 grid grid-cols-1 gap-4 md:grid-cols-2" @submit.prevent="submitForm">
          <label class="block">
            <span class="text-sm font-bold text-gray-700">Milestone Name</span>
            <input
              v-model="form.milestone_name"
              type="text"
              class="mt-2 w-full rounded-xl border px-4 py-3 text-sm outline-none"
              :class="getFieldError('milestone_name') ? 'border-red-400' : 'border-gray-300'"
              placeholder="Example: Final QA Stabilization"
            />
            <p v-if="getFieldError('milestone_name')" class="mt-1 text-xs font-bold text-red-600">
              {{ getFieldError("milestone_name") }}
            </p>
          </label>

          <label class="block">
            <span class="text-sm font-bold text-gray-700">Target Date</span>
            <input
              v-model="form.target_date"
              type="date"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
            />
          </label>

          <label class="block">
            <span class="text-sm font-bold text-gray-700">Status</span>
            <select
              v-model="form.status"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
            >
              <option value="pending">Pending</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="blocked">Blocked</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </label>

          <label class="block">
            <span class="text-sm font-bold text-gray-700">Progress %</span>
            <input
              v-model.number="form.progress_percentage"
              type="number"
              min="0"
              max="100"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
            />
          </label>

          <label class="block">
            <span class="text-sm font-bold text-gray-700">Weight</span>
            <input
              v-model.number="form.weight"
              type="number"
              min="0.1"
              step="0.1"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
            />
          </label>

          <label class="block md:col-span-2">
            <span class="text-sm font-bold text-gray-700">Description</span>
            <textarea
              v-model="form.description"
              rows="4"
              class="mt-2 w-full rounded-xl border border-gray-300 px-4 py-3 text-sm outline-none"
              placeholder="Write milestone description..."
            ></textarea>
          </label>

          <div class="flex gap-3 md:col-span-2">
            <button
              type="submit"
              class="rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white hover:bg-blue-700 disabled:opacity-60"
              :disabled="saving"
            >
              {{ saving ? "Saving..." : formMode === "create" ? "Create Milestone" : "Update Milestone" }}
            </button>

            <button
              type="button"
              class="rounded-xl bg-gray-100 px-5 py-3 text-sm font-bold text-gray-700 hover:bg-gray-200"
              @click="resetForm"
            >
              Reset
            </button>
          </div>
        </form>
      </div>

      <div class="rounded-2xl bg-white p-6 shadow-sm">
        <div class="mb-5 flex items-center justify-between">
          <h2 class="text-xl font-black text-gray-900">Milestone Records</h2>
          <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-bold text-gray-600">
            {{ milestones.length }} milestones
          </span>
        </div>

        <div v-if="loadingProjects || loadingMilestones" class="rounded-2xl bg-gray-50 p-10 text-center text-sm font-bold text-gray-500">
          Loading milestones...
        </div>

        <div v-else-if="!selectedProjectId" class="rounded-2xl border border-dashed border-gray-300 p-10 text-center">
          <h3 class="text-lg font-black text-gray-900">No project selected</h3>
          <p class="mt-2 text-sm text-gray-500">Select a project to manage milestones.</p>
        </div>

        <div v-else-if="!hasMilestones" class="rounded-2xl border border-dashed border-gray-300 p-10 text-center">
          <h3 class="text-lg font-black text-gray-900">No milestones found</h3>
          <p class="mt-2 text-sm text-gray-500">Create the first milestone for this project.</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead>
              <tr class="text-left text-xs font-black uppercase text-gray-500">
                <th class="px-4 py-3">Milestone</th>
                <th class="px-4 py-3">Status</th>
                <th class="px-4 py-3">Progress</th>
                <th class="px-4 py-3">Target Date</th>
                <th class="px-4 py-3">Weight</th>
                <th class="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="milestone in milestones" :key="milestone.id">
                <td class="px-4 py-4">
                  <p class="font-black text-gray-900">{{ milestone.milestone_name }}</p>
                  <p class="mt-1 text-xs text-gray-500">
                    {{ milestone.description || "No description." }}
                  </p>
                </td>
                <td class="px-4 py-4">
                  <span class="rounded-full px-3 py-1 text-xs font-bold" :class="statusClass(milestone.status)">
                    {{ cleanText(milestone.status) }}
                  </span>
                </td>
                <td class="px-4 py-4 font-bold text-gray-800">
                  {{ milestone.progress_percentage || 0 }}%
                </td>
                <td class="px-4 py-4 text-gray-600">
                  {{ formatDate(milestone.target_date) }}
                </td>
                <td class="px-4 py-4 text-gray-600">
                  {{ milestone.weight || 1 }}
                </td>
                <td class="px-4 py-4 text-right">
                  <button
                    type="button"
                    class="mr-2 rounded-lg bg-gray-100 px-3 py-2 text-xs font-bold text-gray-700 hover:bg-gray-200"
                    @click="openEditForm(milestone)"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    class="rounded-lg bg-red-50 px-3 py-2 text-xs font-bold text-red-700 hover:bg-red-100"
                    @click="removeMilestone(milestone)"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
VUE

echo ""
echo "=================================================="
echo "5) Removing duplicate progress route from api.php"
echo "=================================================="

python3 - <<'PY'
from pathlib import Path

path = Path("backend/routes/api.php")
text = path.read_text()

duplicate = """            Route::patch('/{project}/tasks/{task}/progress', [ProjectProgressController::class, 'updateTaskProgress']);

            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
"""

replacement = """            Route::get('/{project}/tasks', [ProjectTaskController::class, 'index']);
"""

if duplicate in text:
    text = text.replace(duplicate, replacement)

path.write_text(text)
PY

echo ""
echo "=================================================="
echo "6) Laravel checks"
echo "=================================================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/V1/ProjectDashboardController.php"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan optimize:clear"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -i project"

echo ""
echo "=================================================="
echo "7) Frontend build check"
echo "=================================================="

cd frontend
npm run build
cd ..

echo ""
echo "=================================================="
echo "STEP 60 STABILIZATION COMPLETED"
echo "Backup directory: $BACKUP_DIR"
echo "=================================================="
