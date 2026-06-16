<script setup>
import { computed, onMounted, reactive, ref, watch } from "vue";
import {
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { healthWeightApi } from "@/services/healthWeightApi";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const logs = ref([]);
const summary = ref({
  total_logs: 0,
  min_weight: null,
  max_weight: null,
  average_weight: null,
  latest_weight: null,
  first_weight: null,
  weight_change: null,
  trend_direction: "no_data",
  chart: [],
});

const form = reactive({
  id: null,
  log_date: new Date().toISOString().slice(0, 10),
  weight_kg: "",
  height_cm: "",
  body_fat_percentage: "",
  muscle_mass_kg: "",
  bmi: "",
  notes: "",
});

const calculatedBmi = computed(() => {
  const weight = Number(form.weight_kg || 0);
  const heightCm = Number(form.height_cm || 0);

  if (weight > 0 && heightCm > 0) {
    const heightM = heightCm / 100;
    return Number((weight / (heightM * heightM)).toFixed(2));
  }

  return form.bmi ? Number(form.bmi) : null;
});

watch(calculatedBmi, (value) => {
  form.bmi = value || "";
});

function resetForm() {
  form.id = null;
  form.log_date = new Date().toISOString().slice(0, 10);
  form.weight_kg = "";
  form.height_cm = "";
  form.body_fat_percentage = "";
  form.muscle_mass_kg = "";
  form.bmi = "";
  form.notes = "";
}

function normalizePayload() {
  return {
    log_date: form.log_date,
    weight_kg: Number(form.weight_kg),
    height_cm: form.height_cm ? Number(form.height_cm) : null,
    length_cm: form.height_cm ? Number(form.height_cm) : null,
    body_fat_percentage: form.body_fat_percentage
      ? Number(form.body_fat_percentage)
      : null,
    muscle_mass_kg: form.muscle_mass_kg ? Number(form.muscle_mass_kg) : null,
    bmi: calculatedBmi.value ? Number(calculatedBmi.value) : null,
    notes: form.notes || null,
  };
}

async function loadData() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const [logsResponse, summaryResponse] = await Promise.all([
      healthWeightApi.getLogs(),
      healthWeightApi.getSummary(),
    ]);

    logs.value = logsResponse.data.data || [];
    summary.value = summaryResponse.data;
  } catch (error) {
    errorMessage.value =
      error?.message || "Failed to load weight module data.";
  } finally {
    loading.value = false;
  }
}

async function saveLog() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const payload = normalizePayload();

    if (form.id) {
      await healthWeightApi.updateLog(form.id, payload);
      successMessage.value = "Weight log updated successfully.";
    } else {
      await healthWeightApi.createLog(payload);
      successMessage.value = "Weight log added successfully.";
    }

    resetForm();
    await loadData();
  } catch (error) {
    if (error?.errors) {
      errorMessage.value = Object.values(error.errors).flat().join(" ");
    } else {
      errorMessage.value = error?.message || "Failed to save weight log.";
    }
  } finally {
    saving.value = false;
  }
}

function editLog(log) {
  form.id = log.id;
  form.log_date = log.log_date;
  form.weight_kg = log.weight_kg;
  form.height_cm = log.height_cm || "";
  form.body_fat_percentage = log.body_fat_percentage || "";
  form.muscle_mass_kg = log.muscle_mass_kg || "";
  form.bmi = log.bmi || "";
  form.notes = log.notes || "";
}

async function deleteLog(id) {
  if (!confirm("Are you sure you want to delete this weight log?")) {
    return;
  }

  errorMessage.value = "";
  successMessage.value = "";

  try {
    await healthWeightApi.deleteLog(id);
    successMessage.value = "Weight log deleted successfully.";
    await loadData();
  } catch (error) {
    errorMessage.value = error?.message || "Failed to delete weight log.";
  }
}

function trendBadgeClass(direction) {
  if (direction === "decreasing") {
    return "bg-green-100 text-green-700";
  }

  if (direction === "increasing") {
    return "bg-orange-100 text-orange-700";
  }

  if (direction === "stable") {
    return "bg-blue-100 text-blue-700";
  }

  return "bg-gray-100 text-gray-700";
}

onMounted(loadData);
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Weight Tracking
        </h1>
        <p class="mt-1 text-gray-500">
          Track your weight logs, analyze trends, and monitor progress.
        </p>
      </div>

      <div v-if="errorMessage" class="rounded-xl bg-red-50 p-4 text-red-700">
        {{ errorMessage }}
      </div>

      <div
        v-if="successMessage"
        class="rounded-xl bg-green-50 p-4 text-green-700"
      >
        {{ successMessage }}
      </div>

      <div class="grid grid-cols-1 gap-4 md:grid-cols-5">
        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Latest Weight</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.latest_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Average</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.average_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Minimum</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.min_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Maximum</p>
          <p class="mt-2 text-2xl font-bold text-gray-900">
            {{ summary.max_weight ?? "-" }} kg
          </p>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">Trend</p>
          <div class="mt-2 flex items-center gap-2">
            <span
              class="rounded-full px-3 py-1 text-sm font-semibold"
              :class="trendBadgeClass(summary.trend_direction)"
            >
              {{ summary.trend_direction }}
            </span>
          </div>
          <p class="mt-2 text-sm text-gray-500">
            Change: {{ summary.weight_change ?? "-" }} kg
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="rounded-2xl bg-white p-6 shadow-sm lg:col-span-2">
          <div class="mb-4 flex items-center justify-between">
            <div>
              <h2 class="text-xl font-bold text-gray-900">
                Weight Trend Chart
              </h2>
              <p class="text-sm text-gray-500">
                Your weight movement over time.
              </p>
            </div>
          </div>

          <div v-if="summary.chart?.length" class="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart :data="summary.chart">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="weight_kg"
                  strokeWidth="3"
                  dot
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          <div
            v-else
            class="flex h-80 items-center justify-center rounded-xl border border-dashed text-gray-400"
          >
            No weight chart data yet.
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow-sm">
          <h2 class="text-xl font-bold text-gray-900">
            {{ form.id ? "Edit Weight Log" : "Add Weight Log" }}
          </h2>

          <form class="mt-5 space-y-4" @submit.prevent="saveLog">
            <div>
              <label class="block text-sm font-medium text-gray-700">
                Date
              </label>
              <input
                v-model="form.log_date"
                type="date"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Weight KG
              </label>
              <input
                v-model="form.weight_kg"
                type="number"
                step="0.01"
                min="20"
                max="400"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Length / Height CM
              </label>
              <input
                v-model="form.height_cm"
                type="number"
                step="0.1"
                min="30"
                max="250"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
                placeholder="Example: 151"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Body Fat %
              </label>
              <input
                v-model="form.body_fat_percentage"
                type="number"
                step="0.01"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Muscle Mass KG
              </label>
              <input
                v-model="form.muscle_mass_kg"
                type="number"
                step="0.01"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                BMI
              </label>
              <input
                v-model="form.bmi"
                type="number"
                step="0.01"
                readonly
                class="mt-1 w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
                placeholder="Auto calculated from weight and height"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Notes
              </label>
              <textarea
                v-model="form.notes"
                rows="3"
                class="mt-1 w-full rounded-xl border border-gray-300 px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-blue-500 focus:outline-none"
              ></textarea>
            </div>

            <div class="flex gap-3">
              <button
                type="submit"
                :disabled="saving"
                class="w-full rounded-xl bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {{ saving ? "Saving..." : form.id ? "Update" : "Save" }}
              </button>

              <button
                v-if="form.id"
                type="button"
                @click="resetForm"
                class="rounded-xl border border-gray-300 px-4 py-2 font-semibold text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>

      <div class="rounded-2xl bg-white p-6 shadow-sm">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">
              Weight Logs
            </h2>
            <p class="text-sm text-gray-500">
              Complete history of your weight records.
            </p>
          </div>
        </div>

        <div v-if="loading" class="py-10 text-center text-gray-500">
          Loading weight logs...
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b bg-gray-50 text-sm text-gray-600">
                <th class="px-4 py-3">Date</th>
                <th class="px-4 py-3">Weight</th>
                <th class="px-4 py-3">BMI</th>
                <th class="px-4 py-3">Body Fat</th>
                <th class="px-4 py-3">Muscle Mass</th>
                <th class="px-4 py-3">Notes</th>
                <th class="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in logs"
                :key="log.id"
                class="border-b text-sm hover:bg-gray-50"
              >
                <td class="px-4 py-3 font-medium text-gray-900">
                  {{ log.log_date }}
                </td>
                <td class="px-4 py-3">
                  {{ log.weight_kg }} kg
                </td>
                <td class="px-4 py-3">
                  {{ log.bmi ?? "-" }}
                </td>
                <td class="px-4 py-3">
                  {{ log.body_fat_percentage ?? "-" }}
                </td>
                <td class="px-4 py-3">
                  {{ log.muscle_mass_kg ?? "-" }}
                </td>
                <td class="px-4 py-3 text-gray-500">
                  {{ log.notes ?? "-" }}
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    class="mr-3 font-semibold text-blue-600 hover:text-blue-800"
                    @click="editLog(log)"
                  >
                    Edit
                  </button>
                  <button
                    class="font-semibold text-red-600 hover:text-red-800"
                    @click="deleteLog(log.id)"
                  >
                    Delete
                  </button>
                </td>
              </tr>

              <tr v-if="logs.length === 0">
                <td colspan="7" class="px-4 py-10 text-center text-gray-400">
                  No weight logs yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
