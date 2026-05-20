<script setup>
import { onMounted, ref } from "vue";
import {
  getProjects,
  getProjectStatusUpdates,
} from "@/services/projectService";

const projects = ref([]);
const selectedProjectId = ref("");
const updates = ref([]);
const loading = ref(false);
const errorMessage = ref("");

function normalizeProjects(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

function cleanText(value) {
  if (!value) return "-";
  return String(value).replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 });
  projects.value = normalizeProjects(response);

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id;
  }
}

async function loadUpdates() {
  if (!selectedProjectId.value) return;

  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjectStatusUpdates(selectedProjectId.value);
    updates.value = Array.isArray(response?.data) ? response.data : [];
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load project status updates.";
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  await loadProjects();
  await loadUpdates();
});
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">STEP 59</p>
          <h1 class="mt-1 text-3xl font-black text-gray-900">Project Status Updates</h1>
          <p class="mt-2 text-gray-500">Review recent updates, automatic recalculations, and status history.</p>
        </div>

        <div class="flex flex-wrap gap-3">
          <select
            v-model="selectedProjectId"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-bold outline-none"
            @change="loadUpdates"
          >
            <option value="">Select Project</option>
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.project_name }}
            </option>
          </select>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white"
            @click="loadUpdates"
          >
            Refresh
          </button>
        </div>
      </div>

      <div v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
        {{ errorMessage }}
      </div>

      <div v-if="loading" class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm">
        Loading status updates...
      </div>

      <div
        v-else-if="updates.length === 0"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center shadow-sm"
      >
        <h2 class="text-xl font-black text-gray-900">No status updates found</h2>
        <p class="mt-2 text-sm text-gray-500">
          Recalculate progress, update a task, or create a milestone to generate history.
        </p>
      </div>

      <div v-else class="overflow-hidden rounded-2xl bg-white shadow-sm">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Update</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Type</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Old Status</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">New Status</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Progress</th>
                <th class="px-5 py-3 text-left text-xs font-black uppercase tracking-wide text-gray-500">Created</th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100">
              <tr v-for="update in updates" :key="update.id" class="hover:bg-gray-50">
                <td class="px-5 py-4">
                  <p class="font-black text-gray-900">{{ update.update_title }}</p>
                  <p class="mt-1 text-xs text-gray-500">{{ update.update_description || "No description." }}</p>
                </td>
                <td class="px-5 py-4 text-sm font-bold text-gray-700">{{ cleanText(update.update_type) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{{ cleanText(update.old_status) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">{{ cleanText(update.new_status) }}</td>
                <td class="px-5 py-4 text-sm text-gray-600">
                  {{ update.old_progress_percentage ?? "-" }} → {{ update.new_progress_percentage ?? "-" }}
                </td>
                <td class="px-5 py-4 text-sm text-gray-500">{{ update.created_at }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
