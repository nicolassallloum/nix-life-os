<script setup>
import { computed, onMounted, ref } from "vue";
import { getProjects, recalculateProjectProgress } from "../../services/projectService";
import ProjectCard from "../../components/projects/ProjectCard.vue";
import ProjectKanbanColumn from "../../components/projects/ProjectKanbanColumn.vue";

const projects = ref([]);
const loading = ref(false);
const errorMessage = ref("");
const activeView = ref("list");
const searchQuery = ref("");
const selectedStatus = ref("all");

const statuses = [
  {
    key: "planned",
    title: "Planned",
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
    value: "planned",
    label: "Planned",
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

const totalProjects = computed(() => projects.value.length);

const completedProjects = computed(() => {
  return projects.value.filter((project) => project.status === "completed").length;
});

const inProgressProjects = computed(() => {
  return projects.value.filter((project) => project.status === "in_progress").length;
});

const averageProgress = computed(() => {
  if (!projects.value.length) return 0;

  const total = projects.value.reduce((sum, project) => {
    return sum + Number(project.progress_percentage || 0);
  }, 0);

  return Math.round(total / projects.value.length);
});

const filteredProjects = computed(() => {
  return projects.value.filter((project) => {
    const matchesSearch =
      !searchQuery.value ||
      project.project_name?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      project.project_code?.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesStatus =
      selectedStatus.value === "all" || project.status === selectedStatus.value;

    return matchesSearch && matchesStatus;
  });
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

  if (Array.isArray(payload?.projects)) {
    return payload.projects;
  }

  if (Array.isArray(payload?.data?.projects)) {
    return payload.data.projects;
  }

  return [];
}

async function loadProjects() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjects();
    projects.value = normalizeProjects(response);
  } catch (error) {
    console.error(error);

    errorMessage.value =
      error.response?.data?.message ||
      "Failed to load projects. Please check the backend API.";
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

    await loadProjects();
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
  loadProjects();
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
            Project Dashboard
          </h1>

          <p class="mt-2 text-gray-500">
            Track project progress, milestones, and execution status.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            type="button"
            class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
            @click="loadProjects"
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

      <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm font-medium text-gray-500">Total Projects</p>
          <p class="mt-2 text-3xl font-black text-gray-900">
            {{ totalProjects }}
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm font-medium text-gray-500">In Progress</p>
          <p class="mt-2 text-3xl font-black text-blue-600">
            {{ inProgressProjects }}
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm font-medium text-gray-500">Completed</p>
          <p class="mt-2 text-3xl font-black text-emerald-600">
            {{ completedProjects }}
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm font-medium text-gray-500">Average Progress</p>
          <p class="mt-2 text-3xl font-black text-gray-900">
            {{ averageProgress }}%
          </p>
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
                activeView === 'list'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-500'
              "
              @click="activeView = 'list'"
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

      <div
        v-if="loading"
        class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm"
      >
        Loading projects...
      </div>

      <template v-else>
        <div
          v-if="activeView === 'list'"
          class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3"
        >
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

        <div
          v-if="activeView === 'kanban'"
          class="grid grid-cols-1 gap-5 xl:grid-cols-4"
        >
          <ProjectKanbanColumn
            v-for="status in statuses"
            :key="status.key"
            :title="status.title"
            :status="status.key"
            :projects="projectsByStatus(status.key)"
          />
        </div>
      </template>
    </div>
  </div>
</template>
