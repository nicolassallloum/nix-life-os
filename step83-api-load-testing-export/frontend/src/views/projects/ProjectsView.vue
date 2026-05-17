<script setup>
import { computed, onMounted, ref, watch } from "vue";
import {
  createProject,
  getProjects,
  updateProject,
} from "@/services/projectService";
import ProjectProgressBar from "@/components/projects/ProjectProgressBar.vue";

const projects = ref([]);
const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const search = ref("");
const status = ref("");
const priority = ref("");
const currentPage = ref(1);
const perPage = ref(10);

const showFormModal = ref(false);
const formMode = ref("create");
const selectedProjectId = ref(null);
const validationErrors = ref({});

const form = ref({
  project_name: "",
  project_code: "",
  description: "",
  status: "not_started",
  priority: "medium",
  start_date: "",
  target_end_date: "",
  actual_end_date: "",
  progress_percentage: 0,
});

const pagination = ref({
  current_page: 1,
  last_page: 1,
  per_page: 10,
  total: 0,
});

const statusOptions = [
  { value: "", label: "All Statuses" },
  { value: "not_started", label: "Not Started" },
  { value: "in_progress", label: "In Progress" },
  { value: "on_hold", label: "On Hold" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

const formStatusOptions = [
  { value: "not_started", label: "Not Started" },
  { value: "in_progress", label: "In Progress" },
  { value: "on_hold", label: "On Hold" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

const priorityOptions = [
  { value: "", label: "All Priorities" },
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const formPriorityOptions = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const hasProjects = computed(() => projects.value.length > 0);

const formTitle = computed(() => {
  return formMode.value === "create" ? "Create Project" : "Edit Project";
});

const submitButtonText = computed(() => {
  if (saving.value) return "Saving...";
  return formMode.value === "create" ? "Create Project" : "Update Project";
});

function cleanText(value) {
  if (!value) return "-";

  return value
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatDate(value) {
  if (!value) return "Not set";

  return new Date(value).toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "2-digit",
  });
}

function statusClass(value) {
  const classes = {
    not_started: "bg-gray-100 text-gray-700",
    in_progress: "bg-blue-100 text-blue-700",
    on_hold: "bg-yellow-100 text-yellow-700",
    completed: "bg-emerald-100 text-emerald-700",
    cancelled: "bg-red-100 text-red-700",
  };

  return classes[value] || "bg-gray-100 text-gray-700";
}

function priorityClass(value) {
  const classes = {
    low: "bg-gray-100 text-gray-700",
    medium: "bg-blue-100 text-blue-700",
    high: "bg-orange-100 text-orange-700",
    critical: "bg-red-100 text-red-700",
  };

  return classes[value] || "bg-gray-100 text-gray-700";
}

function resetForm() {
  form.value = {
    project_name: "",
    project_code: "",
    description: "",
    status: "not_started",
    priority: "medium",
    start_date: "",
    target_end_date: "",
    actual_end_date: "",
    progress_percentage: 0,
  };

  selectedProjectId.value = null;
  validationErrors.value = {};
}

function normalizeDateForInput(value) {
  if (!value) return "";
  return String(value).substring(0, 10);
}

function openCreateForm() {
  resetForm();
  formMode.value = "create";
  showFormModal.value = true;
}

function openEditForm(project) {
  resetForm();

  formMode.value = "edit";
  selectedProjectId.value = project.id;

  form.value = {
    project_name: project.project_name || "",
    project_code: project.project_code || "",
    description: project.description || "",
    status: project.status || "not_started",
    priority: project.priority || "medium",
    start_date: normalizeDateForInput(project.start_date),
    target_end_date: normalizeDateForInput(project.target_end_date),
    actual_end_date: normalizeDateForInput(project.actual_end_date),
    progress_percentage: Number(project.progress_percentage || 0),
  };

  showFormModal.value = true;
}

function closeForm() {
  showFormModal.value = false;
  resetForm();
}

function buildPayload() {
  return {
    project_name: form.value.project_name,
    project_code: form.value.project_code || null,
    description: form.value.description || null,
    status: form.value.status,
    priority: form.value.priority,
    start_date: form.value.start_date || null,
    target_end_date: form.value.target_end_date || null,
    actual_end_date: form.value.actual_end_date || null,
    progress_percentage: Number(form.value.progress_percentage || 0),
  };
}

function getFieldError(field) {
  return validationErrors.value?.[field]?.[0] || "";
}

async function loadProjects(page = 1) {
  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjects({
      search: search.value || undefined,
      status: status.value || undefined,
      priority: priority.value || undefined,
      page,
      per_page: perPage.value,
    });

    projects.value = Array.isArray(response?.data) ? response.data : [];

    pagination.value = {
      current_page: response?.meta?.current_page || 1,
      last_page: response?.meta?.last_page || 1,
      per_page: response?.meta?.per_page || perPage.value,
      total: response?.meta?.total || 0,
    };

    currentPage.value = pagination.value.current_page;
  } catch (error) {
    console.error(error);

    errorMessage.value =
      error.response?.data?.message ||
      "Failed to load projects. Please check backend API, token, and route configuration.";
  } finally {
    loading.value = false;
  }
}

async function submitProjectForm() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  validationErrors.value = {};

  try {
    const payload = buildPayload();

    if (formMode.value === "create") {
      await createProject(payload);
      successMessage.value = "Project created successfully.";
    } else {
      await updateProject(selectedProjectId.value, payload);
      successMessage.value = "Project updated successfully.";
    }

    closeForm();
    await loadProjects(currentPage.value);
  } catch (error) {
    console.error(error);

    if (error.response?.status === 422) {
      validationErrors.value = error.response?.data?.errors || {};
      errorMessage.value =
        error.response?.data?.message || "Please fix the validation errors.";
      return;
    }

    errorMessage.value =
      error.response?.data?.message ||
      "Failed to save project. Please check backend API and database.";
  } finally {
    saving.value = false;
  }
}

function resetFilters() {
  search.value = "";
  status.value = "";
  priority.value = "";
  currentPage.value = 1;
  loadProjects(1);
}

function goToPage(page) {
  if (page < 1 || page > pagination.value.last_page) return;
  loadProjects(page);
}

let searchTimeout = null;

watch([search, status, priority, perPage], () => {
  clearTimeout(searchTimeout);

  searchTimeout = setTimeout(() => {
    currentPage.value = 1;
    loadProjects(1);
  }, 350);
});

watch(
  () => form.value.status,
  (newStatus) => {
    if (newStatus === "completed") {
      form.value.progress_percentage = 100;

      if (!form.value.actual_end_date) {
        form.value.actual_end_date = new Date().toISOString().substring(0, 10);
      }
    }
  }
);

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
            Project List
          </h1>

          <p class="mt-2 text-gray-500">
            Create, edit, search, filter, validate, and verify project persistence.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            type="button"
            class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
            @click="loadProjects(currentPage)"
          >
            Refresh
          </button>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-sm hover:bg-blue-700"
            @click="openCreateForm"
          >
            + Create Project
          </button>
        </div>
      </div>

      <div
        v-if="successMessage"
        class="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-medium text-emerald-700"
      >
        {{ successMessage }}
      </div>

      <div
        v-if="errorMessage"
        class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-700"
      >
        {{ errorMessage }}
      </div>

      <div class="rounded-2xl bg-white p-5 shadow-sm">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-5">
          <input
            v-model="search"
            type="text"
            placeholder="Search by name, code, or description..."
            class="rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500 md:col-span-2"
          />

          <select
            v-model="status"
            class="rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
          >
            <option
              v-for="option in statusOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>

          <select
            v-model="priority"
            class="rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
          >
            <option
              v-for="option in priorityOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>

          <button
            type="button"
            class="rounded-xl bg-gray-900 px-4 py-2 text-sm font-bold text-white hover:bg-gray-800"
            @click="resetFilters"
          >
            Reset
          </button>
        </div>
      </div>

      <div
        v-if="loading"
        class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm"
      >
        Loading projects...
      </div>

      <div
        v-else-if="!hasProjects"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center shadow-sm"
      >
        <h2 class="text-xl font-black text-gray-900">
          No projects found
        </h2>

        <p class="mt-2 text-sm text-gray-500">
          Create a new project or change the search filters.
        </p>

        <button
          type="button"
          class="mt-5 rounded-xl bg-blue-600 px-5 py-2 text-sm font-bold text-white hover:bg-blue-700"
          @click="openCreateForm"
        >
          Create First Project
        </button>
      </div>

      <div v-else class="overflow-hidden rounded-2xl bg-white shadow-sm">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Project
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Status
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Priority
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Start Date
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Target Date
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Progress
                </th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">
                  Tasks
                </th>
                <th class="px-5 py-3 text-right text-xs font-black uppercase tracking-wide text-gray-500">
                  Actions
                </th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100 bg-white">
              <tr
                v-for="project in projects"
                :key="project.id"
                class="hover:bg-gray-50"
              >
                <td class="px-5 py-4">
                  <p class="font-black text-gray-900">
                    {{ project.project_name }}
                  </p>

                  <p class="mt-1 text-xs text-gray-500">
                    {{ project.project_code || "No Code" }}
                  </p>

                  <p class="mt-1 line-clamp-1 text-xs text-gray-400">
                    {{ project.description || "No description available." }}
                  </p>

                  <p class="mt-1 text-[11px] text-gray-400">
                    Owner: {{ project.user_id }}
                  </p>
                </td>

                <td class="px-5 py-4">
                  <span
                    class="rounded-full px-3 py-1 text-xs font-bold"
                    :class="statusClass(project.status)"
                  >
                    {{ cleanText(project.status) }}
                  </span>
                </td>

                <td class="px-5 py-4">
                  <span
                    class="rounded-full px-3 py-1 text-xs font-bold"
                    :class="priorityClass(project.priority)"
                  >
                    {{ cleanText(project.priority) }}
                  </span>
                </td>

                <td class="px-5 py-4 text-sm font-medium text-gray-700">
                  {{ formatDate(project.start_date) }}
                </td>

                <td class="px-5 py-4 text-sm font-medium text-gray-700">
                  {{ formatDate(project.target_end_date) }}
                </td>

                <td class="min-w-48 px-5 py-4">
                  <ProjectProgressBar :value="Number(project.progress_percentage || 0)" size="sm" />
                </td>

                <td class="px-5 py-4 text-sm font-bold text-gray-700">
                  {{ project.tasks_count || 0 }}
                </td>

                <td class="px-5 py-4 text-right">
                  <button
                    type="button"
                    class="rounded-xl bg-gray-900 px-4 py-2 text-xs font-bold text-white hover:bg-gray-800"
                    @click="openEditForm(project)"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="flex flex-col gap-3 border-t border-gray-100 px-5 py-4 md:flex-row md:items-center md:justify-between">
          <p class="text-sm text-gray-500">
            Showing page
            <span class="font-bold text-gray-800">{{ pagination.current_page }}</span>
            of
            <span class="font-bold text-gray-800">{{ pagination.last_page }}</span>
            —
            <span class="font-bold text-gray-800">{{ pagination.total }}</span>
            total projects
          </p>

          <div class="flex items-center gap-2">
            <select
              v-model="perPage"
              class="rounded-xl border border-gray-300 px-3 py-2 text-sm outline-none focus:border-blue-500"
            >
              <option :value="5">5 / page</option>
              <option :value="10">10 / page</option>
              <option :value="15">15 / page</option>
              <option :value="25">25 / page</option>
              <option :value="50">50 / page</option>
            </select>

            <button
              type="button"
              class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-bold text-gray-700 disabled:cursor-not-allowed disabled:opacity-40"
              :disabled="pagination.current_page <= 1"
              @click="goToPage(pagination.current_page - 1)"
            >
              Previous
            </button>

            <button
              type="button"
              class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-bold text-gray-700 disabled:cursor-not-allowed disabled:opacity-40"
              :disabled="pagination.current_page >= pagination.last_page"
              @click="goToPage(pagination.current_page + 1)"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="showFormModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      >
        <div class="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl bg-white p-6 shadow-xl">
          <div class="mb-5 flex items-start justify-between gap-4">
            <div>
              <h2 class="text-2xl font-black text-gray-900">
                {{ formTitle }}
              </h2>

              <p class="mt-1 text-sm text-gray-500">
                Required field: project name. Owner is assigned automatically from logged-in user.
              </p>
            </div>

            <button
              type="button"
              class="rounded-xl bg-gray-100 px-3 py-2 text-sm font-bold text-gray-600 hover:bg-gray-200"
              @click="closeForm"
            >
              ✕
            </button>
          </div>

          <form class="space-y-5" @submit.prevent="submitProjectForm">
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Project Name <span class="text-red-500">*</span>
                </label>

                <input
                  v-model="form.project_name"
                  type="text"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('project_name') ? 'border-red-400' : 'border-gray-300'"
                  placeholder="Example: Nix Life OS Project Module"
                />

                <p v-if="getFieldError('project_name')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("project_name") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Project Code
                </label>

                <input
                  v-model="form.project_code"
                  type="text"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('project_code') ? 'border-red-400' : 'border-gray-300'"
                  placeholder="Example: PRJ-STEP-57"
                />

                <p v-if="getFieldError('project_code')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("project_code") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Status
                </label>

                <select
                  v-model="form.status"
                  class="w-full rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
                >
                  <option
                    v-for="option in formStatusOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>

                <p v-if="getFieldError('status')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("status") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Priority
                </label>

                <select
                  v-model="form.priority"
                  class="w-full rounded-xl border border-gray-300 px-4 py-2 text-sm outline-none focus:border-blue-500"
                >
                  <option
                    v-for="option in formPriorityOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>

                <p v-if="getFieldError('priority')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("priority") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Start Date
                </label>

                <input
                  v-model="form.start_date"
                  type="date"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('start_date') ? 'border-red-400' : 'border-gray-300'"
                />

                <p v-if="getFieldError('start_date')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("start_date") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Target End Date
                </label>

                <input
                  v-model="form.target_end_date"
                  type="date"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('target_end_date') ? 'border-red-400' : 'border-gray-300'"
                />

                <p v-if="getFieldError('target_end_date')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("target_end_date") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Actual End Date
                </label>

                <input
                  v-model="form.actual_end_date"
                  type="date"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('actual_end_date') ? 'border-red-400' : 'border-gray-300'"
                />

                <p v-if="getFieldError('actual_end_date')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("actual_end_date") }}
                </p>
              </div>

              <div>
                <label class="mb-1 block text-sm font-bold text-gray-700">
                  Progress Percentage
                </label>

                <input
                  v-model.number="form.progress_percentage"
                  type="number"
                  min="0"
                  max="100"
                  step="1"
                  class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                  :class="getFieldError('progress_percentage') ? 'border-red-400' : 'border-gray-300'"
                />

                <p v-if="getFieldError('progress_percentage')" class="mt-1 text-xs font-medium text-red-600">
                  {{ getFieldError("progress_percentage") }}
                </p>
              </div>
            </div>

            <div>
              <label class="mb-1 block text-sm font-bold text-gray-700">
                Description
              </label>

              <textarea
                v-model="form.description"
                rows="4"
                class="w-full rounded-xl border px-4 py-2 text-sm outline-none focus:border-blue-500"
                :class="getFieldError('description') ? 'border-red-400' : 'border-gray-300'"
                placeholder="Write project description..."
              ></textarea>

              <p v-if="getFieldError('description')" class="mt-1 text-xs font-medium text-red-600">
                {{ getFieldError("description") }}
              </p>
            </div>

            <div class="flex flex-col-reverse gap-3 border-t border-gray-100 pt-5 md:flex-row md:justify-end">
              <button
                type="button"
                class="rounded-xl border border-gray-300 px-5 py-2 text-sm font-bold text-gray-700 hover:bg-gray-50"
                @click="closeForm"
              >
                Cancel
              </button>

              <button
                type="submit"
                class="rounded-xl bg-blue-600 px-5 py-2 text-sm font-bold text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="saving"
              >
                {{ submitButtonText }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>