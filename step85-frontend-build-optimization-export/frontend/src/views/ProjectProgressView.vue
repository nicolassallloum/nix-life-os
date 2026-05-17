<script setup>
import { computed, onMounted, ref } from "vue";
import {
  getProjects,
  getProjectProgress,
  recalculateProjectProgress,
} from "@/services/projectService";

const projects = ref([]);
const selectedProjectId = ref("");
const progress = ref(null);
const loading = ref(false);
const recalculating = ref(false);
const errorMessage = ref("");

function normalizeList(response) {
  if (Array.isArray(response?.data)) return response.data;
  if (Array.isArray(response?.data?.data)) return response.data.data;
  return [];
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 });
  projects.value = normalizeList(response);

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id;
  }
}

async function loadProgress() {
  if (!selectedProjectId.value) return;

  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await getProjectProgress(selectedProjectId.value);
    progress.value = response.data;
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to load project progress.";
  } finally {
    loading.value = false;
  }
}

async function recalculate() {
  if (!selectedProjectId.value) return;

  recalculating.value = true;
  errorMessage.value = "";

  try {
    const response = await recalculateProjectProgress(selectedProjectId.value);
    progress.value = response.data;
    await loadProjects();
  } catch (error) {
    console.error(error);
    errorMessage.value =
      error.response?.data?.message || "Failed to recalculate project progress.";
  } finally {
    recalculating.value = false;
  }
}

function cleanText(value) {
  if (!value) return "-";
  return String(value).replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatDate(value) {
  if (!value) return "Not set";
  return new Date(value).toLocaleDateString("en-GB");
}

function barWidth(value, max) {
  if (!max) return "0%";
  return `${Math.round((Number(value || 0) / max) * 100)}%`;
}

const summary = computed(() => progress.value?.summary || {});
const project = computed(() => progress.value?.project || {});
const taskChart = computed(() => progress.value?.charts?.tasks_by_status || []);
const milestoneChart = computed(() => progress.value?.charts?.milestones_by_status || []);
const maxTaskValue = computed(() => Math.max(...taskChart.value.map((item) => Number(item.value || 0)), 1));
const maxMilestoneValue = computed(() => Math.max(...milestoneChart.value.map((item) => Number(item.value || 0)), 1));

onMounted(async () => {
  await loadProjects();
  await loadProgress();
});
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide text-blue-600">STEP 59</p>
          <h1 class="mt-1 text-3xl font-black text-gray-900">Project Progress / Status</h1>
          <p class="mt-2 text-gray-500">
            Verify progress calculation, task counts, milestones, recent updates, history, charts, and empty state.
          </p>
        </div>

        <div class="flex flex-wrap gap-3">
          <select
            v-model="selectedProjectId"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-bold outline-none"
            @change="loadProgress"
          >
            <option value="">Select Project</option>
            <option v-for="item in projects" :key="item.id" :value="item.id">
              {{ item.project_name }}
            </option>
          </select>

          <button
            type="button"
            class="rounded-xl bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm hover:bg-gray-50"
            @click="loadProgress"
          >
            Refresh
          </button>

          <button
            type="button"
            class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-bold text-white shadow-sm hover:bg-blue-700"
            :disabled="recalculating"
            @click="recalculate"
          >
            {{ recalculating ? "Recalculating..." : "Recalculate" }}
          </button>
        </div>
      </div>

      <div v-if="errorMessage" class="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
        {{ errorMessage }}
      </div>

      <div v-if="loading" class="rounded-2xl bg-white p-10 text-center text-sm font-bold text-gray-500 shadow-sm">
        Loading project progress...
      </div>

      <div
        v-else-if="!selectedProjectId || !progress"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-12 text-center shadow-sm"
      >
        <h2 class="text-xl font-black text-gray-900">No project selected</h2>
        <p class="mt-2 text-sm text-gray-500">Create or select a project to view progress.</p>
      </div>

      <template v-else>
        <div
          v-if="summary.empty_progress_state"
          class="rounded-2xl border border-dashed border-gray-300 bg-white p-10 text-center shadow-sm"
        >
          <h2 class="text-xl font-black text-gray-900">Empty progress state</h2>
          <p class="mt-2 text-sm text-gray-500">
            This project has no tasks and no milestones yet. Progress is correctly calculated as 0%.
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-2xl font-black text-gray-900">{{ project.project_name }}</h2>
              <p class="mt-1 text-sm text-gray-500">{{ project.project_code || "No Code" }}</p>
              <p class="mt-2 text-sm text-gray-500">
                Status: <strong>{{ cleanText(project.status) }}</strong> —
                Target: <strong>{{ formatDate(project.target_end_date) }}</strong>
              </p>
            </div>

            <div class="text-right">
              <p class="text-sm font-bold text-gray-500">Progress</p>
              <p class="text-4xl font-black text-blue-600">{{ project.progress_percentage || 0 }}%</p>
            </div>
          </div>

          <div class="mt-5 h-4 overflow-hidden rounded-full bg-gray-200">
            <div
              class="h-full rounded-full bg-blue-600 transition-all"
              :style="{ width: `${project.progress_percentage || 0}%` }"
            ></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-4 xl:grid-cols-8">
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Total Tasks</p>
            <p class="mt-2 text-2xl font-black">{{ summary.total_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Completed</p>
            <p class="mt-2 text-2xl font-black text-emerald-600">{{ summary.completed_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Pending</p>
            <p class="mt-2 text-2xl font-black text-gray-700">{{ summary.pending_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">In Progress</p>
            <p class="mt-2 text-2xl font-black text-blue-600">{{ summary.in_progress_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Blocked</p>
            <p class="mt-2 text-2xl font-black text-yellow-600">{{ summary.blocked_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Overdue</p>
            <p class="mt-2 text-2xl font-black text-red-600">{{ summary.overdue_tasks || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Milestones</p>
            <p class="mt-2 text-2xl font-black">{{ summary.total_milestones || 0 }}</p>
          </div>
          <div class="rounded-2xl bg-white p-4 shadow-sm">
            <p class="text-xs font-bold text-gray-500">Done Milestones</p>
            <p class="mt-2 text-2xl font-black text-emerald-600">{{ summary.completed_milestones || 0 }}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-5 xl:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <h2 class="text-lg font-black text-gray-900">Tasks by Status</h2>
            <div class="mt-4 space-y-4">
              <div v-for="item in taskChart" :key="item.status">
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold">{{ item.label }}</span>
                  <span>{{ item.value }}</span>
                </div>
                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div class="h-full rounded-full bg-blue-600" :style="{ width: barWidth(item.value, maxTaskValue) }"></div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <h2 class="text-lg font-black text-gray-900">Milestones by Status</h2>
            <div class="mt-4 space-y-4">
              <div v-for="item in milestoneChart" :key="item.status">
                <div class="mb-1 flex justify-between text-sm">
                  <span class="font-bold">{{ item.label }}</span>
                  <span>{{ item.value }}</span>
                </div>
                <div class="h-3 overflow-hidden rounded-full bg-gray-100">
                  <div class="h-full rounded-full bg-emerald-600" :style="{ width: barWidth(item.value, maxMilestoneValue) }"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <h2 class="text-lg font-black text-gray-900">Recent Updates / Status History</h2>

          <div
            v-if="!progress.recent_updates || progress.recent_updates.length === 0"
            class="mt-4 rounded-xl border border-dashed border-gray-300 p-8 text-center text-sm text-gray-400"
          >
            No status history available.
          </div>

          <div v-else class="mt-4 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead>
                <tr class="bg-gray-50">
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Title</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Type</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Old</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">New</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Progress</th>
                  <th class="px-4 py-3 text-left text-xs font-black uppercase text-gray-500">Created</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="update in progress.recent_updates" :key="update.id">
                  <td class="px-4 py-3 text-sm font-bold text-gray-900">{{ update.update_title }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.update_type) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.old_status) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ cleanText(update.new_status) }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">
                    {{ update.old_progress_percentage ?? "-" }} → {{ update.new_progress_percentage ?? "-" }}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-500">{{ update.created_at }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
