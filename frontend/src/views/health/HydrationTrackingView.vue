<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div>
      <h1 class="text-2xl font-bold text-slate-900">Hydration Tracking</h1>
      <p class="text-sm text-slate-500">
        Track your daily water intake and hydration progress.
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
        <p class="text-sm text-slate-500">Today Intake</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ todayWaterMl.toLocaleString() }} ml
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Daily Goal</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ dailyGoalMl.toLocaleString() }} ml
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
          {{ hydrationLogs.length }}
        </h2>
      </div>
    </div>

    <!-- Progress Bar -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-2 flex items-center justify-between">
        <h2 class="text-lg font-semibold text-slate-900">Daily Hydration Progress</h2>
        <span class="text-sm font-medium text-slate-600">{{ goalProgress }}%</span>
      </div>

      <div class="h-3 w-full rounded-full bg-slate-100">
        <div
          class="h-3 rounded-full bg-indigo-600 transition-all"
          :style="{ width: `${goalProgress}%` }"
        ></div>
      </div>

      <p class="mt-3 text-sm text-slate-500">
        {{ todayWaterMl.toLocaleString() }} ml consumed out of
        {{ dailyGoalMl.toLocaleString() }} ml target.
      </p>
    </div>

    <!-- Add Hydration Form -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-900">Add Hydration Log</h2>
      <p class="mb-5 text-sm text-slate-500">
        Record water intake for a selected date.
      </p>

      <form class="grid grid-cols-1 gap-4 md:grid-cols-4" @submit.prevent="saveHydrationLog">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Date</label>
          <input
            v-model="form.log_date"
            type="date"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20" required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Water ML</label>
          <input
            v-model.number="form.water_ml"
            type="number"
            min="1"
            step="1"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20" required
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Drink Type</label>
          <select
            v-model="form.drink_type"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20">
            <option value="water">Water</option>
            <option value="tea">Tea</option>
            <option value="coffee">Coffee</option>
            <option value="juice">Juice</option>
            <option value="other">Other</option>
          </select>
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
            {{ loading ? "Saving..." : "Save Hydration" }}
          </button>
        </div>
      </form>
    </div>

    <!-- Hydration Table -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">Recent Hydration Logs</h2>
          <p class="text-sm text-slate-500">Latest water intake records.</p>
        </div>

        <button
          class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          @click="loadHydrationLogs"
        >
          Refresh
        </button>
      </div>

      <div
        v-if="loading && hydrationLogs.length === 0"
        class="py-8 text-center text-sm text-slate-500"
      >
        Loading hydration logs...
      </div>

      <div
        v-else-if="hydrationLogs.length === 0"
        class="py-8 text-center text-sm text-slate-500"
      >
        No hydration logs found.
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full border-collapse text-left text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-slate-500">
              <th class="py-3 pr-4 font-medium">Date</th>
              <th class="py-3 pr-4 font-medium">Water ML</th>
              <th class="py-3 pr-4 font-medium">Drink Type</th>
              <th class="py-3 pr-4 font-medium">Notes</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="log in hydrationLogs"
              :key="log.id"
              class="border-b border-slate-100 text-slate-700"
            >
              <td class="py-3 pr-4">{{ log.log_date || log.date }}</td>
              <td class="py-3 pr-4">
                {{ Number(log.water_ml || log.amount_ml || log.intake_ml || 0).toLocaleString() }}
              </td>
              <td class="py-3 pr-4 capitalize">
                {{ log.drink_type || log.type || "water" }}
              </td>
              <td class="py-3 pr-4">
                {{ log.notes || "-" }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Quick Add Buttons -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-900">Quick Add</h2>
      <p class="mb-4 text-sm text-slate-500">
        Quickly add common water amounts for today.
      </p>

      <div class="flex flex-wrap gap-3">
        <button
          v-for="amount in quickAmounts"
          :key="amount"
          type="button"
          :disabled="loading"
          class="rounded-xl border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
          @click="quickAdd(amount)"
        >
          +{{ amount }} ml
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api/v1";

const loading = ref(false);
const error = ref("");
const successMessage = ref("");
const hydrationLogs = ref([]);

const dailyGoalMl = ref(2000);
const quickAmounts = [100, 250, 330, 500, 750];

const form = ref({
  log_date: new Date().toISOString().slice(0, 10),
  water_ml: "",
  drink_type: "water",
  notes: "",
});

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const todayWaterMl = computed(() => {
  const today = new Date().toISOString().slice(0, 10);

  return hydrationLogs.value
    .filter((log) => (log.log_date || log.date) === today)
    .reduce((total, log) => {
      return total + Number(log.water_ml || log.amount_ml || log.intake_ml || log.quantity_ml || log.ml || 0);
    }, 0);
});

const goalProgress = computed(() => {
  if (!dailyGoalMl.value) return 0;
  return Math.min(Math.round((todayWaterMl.value / dailyGoalMl.value) * 100), 100);
});

const normalizeList = (result) => {
  if (Array.isArray(result.data)) return result.data;
  if (Array.isArray(result.data?.data)) return result.data.data;
  if (Array.isArray(result.data?.logs)) return result.data.logs;
  if (Array.isArray(result.data?.hydration_logs)) return result.data.hydration_logs;
  return [];
};

const loadHydrationLogs = async () => {
  try {
    loading.value = true;
    error.value = "";

    const response = await fetch(`${API_BASE_URL}/health/hydration`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load hydration logs.");
    }

    hydrationLogs.value = normalizeList(result);
  } catch (err) {
    console.error("Hydration load error:", err);
    error.value = err.message || "Failed to load hydration logs.";
  } finally {
    loading.value = false;
  }
};

const saveHydrationLog = async () => {
  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    const payload = {
      log_date: form.value.log_date,
      water_ml: Number(form.value.water_ml),
      amount_ml: Number(form.value.water_ml),
      quantity_ml: Number(form.value.water_ml),
      drink_type: form.value.drink_type || "water",
      hydration_type: form.value.drink_type === "water" ? "Water" : form.value.drink_type,
      notes: form.value.notes || null,
    };

    const response = await fetch(`${API_BASE_URL}/health/hydration`, {
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
      throw new Error(result.message || "Failed to save hydration log.");
    }

    successMessage.value = "Hydration log saved successfully.";

    form.value = {
      log_date: new Date().toISOString().slice(0, 10),
      water_ml: "",
      drink_type: "water",
      notes: "",
    };

    await loadHydrationLogs();
  } catch (err) {
    console.error("Hydration save error:", err);
    error.value = err.message || "Failed to save hydration log.";
  } finally {
    loading.value = false;
  }
};

const quickAdd = async (amount) => {
  form.value = {
    log_date: new Date().toISOString().slice(0, 10),
    water_ml: amount,
    drink_type: "water",
    notes: `Quick add ${amount} ml`,
  };

  await saveHydrationLog();
};

onMounted(() => {
  loadHydrationLogs();
});
</script>

<style scoped>
/* Health follow-up readability fix: force readable text in light form fields */
input,
select,
textarea,
input:disabled,
select:disabled,
textarea:disabled,
input[readonly],
select[readonly],
textarea[readonly] {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  caret-color: #2563eb !important;
  opacity: 1 !important;
  color-scheme: light !important;
}

input::placeholder,
textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

select option,
option {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
}

input:-webkit-autofill,
textarea:-webkit-autofill,
select:-webkit-autofill {
  -webkit-text-fill-color: #020617 !important;
  box-shadow: 0 0 0 1000px #ffffff inset !important;
  transition: background-color 9999s ease-out 0s !important;
}

input::selection,
textarea::selection,
select::selection {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
  background-color: #2563eb !important;
}

input::-moz-selection,
textarea::-moz-selection,
select::-moz-selection {
  color: #ffffff !important;
  background-color: #2563eb !important;
}
</style>
