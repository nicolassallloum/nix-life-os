<script setup>
import { onMounted, ref } from "vue";
import {
  getHealthProfile,
  updateHealthProfile,
  getStepsHistory,
  getStepsSummary,
  saveStepLog,
  deleteStepLog,
} from "../../services/healthService";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const profile = ref({
  daily_steps_goal: 8000,
  stride_length_cm: 75,
  distance_unit: "km",
});

const stepForm = ref({
  log_date: new Date().toISOString().slice(0, 10),
  steps_count: 0,
  notes: "",
});

const summary = ref({
  days_range: 30,
  logged_days: 0,
  total_steps: 0,
  average_steps: 0,
  total_distance_km: 0,
  average_distance_km: 0,
  goal_completed_days: 0,
  goal_completion_rate: 0,
});

const logs = ref([]);

async function loadDashboard() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const [profileResponse, summaryResponse, historyResponse] =
      await Promise.all([
        getHealthProfile(),
        getStepsSummary(30),
        getStepsHistory(30),
      ]);

    profile.value = profileResponse.data;
    summary.value = summaryResponse.data;
    logs.value = historyResponse.data;
  } catch (error) {
    console.error("Steps dashboard error:", error.response?.data || error);

    errorMessage.value =
    error.response?.data?.message ||
    error.message ||
    "Failed to load steps dashboard.";
  } finally {
    loading.value = false;
  }
}

async function submitProfile() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const response = await updateHealthProfile({
      daily_steps_goal: Number(profile.value.daily_steps_goal),
      stride_length_cm: Number(profile.value.stride_length_cm),
      distance_unit: "km",
    });

    profile.value = response.data;
    successMessage.value = "Health profile updated successfully.";
    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to update health profile.";
  } finally {
    saving.value = false;
  }
}

async function submitStepLog() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await saveStepLog({
      log_date: stepForm.value.log_date,
      steps_count: Number(stepForm.value.steps_count),
      notes: stepForm.value.notes,
    });

    successMessage.value = "Step log saved successfully.";

    stepForm.value.steps_count = 0;
    stepForm.value.notes = "";

    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to save step log.";
  } finally {
    saving.value = false;
  }
}

async function removeLog(id) {
  if (!confirm("Are you sure you want to delete this step log?")) {
    return;
  }

  try {
    await deleteStepLog(id);
    successMessage.value = "Step log deleted successfully.";
    await loadDashboard();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Failed to delete step log.";
  }
}

function formatNumber(value) {
  return new Intl.NumberFormat().format(value || 0);
}

function progressBarWidth(value) {
  const percentage = Number(value || 0);

  if (percentage > 100) {
    return "100%";
  }

  return `${percentage}%`;
}

onMounted(() => {
  loadDashboard();
});
</script>

<template>
  <div class="min-h-screen bg-slate-100 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <!-- Header -->
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-3xl font-bold text-slate-900">
            Steps Tracking
          </h1>
          <p class="text-slate-500">
            Track daily walking activity, distance, and 30-day goal progress.
          </p>
        </div>

        <button
          @click="loadDashboard"
          class="rounded-xl bg-slate-900 px-5 py-2 text-sm font-semibold text-white hover:bg-slate-700"
        >
          Refresh
        </button>
      </div>

      <!-- Alerts -->
      <div
        v-if="errorMessage"
        class="rounded-xl border border-red-200 bg-red-50 p-4 text-red-700"
      >
        {{ errorMessage }}
      </div>

      <div
        v-if="successMessage"
        class="rounded-xl border border-green-200 bg-green-50 p-4 text-green-700"
      >
        {{ successMessage }}
      </div>

      <!-- Loading -->
      <div
        v-if="loading"
        class="rounded-xl bg-white p-6 text-center text-slate-500 shadow-sm"
      >
        Loading steps dashboard...
      </div>

      <template v-else>
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Total Steps</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ formatNumber(summary.total_steps) }}
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Last {{ summary.days_range }} days
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Total Distance</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ summary.total_distance_km }} km
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Average {{ summary.average_distance_km }} km/day
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Average Steps</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ formatNumber(summary.average_steps) }}
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              Based on {{ summary.logged_days }} logged days
            </p>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow-sm">
            <p class="text-sm text-slate-500">Goal Completion</p>
            <h2 class="mt-2 text-3xl font-bold text-slate-900">
              {{ summary.goal_completion_rate }}%
            </h2>
            <p class="mt-1 text-sm text-slate-400">
              {{ summary.goal_completed_days }} completed days
            </p>
          </div>
        </div>

        <!-- Forms -->
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- Add Daily Steps -->
          <div class="rounded-2xl bg-white p-6 shadow-sm">
            <h2 class="text-xl font-bold text-slate-900">
              Add Daily Steps
            </h2>

            <form @submit.prevent="submitStepLog" class="mt-5 space-y-4">
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Date
                </label>
                <input
                  v-model="stepForm.log_date"
                  type="date"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Steps Count
                </label>
                <input
                  v-model="stepForm.steps_count"
                  type="number"
                  min="0"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                  placeholder="Example: 6500"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Notes
                </label>
                <textarea
                  v-model="stepForm.notes"
                  rows="3"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                  placeholder="Optional notes"
                ></textarea>
              </div>

              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
              >
                {{ saving ? "Saving..." : "Save Steps" }}
              </button>
            </form>
          </div>

          <!-- Health Profile -->
          <div class="rounded-2xl bg-white p-6 shadow-sm">
            <h2 class="text-xl font-bold text-slate-900">
              Steps Settings
            </h2>

            <form @submit.prevent="submitProfile" class="mt-5 space-y-4">
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Daily Steps Goal
                </label>
                <input
                  v-model="profile.daily_steps_goal"
                  type="number"
                  min="500"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">
                  Stride Length CM
                </label>
                <input
                  v-model="profile.stride_length_cm"
                  type="number"
                  min="30"
                  step="0.01"
                  class="w-full rounded-xl border border-slate-300 px-4 py-2 focus:border-slate-900 focus:outline-none"
                />
                <p class="mt-1 text-xs text-slate-400">
                  Default: 75 cm. Used to calculate distance.
                </p>
              </div>

              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white hover:bg-slate-700 disabled:opacity-60"
              >
                {{ saving ? "Saving..." : "Update Settings" }}
              </button>
            </form>
          </div>
        </div>

        <!-- History Table -->
        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <div class="mb-5 flex items-center justify-between">
            <div>
              <h2 class="text-xl font-bold text-slate-900">
                30-Day Steps History
              </h2>
              <p class="text-sm text-slate-500">
                Daily logs ordered from newest to oldest.
              </p>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-left">
              <thead>
                <tr class="border-b bg-slate-50 text-sm text-slate-600">
                  <th class="px-4 py-3">Date</th>
                  <th class="px-4 py-3">Steps</th>
                  <th class="px-4 py-3">Distance</th>
                  <th class="px-4 py-3">Goal</th>
                  <th class="px-4 py-3">Progress</th>
                  <th class="px-4 py-3">Status</th>
                  <th class="px-4 py-3">Notes</th>
                  <th class="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="log in logs"
                  :key="log.id"
                  class="border-b text-sm hover:bg-slate-50"
                >
                  <td class="px-4 py-3 font-medium text-slate-900">
                    {{ log.log_date }}
                  </td>

                  <td class="px-4 py-3">
                    {{ formatNumber(log.steps_count) }}
                  </td>

                  <td class="px-4 py-3">
                    {{ log.distance_km }} km
                  </td>

                  <td class="px-4 py-3">
                    {{ formatNumber(log.goal_steps) }}
                  </td>

                  <td class="px-4 py-3">
                    <div class="w-32 rounded-full bg-slate-200">
                      <div
                        class="h-2 rounded-full bg-blue-600"
                        :style="{ width: progressBarWidth(log.goal_percentage) }"
                      ></div>
                    </div>
                    <p class="mt-1 text-xs text-slate-500">
                      {{ log.goal_percentage }}%
                    </p>
                  </td>

                  <td class="px-4 py-3">
                    <span
                      v-if="log.goal_completed"
                      class="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700"
                    >
                      Completed
                    </span>

                    <span
                      v-else
                      class="rounded-full bg-yellow-100 px-3 py-1 text-xs font-semibold text-yellow-700"
                    >
                      In Progress
                    </span>
                  </td>

                  <td class="px-4 py-3 text-slate-500">
                    {{ log.notes || "-" }}
                  </td>

                  <td class="px-4 py-3 text-right">
                    <button
                      @click="removeLog(log.id)"
                      class="rounded-lg bg-red-50 px-3 py-1 text-xs font-semibold text-red-600 hover:bg-red-100"
                    >
                      Delete
                    </button>
                  </td>
                </tr>

                <tr v-if="logs.length === 0">
                  <td colspan="8" class="px-4 py-8 text-center text-slate-400">
                    No step logs found.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>