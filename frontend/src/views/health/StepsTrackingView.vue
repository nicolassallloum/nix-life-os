<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div>
      <h1 class="text-2xl font-bold text-slate-900">Steps Tracking</h1>
      <p class="text-sm text-slate-500">
        Track your daily steps, distance, and activity progress.
      </p>
    </div>

    <!-- Error Message -->
    <div
      v-if="error"
      class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ error }}
    </div>

    <!-- Success Message -->
    <div
      v-if="successMessage"
      class="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700"
    >
      {{ successMessage }}
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Today Steps</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ todaySteps.toLocaleString() }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Goal</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ dailyGoal.toLocaleString() }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Progress</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ goalProgress }}%
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Total Records</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ stepLogs.length }}
        </h2>
      </div>
    </div>

    <!-- Add Steps Form -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-900">Add Step Log</h2>
      <p class="mb-5 text-sm text-slate-500">
        Record your steps for a selected date.
      </p>

      <form class="grid grid-cols-1 gap-4 md:grid-cols-4" @submit.prevent="saveStepLog">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Date</label>
          <input
            v-model="form.log_date"
            type="date"
            class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
            required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Steps</label>
          <input
            v-model.number="form.steps"
            type="number"
            min="0"
            class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
            required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Distance KM</label>
          <input
            v-model.number="form.distance_km"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Calories</label>
          <input
            v-model.number="form.calories_burned"
            type="number"
            min="0"
            class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          />
        </div>

        <div class="md:col-span-4">
          <button
            type="submit"
            :disabled="loading"
            class="rounded-xl bg-indigo-600 px-5 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {{ loading ? "Saving..." : "Save Steps" }}
          </button>
        </div>
      </form>
    </div>

    <!-- Steps Table -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">Recent Step Logs</h2>
          <p class="text-sm text-slate-500">Latest health activity records.</p>
        </div>

        <button
          class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          @click="loadStepLogs"
        >
          Refresh
        </button>
      </div>

      <div v-if="loading && stepLogs.length === 0" class="py-8 text-center text-sm text-slate-500">
        Loading step logs...
      </div>

      <div v-else-if="stepLogs.length === 0" class="py-8 text-center text-sm text-slate-500">
        No step logs found.
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full border-collapse text-left text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-slate-500">
              <th class="py-3 pr-4 font-medium">Date</th>
              <th class="py-3 pr-4 font-medium">Steps</th>
              <th class="py-3 pr-4 font-medium">Distance KM</th>
              <th class="py-3 pr-4 font-medium">Calories</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="log in stepLogs"
              :key="log.id"
              class="border-b border-slate-100 text-slate-700"
            >
              <td class="py-3 pr-4">{{ log.log_date || log.date }}</td>
              <td class="py-3 pr-4">{{ Number(log.steps || 0).toLocaleString() }}</td>
              <td class="py-3 pr-4">{{ log.distance_km || 0 }}</td>
              <td class="py-3 pr-4">{{ log.calories_burned || 0 }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000";

const loading = ref(false);
const error = ref("");
const successMessage = ref("");
const stepLogs = ref([]);

const dailyGoal = ref(10000);

const form = ref({
  log_date: new Date().toISOString().slice(0, 10),
  steps: 0,
  distance_km: 0,
  calories_burned: 0,
});

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const todaySteps = computed(() => {
  const today = new Date().toISOString().slice(0, 10);

  const todayLog = stepLogs.value.find((log) => {
    return log.log_date === today || log.date === today;
  });

  return Number(todayLog?.steps || 0);
});

const goalProgress = computed(() => {
  if (!dailyGoal.value) return 0;
  return Math.min(Math.round((todaySteps.value / dailyGoal.value) * 100), 100);
});

const normalizeList = (result) => {
  if (Array.isArray(result.data)) return result.data;
  if (Array.isArray(result.data?.data)) return result.data.data;
  if (Array.isArray(result.data?.logs)) return result.data.logs;
  return [];
};

const loadStepLogs = async () => {
  try {
    loading.value = true;
    error.value = "";

    const response = await fetch(`${API_BASE_URL}/api/v1/health/steps`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load step logs.");
    }

    stepLogs.value = normalizeList(result);
  } catch (err) {
    console.error("Steps load error:", err);
    error.value = err.message || "Failed to load step logs.";
  } finally {
    loading.value = false;
  }
};

const saveStepLog = async () => {
  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    const payload = {
      log_date: form.value.log_date,
      steps: Number(form.value.steps),
      distance_km: Number(form.value.distance_km || 0),
      calories_burned: Number(form.value.calories_burned || 0),
    };

    const response = await fetch(`${API_BASE_URL}/api/v1/health/steps`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token()}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to save step log.");
    }

    successMessage.value = "Step log saved successfully.";

    form.value = {
      log_date: new Date().toISOString().slice(0, 10),
      steps: 0,
      distance_km: 0,
      calories_burned: 0,
    };

    await loadStepLogs();
  } catch (err) {
    console.error("Steps save error:", err);
    error.value = err.message || "Failed to save step log.";
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  loadStepLogs();
});
</script>