<script setup>
import { computed, onMounted, ref } from "vue";
import {
  getProjectDashboard,
  getProjects,
  recalculateProjectProgress,
} from "../../services/projectService";

import ProjectCard from "../../components/projects/ProjectCard.vue";
import ProjectKanbanColumn from "../../components/projects/ProjectKanbanColumn.vue";

const projects = ref([]);
const dashboard = ref({
  summary: {
    total_projects: 0,
    active_projects: 0,
    completed_projects: 0,
    overdue_tasks: 0,
    average_progress: 0,
  },
  progress_cards: [],
  recent_projects: [],
  charts: {
    status: [],
    priority: [],
  },
});

const loading = ref(false);
const errorMessage = ref("");
const activeView = ref("overview");
const searchQuery = ref("");
const selectedStatus = ref("all");

const statuses = [
  {
    key: "not_started",
    title: "Not Started",
  },
  {
    key: "in_progress",
    title: "In Progress",
  },
  {
    key: "on_hold",
    title: "On Hold",
  },
  {
    key: "completed",
    title: "Completed",
  },
];

const statusOptions = [
  {
    value: "all",
    label: "All Statuses",
  },
  {
    value: "not_started",
    label: "Not Started",
  },
  {
    value: "in_progress",
    label: "In Progress",
  },
  {
    value: "on_hold",
    label: "On Hold",
  },
  {
    value: "completed",
    label: "Completed",
  },
  {
    value: "cancelled",
    label: "Cancelled",
  },
];

const emptyProjectDashboard = () => ({
  summary: {
    total_projects: 0,
    active_projects: 0,
    completed_projects: 0,
    overdue_tasks: 0,
    average_progress: 0,
  },
  progress_cards: [],
  recent_projects: [],
  charts: {
    status: [],
    priority: [],
  },
});

const summary = computed(() => dashboard.value?.summary || emptyProjectDashboard().summary);

const filteredProjects = computed(() => {
  return (Array.isArray(projects.value) ? projects.value : []).filter((project) => {
    const matchesSearch =
      !searchQuery.value ||
      project.project_name?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      project.project_code?.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesStatus =
      selectedStatus.value === "all" || project.status === selectedStatus.value;

    return matchesSearch && matchesStatus;
  });
});

const statusChartItems = computed(() => Array.isArray(dashboard.value?.charts?.status) ? dashboard.value.charts.status : []);
const priorityChartItems = computed(() => Array.isArray(dashboard.value?.charts?.priority) ? dashboard.value.charts.priority : []);
const progressCards = computed(() => Array.isArray(dashboard.value?.progress_cards) ? dashboard.value.progress_cards : []);

const maxStatusChartValue = computed(() => {
  const values = statusChartItems.value.map((item) => Number(item.value || 0));
  return Math.max(...values, 1);
});

const maxPriorityChartValue = computed(() => {
  const values = priorityChartItems.value.map((item) => Number(item.value || 0));
  return Math.max(...values, 1);
});

function projectsByStatus(status) {
  return filteredProjects.value.filter((project) => project.status === status);
}

function normalizeProjects(payload) {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (Array.isArray(payload?.data)) {
    return payload.data;
  }

  if (Array.isArray(payload?.data?.data)) {
    return payload.data.data;
  }

  if (Array.isArray(payload?.projects)) {
    return payload.projects;
  }

  if (Array.isArray(payload?.data?.projects)) {
    return payload.data.projects;
  }

  return [];
}

function chartWidth(value, maxValue) {
  const numericValue = Number(value || 0);
  const numericMax = Number(maxValue || 0);

  if (!numericMax || !Number.isFinite(numericValue)) return "0%";

  return `${Math.min(100, Math.max(0, Math.round((numericValue / numericMax) * 100)))}%`;
}

async function loadDashboard() {
  const response = await getProjectDashboard();

  const data = response?.data || {};
  const fallback = emptyProjectDashboard();

  dashboard.value = {
    summary: {
      ...fallback.summary,
      ...(data.summary || {}),
    },
    progress_cards: Array.isArray(data.progress_cards) ? data.progress_cards : [],
    recent_projects: Array.isArray(data.recent_projects) ? data.recent_projects : [],
    charts: {
      status: Array.isArray(data.charts?.status) ? data.charts.status : [],
      priority: Array.isArray(data.charts?.priority) ? data.charts.priority : [],
    },
  };
}

async function loadProjects() {
  const response = await getProjects({
    per_page: 100,
  });

  projects.value = normalizeProjects(response);
}

async function loadPage() {
  loading.value = true;
  errorMessage.value = "";

  try {
    await Promise.all([loadDashboard(), loadProjects()]);
  } catch (error) {
    console.error(error);

    errorMessage.value =
      error.response?.data?.message ||
      "Failed to load Projects Dashboard. Please check backend API routes.";
  } finally {
    loading.value = false;
  }
}

async function recalculateAllProgress() {
  loading.value = true;
  errorMessage.value = "";

  try {
    for (const project of projects.value) {
      await recalculateProjectProgress(project.id);
    }

    await loadPage();
  } catch (error) {
    console.error(error);

    errorMessage.value =
      error.response?.data?.message ||
      "Failed to recalculate project progress.";
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadPage();
});
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">
            NIX LIFE OS
          </p>

          <h1 class="mt-1 text-3xl font-black text-gray-900">
            Projects Dashboard
          </h1>

          <p class="mt-2 text-gray-500">
            Track total projects, active execution, completed work, overdue tasks, progress cards, and charts.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            type="button"
            class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
            @click="loadPage"
          >
            Refresh
          </button>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-sm hover:bg-blue-700"
            @click="recalculateAllProgress"
          >
            Recalculate Progress
          </button>
        </div>
      </div>

      <div
        v-if="errorMessage"
        class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-700"
      >
        {{ errorMessage }}
      </div>

      <div
        v-if="loading"
        class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm"
      >
        Loading projects dashboard...
      </div>

      <template v-else>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-5">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm font-medium text-gray-500">Total Projects</p>
            <p class="mt-2 text-3xl font-black text-gray-900">
              {{ summary.total_projects || 0 }}
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm font-medium text-gray-500">Active Projects</p>
            <p class="mt-2 text-3xl font-black text-blue-600">
              {{ summary.active_projects || 0 }}
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm font-medium text-gray-500">Completed Projects</p>
            <p class="mt-2 text-3xl font-black text-emerald-600">
              {{ summary.completed_projects || 0 }}
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm font-medium text-gray-500">Overdue Tasks</p>
            <p class="mt-2 text-3xl font-black text-red-600">
              {{ summary.overdue_tasks || 0 }}
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm font-medium text-gray-500">Average Progress</p>
            <p class="mt-2 text-3xl font-black text-gray-900">
              {{ summary.average_progress || 0 }}%
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-5 xl:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-lg font-black text-gray-900">
                Projects by Status
              </h2>
            </div>

            <div
              v-if="statusChartItems.length === 0"
              class="rounded-xl border border-dashed border-gray-300 p-8 text-center text-sm text-gray-400"
            >
              No status chart data available.
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="item in statusChartItems"
                :key="item.status"
              >
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold text-gray-700">{{ item.label }}</span>
                  <span class="text-gray-500">{{ item.value }}</span>
                </div>

                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div
                    class="h-full rounded-full bg-blue-600"
                    :style="{ width: chartWidth(item.value, maxStatusChartValue) }"
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-lg font-black text-gray-900">
                Projects by Priority
              </h2>
            </div>

            <div
              v-if="priorityChartItems.length === 0"
              class="rounded-xl border border-dashed border-gray-300 p-8 text-center text-sm text-gray-400"
            >
              No priority chart data available.
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="item in priorityChartItems"
                :key="item.priority"
              >
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold text-gray-700">{{ item.label }}</span>
                  <span class="text-gray-500">{{ item.value }}</span>
                </div>

                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div
                    class="h-full rounded-full bg-purple-600"
                    :style="{ width: chartWidth(item.value, maxPriorityChartValue) }"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-lg font-black text-gray-900">
              Project Progress Cards
            </h2>
          </div>

          <div
            v-if="progressCards.length === 0"
            class="rounded-xl border border-dashed border-gray-300 p-8 text-center text-sm text-gray-400"
          >
            No project progress data available.
          </div>

          <div v-else class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
            <div
              v-for="project in progressCards"
              :key="project.id"
              class="rounded-2xl border border-gray-100 bg-gray-50 p-4"
            >
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="font-black text-gray-900">
                    {{ project.project_name }}
                  </p>
                  <p class="mt-1 text-xs text-gray-500">
                    {{ project.project_code || "No Code" }}
                  </p>
                </div>

                <span class="rounded-full bg-white px-3 py-1 text-xs font-bold text-gray-600">
                  {{ project.status }}
                </span>
              </div>

              <div class="mt-4">
                <div class="mb-1 flex justify-between text-xs">
                  <span class="font-bold text-gray-500">Progress</span>
                  <span class="font-bold text-gray-700">
                    {{ project.progress_percentage || 0 }}%
                  </span>
                </div>

                <div class="h-3 overflow-hidden rounded-full bg-gray-200">
                  <div
                    class="h-full rounded-full bg-emerald-600"
                    :style="{ width: `${project.progress_percentage || 0}%` }"
                  ></div>
                </div>
              </div>

              <div class="mt-4 text-xs text-gray-500">
                Tasks:
                <span class="font-bold text-gray-700">
                  {{ project.completed_tasks || 0 }} / {{ project.total_tasks || 0 }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div class="flex flex-col gap-3 md:flex-row">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search project..."
                class="w-full rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500 md:w-72"
              />

              <select
                v-model="selectedStatus"
                class="rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
              >
                <option
                  v-for="status in statusOptions"
                  :key="status.value"
                  :value="status.value"
                >
                  {{ status.label }}
                </option>
              </select>
            </div>

            <div class="flex rounded-xl bg-gray-100 p-1">
              <button
                type="button"
                class="rounded-lg px-4 py-2 text-sm font-bold"
                :class="
                  activeView === 'overview'
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-500'
                "
                @click="activeView = 'overview'"
              >
                List View
              </button>

              <button
                type="button"
                class="rounded-lg px-4 py-2 text-sm font-bold"
                :class="
                  activeView === 'kanban'
                    ? 'bg-white text-blue-600 shadow-sm'
                    : 'text-gray-500'
                "
                @click="activeView = 'kanban'"
              >
                Kanban View
              </button>
            </div>
          </div>
        </div>

        <template v-if="activeView === 'overview'">
          <div class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
            <ProjectCard
              v-for="project in filteredProjects"
              :key="project.id"
              :project="project"
            />

            <div
              v-if="filteredProjects.length === 0"
              class="col-span-full rounded-2xl border border-dashed border-gray-300 bg-white p-10 text-center text-gray-400"
            >
              No projects found.
            </div>
          </div>
        </template>

        <template v-if="activeView === 'kanban'">
          <div class="grid grid-cols-1 gap-5 xl:grid-cols-4">
            <ProjectKanbanColumn
              v-for="status in statuses"
              :key="status.key"
              :title="status.title"
              :status="status.key"
              :projects="projectsByStatus(status.key)"
            />
          </div>
        </template>
      </template>
    </div>
  </div>
</template>