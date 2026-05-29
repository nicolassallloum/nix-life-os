<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div>
      <h1 class="text-2xl font-bold text-slate-900">Weight Tracking</h1>
      <p class="text-sm text-slate-500">
        Track your body weight, BMI, and progress over time.
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
        <p class="text-sm text-slate-500">Latest Weight</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ latestWeight }} kg
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Target Weight</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ targetWeight }} kg
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Difference</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ weightDifference }} kg
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Total Records</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ weightLogs.length }}
        </h2>
      </div>
    </div>

    <!-- Add Weight Form -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-900">Add Weight Log</h2>
      <p class="mb-5 text-sm text-slate-500">
        Record your weight for a selected date.
      </p>

      <form class="grid grid-cols-1 gap-4 md:grid-cols-4" @submit.prevent="saveWeightLog">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Date</label>
          <input
            v-model="form.log_date"
            type="date"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"            required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Weight KG</label>
          <input
            v-model.number="form.weight_kg"
            type="number"
            min="1"
            step="0.1"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"            required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">BMI</label>
          <input
            v-model.number="form.bmi"
            type="number"
            min="1"
            step="0.1"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Notes</label>
          <input
            v-model="form.notes"
            type="text"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"            placeholder="Optional notes"
          />
        </div>

        <div class="md:col-span-4">
          <button
            type="submit"
            :disabled="loading"
            class="rounded-xl bg-indigo-600 px-5 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {{ loading ? "Saving..." : "Save Weight" }}
          </button>
        </div>
      </form>
    </div>

    <!-- Weight Table -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">Recent Weight Logs</h2>
          <p class="text-sm text-slate-500">Latest body weight records.</p>
        </div>

        <button
          class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          @click="loadWeightLogs"
        >
          Refresh
        </button>
      </div>

      <div v-if="loading && weightLogs.length === 0" class="py-8 text-center text-sm text-slate-500">
        Loading weight logs...
      </div>

      <div v-else-if="weightLogs.length === 0" class="py-8 text-center text-sm text-slate-500">
        No weight logs found.
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full border-collapse text-left text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-slate-500">
              <th class="py-3 pr-4 font-medium">Date</th>
              <th class="py-3 pr-4 font-medium">Weight KG</th>
              <th class="py-3 pr-4 font-medium">BMI</th>
              <th class="py-3 pr-4 font-medium">Notes</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="log in weightLogs"
              :key="log.id"
              class="border-b border-slate-100 text-slate-700"
            >
              <td class="py-3 pr-4">{{ log.log_date || log.date }}</td>
              <td class="py-3 pr-4">{{ log.weight_kg || log.weight || 0 }}</td>
              <td class="py-3 pr-4">{{ log.bmi || "-" }}</td>
              <td class="py-3 pr-4">{{ log.notes || "-" }}</td>
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
const weightLogs = ref([]);

const targetWeight = ref(60);

const form = ref({
  log_date: new Date().toISOString().slice(0, 10),
  weight_kg: "",
  bmi: "",
  notes: "",
});

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const latestWeight = computed(() => {
  if (!weightLogs.value.length) return 0;

  const latest = weightLogs.value[0];

  return Number(latest.weight_kg || latest.weight || 0);
});

const weightDifference = computed(() => {
  const difference = latestWeight.value - targetWeight.value;
  return Number(difference.toFixed(1));
});

const normalizeList = (result) => {
  if (Array.isArray(result.data)) return result.data;
  if (Array.isArray(result.data?.data)) return result.data.data;
  if (Array.isArray(result.data?.logs)) return result.data.logs;
  return [];
};

const loadWeightLogs = async () => {
  try {
    loading.value = true;
    error.value = "";

    const response = await fetch(`${API_BASE_URL}/health/weight`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load weight logs.");
    }

    weightLogs.value = normalizeList(result);
  } catch (err) {
    console.error("Weight load error:", err);
    error.value = err.message || "Failed to load weight logs.";
  } finally {
    loading.value = false;
  }
};

const saveWeightLog = async () => {
  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    const payload = {
      log_date: form.value.log_date,
      weight_kg: Number(form.value.weight_kg),
      bmi: form.value.bmi ? Number(form.value.bmi) : null,
      notes: form.value.notes || null,
    };

    const response = await fetch(`${API_BASE_URL}/health/weight`, {
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
      throw new Error(result.message || "Failed to save weight log.");
    }

    successMessage.value = "Weight log saved successfully.";

    form.value = {
      log_date: new Date().toISOString().slice(0, 10),
      weight_kg: "",
      bmi: "",
      notes: "",
    };

    await loadWeightLogs();
  } catch (err) {
    console.error("Weight save error:", err);
    error.value = err.message || "Failed to save weight log.";
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  loadWeightLogs();
});
</script>