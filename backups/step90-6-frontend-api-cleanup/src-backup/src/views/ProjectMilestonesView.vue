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
