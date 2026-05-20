<script setup>
import { computed, onMounted, ref } from "vue";

const API_BASE_URL = "/api/v1";

const token = localStorage.getItem("token");

const logs = ref([]);
const dailySummary = ref(null);
const weeklySummary = ref([]);
const loading = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const today = new Date().toISOString().slice(0, 10);

const selectedDate = ref(today);

const form = ref({
  log_date: today,
  log_time: "",
  drink_type: "water",
  amount_ml: 250,
  is_ckd_safe: true,
  source: "manual",
  notes: "",
});

const drinkTypes = [
  { value: "water", label: "Water" },
  { value: "tea", label: "Tea" },
  { value: "coffee", label: "Coffee" },
  { value: "juice", label: "Juice" },
  { value: "soup", label: "Soup" },
  { value: "milk", label: "Milk" },
  { value: "other", label: "Other" },
];

const quickAmounts = [100, 150, 200, 250, 300, 500];

const totalMl = computed(() => {
  return dailySummary.value?.total_ml || 0;
});

const totalLiters = computed(() => {
  return dailySummary.value?.total_liters || 0;
});

const hydrationGoalMl = 2000;

const progressPercentage = computed(() => {
  const percentage = (totalMl.value / hydrationGoalMl) * 100;
  return Math.min(Math.round(percentage), 100);
});

async function apiRequest(endpoint, options = {}) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || "API request failed");
  }

  return data;
}

async function fetchLogs() {
  const data = await apiRequest(
    `/health/hydration?date=${selectedDate.value}&per_page=50`
  );

  logs.value = data.data?.data || data.data || [];
}

async function fetchDailySummary() {
  const data = await apiRequest(
    `/health/hydration/daily-summary?date=${selectedDate.value}`
  );

  dailySummary.value = data.data;
}

async function fetchWeeklySummary() {
  const currentDate = new Date(selectedDate.value);
  const day = currentDate.getDay();

  const diffToMonday = day === 0 ? -6 : 1 - day;

  const monday = new Date(currentDate);
  monday.setDate(currentDate.getDate() + diffToMonday);

  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);

  const startDate = monday.toISOString().slice(0, 10);
  const endDate = sunday.toISOString().slice(0, 10);

  const data = await apiRequest(
    `/health/hydration/weekly-summary?start_date=${startDate}&end_date=${endDate}`
  );

  weeklySummary.value = data.data?.days || [];
}

async function loadDashboard() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await Promise.all([
      fetchLogs(),
      fetchDailySummary(),
      fetchWeeklySummary(),
    ]);
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function submitForm() {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest("/health/hydration", {
      method: "POST",
      body: JSON.stringify({
        ...form.value,
        amount_ml: Number(form.value.amount_ml),
      }),
    });

    successMessage.value = "Hydration log added successfully.";

    form.value.amount_ml = 250;
    form.value.drink_type = "water";
    form.value.notes = "";

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function quickAdd(amount) {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest("/health/hydration/quick-add", {
      method: "POST",
      body: JSON.stringify({
        amount_ml: amount,
        drink_type: "water",
        log_date: selectedDate.value,
      }),
    });

    successMessage.value = `${amount}ml water added successfully.`;

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function deleteLog(id) {
  if (!confirm("Are you sure you want to delete this hydration log?")) {
    return;
  }

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    await apiRequest(`/health/hydration/${id}`, {
      method: "DELETE",
    });

    successMessage.value = "Hydration log deleted successfully.";

    await loadDashboard();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

function getDrinkLabel(value) {
  return drinkTypes.find((item) => item.value === value)?.label || value;
}

function getMaxChartValue() {
  const values = weeklySummary.value.map((item) => Number(item.total_ml));
  return Math.max(...values, hydrationGoalMl);
}

onMounted(() => {
  loadDashboard();
});
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <!-- Header -->
      <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">
            Hydration Tracking
          </h1>
          <p class="mt-1 text-gray-600">
            Track daily water and fluid intake with quick add and drink breakdown.
          </p>
        </div>

        <div class="flex items-center gap-3">
          <input
            v-model="selectedDate"
            type="date"
            class="rounded-xl border border-gray-300 bg-white px-4 py-2 shadow-sm focus:border-blue-500 focus:outline-none"
            @change="loadDashboard"
          />

          <button
            class="rounded-xl bg-blue-600 px-5 py-2 font-semibold text-white shadow hover:bg-blue-700 disabled:opacity-50"
            :disabled="loading"
            @click="loadDashboard"
          >
            Refresh
          </button>
        </div>
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

      <!-- Dashboard Cards -->
      <div class="grid gap-6 md:grid-cols-4">
        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Today Intake</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ totalMl }} ml
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            {{ totalLiters }} liters
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Daily Goal</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ hydrationGoalMl }} ml
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            CKD users should follow doctor limits.
          </p>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Progress</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ progressPercentage }}%
          </h2>

          <div class="mt-4 h-3 rounded-full bg-gray-200">
            <div
              class="h-3 rounded-full bg-blue-600"
              :style="{ width: progressPercentage + '%' }"
            ></div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-6 shadow">
          <p class="text-sm font-medium text-gray-500">Entries</p>
          <h2 class="mt-2 text-3xl font-bold text-gray-900">
            {{ logs.length }}
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Total logs for selected date
          </p>
        </div>
      </div>

      <!-- Quick Add -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">Quick Add Water</h2>
            <p class="text-sm text-gray-500">
              Add common water amounts with one click.
            </p>
          </div>
        </div>

        <div class="flex flex-wrap gap-3">
          <button
            v-for="amount in quickAmounts"
            :key="amount"
            class="rounded-xl bg-blue-50 px-5 py-3 font-semibold text-blue-700 hover:bg-blue-100 disabled:opacity-50"
            :disabled="loading"
            @click="quickAdd(amount)"
          >
            + {{ amount }} ml
          </button>
        </div>
      </div>

      <div class="grid gap-6 lg:grid-cols-3">
        <!-- Form -->
        <div class="rounded-2xl bg-white p-6 shadow lg:col-span-1">
          <h2 class="text-xl font-bold text-gray-900">Add Drink</h2>

          <form class="mt-5 space-y-4" @submit.prevent="submitForm">
            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Date
              </label>
              <input
                v-model="form.log_date"
                type="date"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Time
              </label>
              <input
                v-model="form.log_time"
                type="time"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Drink Type
              </label>
              <select
                v-model="form.drink_type"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              >
                <option
                  v-for="drink in drinkTypes"
                  :key="drink.value"
                  :value="drink.value"
                >
                  {{ drink.label }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Amount ML
              </label>
              <input
                v-model="form.amount_ml"
                type="number"
                min="1"
                max="5000"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-gray-700">
                Notes
              </label>
              <textarea
                v-model="form.notes"
                rows="3"
                class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
                placeholder="Optional notes..."
              ></textarea>
            </div>

            <button
              type="submit"
              class="w-full rounded-xl bg-blue-600 px-5 py-3 font-semibold text-white shadow hover:bg-blue-700 disabled:opacity-50"
              :disabled="loading"
            >
              Add Hydration Log
            </button>
          </form>
        </div>

        <!-- Daily Breakdown -->
        <div class="rounded-2xl bg-white p-6 shadow lg:col-span-2">
          <h2 class="text-xl font-bold text-gray-900">Daily Drink Breakdown</h2>
          <p class="mt-1 text-sm text-gray-500">
            Breakdown by drink type for {{ selectedDate }}.
          </p>

          <div class="mt-6 space-y-4">
            <div
              v-if="!dailySummary?.breakdown?.length"
              class="rounded-xl bg-gray-50 p-5 text-center text-gray-500"
            >
              No hydration data for this date.
            </div>

            <div
              v-for="item in dailySummary?.breakdown || []"
              :key="item.drink_type"
              class="space-y-2"
            >
              <div class="flex items-center justify-between">
                <span class="font-medium text-gray-700">
                  {{ getDrinkLabel(item.drink_type) }}
                </span>
                <span class="text-sm font-semibold text-gray-900">
                  {{ item.total_ml }} ml
                </span>
              </div>

              <div class="h-3 rounded-full bg-gray-200">
                <div
                  class="h-3 rounded-full bg-blue-600"
                  :style="{
                    width:
                      totalMl > 0
                        ? Math.round((item.total_ml / totalMl) * 100) + '%'
                        : '0%',
                  }"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Weekly Chart -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <h2 class="text-xl font-bold text-gray-900">Weekly Hydration Chart</h2>
        <p class="mt-1 text-sm text-gray-500">
          Daily totals for the selected week.
        </p>

        <div class="mt-6 flex h-72 items-end gap-4 border-b border-gray-200 pb-4">
          <div
            v-for="day in weeklySummary"
            :key="day.log_date"
            class="flex flex-1 flex-col items-center justify-end gap-2"
          >
            <div
              class="w-full rounded-t-xl bg-blue-500"
              :style="{
                height:
                  getMaxChartValue() > 0
                    ? Math.max((day.total_ml / getMaxChartValue()) * 220, 8) + 'px'
                    : '8px',
              }"
            ></div>

            <div class="text-center">
              <p class="text-xs font-semibold text-gray-700">
                {{ day.total_ml }}ml
              </p>
              <p class="text-xs text-gray-500">
                {{ day.log_date.slice(5) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Logs Table -->
      <div class="rounded-2xl bg-white p-6 shadow">
        <h2 class="text-xl font-bold text-gray-900">Hydration Logs</h2>

        <div class="mt-5 overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr class="bg-gray-50">
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Date
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Time
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Drink
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Amount
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Source
                </th>
                <th class="px-4 py-3 text-left text-sm font-semibold text-gray-600">
                  Notes
                </th>
                <th class="px-4 py-3 text-right text-sm font-semibold text-gray-600">
                  Action
                </th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100">
              <tr v-if="!logs.length">
                <td colspan="7" class="px-4 py-6 text-center text-gray-500">
                  No hydration logs found.
                </td>
              </tr>

              <tr v-for="log in logs" :key="log.id">
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.log_date }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.log_time || "-" }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ getDrinkLabel(log.drink_type) }}
                </td>
                <td class="px-4 py-3 text-sm font-semibold text-gray-900">
                  {{ log.amount_ml }} ml
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.source }}
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">
                  {{ log.notes || "-" }}
                </td>
                <td class="px-4 py-3 text-right">
                  <button
                    class="rounded-lg bg-red-50 px-3 py-1 text-sm font-semibold text-red-600 hover:bg-red-100"
                    @click="deleteLog(log.id)"
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
