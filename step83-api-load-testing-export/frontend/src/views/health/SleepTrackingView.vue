<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Sleep Tracking</h1>
        <p class="text-sm text-slate-500">
          Track sleep duration, sleep quality, weekly average, and sleep trends.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        @click="loadSleepLogs"
      >
        Refresh
      </button>
    </div>

    <!-- Error -->
    <div
      v-if="error"
      class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ error }}
    </div>

    <!-- Success -->
    <div
      v-if="successMessage"
      class="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700"
    >
      {{ successMessage }}
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Last Sleep Duration</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ formatDuration(lastSleepMinutes) }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Weekly Average</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ weeklyAverageHours }}h
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Average Quality</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ averageQualityScore }}%
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Total Records</p>
        <h2 class="mt-2 text-2xl font-bold text-slate-900">
          {{ sleepLogs.length }}
        </h2>
      </div>
    </div>

    <!-- Quality Progress -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-2 flex items-center justify-between">
        <h2 class="text-lg font-semibold text-slate-900">Sleep Quality Score</h2>
        <span class="text-sm font-medium text-slate-600">
          {{ averageQualityScore }}%
        </span>
      </div>

      <div class="h-3 w-full rounded-full bg-slate-100">
        <div
          class="h-3 rounded-full bg-indigo-600 transition-all"
          :style="{ width: `${Math.min(averageQualityScore, 100)}%` }"
        ></div>
      </div>

      <p class="mt-3 text-sm text-slate-500">
        Average quality score calculated from your saved sleep logs.
      </p>
    </div>

    <!-- Add / Edit Form -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-5 flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">
            {{ editingId ? "Edit Sleep Log" : "Add Sleep Log" }}
          </h2>
          <p class="text-sm text-slate-500">
            Record your bedtime, wake time, quality score, and notes.
          </p>
        </div>

        <button
          v-if="editingId"
          type="button"
          class="rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          @click="resetForm"
        >
          Cancel Edit
        </button>
      </div>

      <form class="grid grid-cols-1 gap-4 md:grid-cols-5" @submit.prevent="saveSleepLog">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Sleep Date
          </label>
          <input
            v-model="form.sleep_date"
            type="date"
            required
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Bed Time
          </label>
          <input
            v-model="form.bed_time"
            type="time"
            required
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Wake Date
          </label>
          <input
            v-model="form.wake_date"
            type="date"
            required
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Wake Time
          </label>
          <input
            v-model="form.wake_time"
            type="time"
            required
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Quality %
          </label>
          <input
            v-model.number="form.quality_score"
            type="number"
            min="0"
            max="100"
            step="1"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"            placeholder="0 - 100"
          />
        </div>

        <div class="md:col-span-5">
          <label class="mb-1 block text-sm font-medium text-slate-700">
            Notes
          </label>
          <input
            v-model="form.notes"
            type="text"
            class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"            placeholder="Optional notes"
          />
        </div>

        <div class="md:col-span-5">
          <button
            type="submit"
            :disabled="loading"
            class="rounded-xl bg-indigo-600 px-5 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {{ loading ? "Saving..." : editingId ? "Update Sleep Log" : "Save Sleep Log" }}
          </button>
        </div>
      </form>
    </div>

    <!-- Sleep Trend Chart -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-4">
        <h2 class="text-lg font-semibold text-slate-900">Sleep Trend Chart</h2>
        <p class="text-sm text-slate-500">
          Duration trend based on your latest sleep records.
        </p>
      </div>

      <div
        v-if="sleepLogs.length === 0"
        class="rounded-xl bg-slate-50 py-10 text-center text-sm text-slate-500"
      >
        No sleep trend data available.
      </div>

      <div v-else class="flex h-72 items-end gap-4 border-b border-slate-200 pb-4">
        <div
          v-for="log in trendLogs"
          :key="log.id"
          class="flex flex-1 flex-col items-center justify-end gap-2"
        >
          <div
            class="w-full rounded-t-xl bg-indigo-500"
            :style="{ height: `${getBarHeight(log)}px` }"
          ></div>

          <div class="text-center">
            <p class="text-xs font-semibold text-slate-700">
              {{ durationHours(log.duration_minutes) }}h
            </p>
            <p class="text-xs text-slate-500">
              {{ shortDate(log.sleep_date) }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Logs Table -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between">
        <div>
          <h2 class="text-lg font-semibold text-slate-900">Recent Sleep Logs</h2>
          <p class="text-sm text-slate-500">Latest sleep records.</p>
        </div>

        <button
          class="text-sm font-medium text-indigo-600 hover:text-indigo-800"
          @click="loadSleepLogs"
        >
          Refresh
        </button>
      </div>

      <div
        v-if="loading && sleepLogs.length === 0"
        class="py-8 text-center text-sm text-slate-500"
      >
        Loading sleep logs...
      </div>

      <div
        v-else-if="sleepLogs.length === 0"
        class="py-8 text-center text-sm text-slate-500"
      >
        No sleep logs found.
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full border-collapse text-left text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-slate-500">
              <th class="py-3 pr-4 font-medium">Sleep Date</th>
              <th class="py-3 pr-4 font-medium">Bed Time</th>
              <th class="py-3 pr-4 font-medium">Wake Time</th>
              <th class="py-3 pr-4 font-medium">Duration</th>
              <th class="py-3 pr-4 font-medium">Quality</th>
              <th class="py-3 pr-4 font-medium">Notes</th>
              <th class="py-3 pr-4 text-right font-medium">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="log in sleepLogs"
              :key="log.id"
              class="border-b border-slate-100 text-slate-700"
            >
              <td class="py-3 pr-4">{{ log.sleep_date }}</td>
              <td class="py-3 pr-4">{{ formatDateTime(log.bed_time) }}</td>
              <td class="py-3 pr-4">{{ formatDateTime(log.wake_time) }}</td>
              <td class="py-3 pr-4 font-semibold">
                {{ formatDuration(log.duration_minutes) }}
              </td>
              <td class="py-3 pr-4">
                {{ log.quality_score ?? "-" }}%
              </td>
              <td class="py-3 pr-4">
                {{ log.notes || "-" }}
              </td>
              <td class="py-3 pr-4 text-right">
                <div class="flex justify-end gap-2">
                  <button
                    type="button"
                    class="rounded-lg bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-200"
                    @click="startEdit(log)"
                  >
                    Edit
                  </button>

                  <button
                    type="button"
                    class="rounded-lg bg-red-50 px-3 py-1 text-xs font-semibold text-red-600 hover:bg-red-100"
                    @click="deleteSleepLog(log.id)"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Quick Add -->
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold text-slate-900">Quick Add</h2>
      <p class="mb-4 text-sm text-slate-500">
        Quickly add common sleep durations for testing.
      </p>

      <div class="flex flex-wrap gap-3">
        <button
          v-for="preset in quickPresets"
          :key="preset.label"
          type="button"
          :disabled="loading"
          class="rounded-xl border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
          @click="quickAdd(preset.hours, preset.quality)"
        >
          {{ preset.label }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1";

const loading = ref(false);
const error = ref("");
const successMessage = ref("");
const sleepLogs = ref([]);
const editingId = ref(null);

const today = new Date().toISOString().slice(0, 10);

const tomorrowDate = () => {
  const date = new Date();
  date.setDate(date.getDate() + 1);
  return date.toISOString().slice(0, 10);
};

const form = ref({
  sleep_date: today,
  bed_time: "23:00",
  wake_date: tomorrowDate(),
  wake_time: "07:00",
  quality_score: 85,
  notes: "",
});

const quickPresets = [
  { label: "Good Sleep 8h", hours: 8, quality: 85 },
  { label: "Short Sleep 6h", hours: 6, quality: 65 },
  { label: "Excellent 9h", hours: 9, quality: 95 },
];

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const normalizeList = (result) => {
  if (Array.isArray(result.data)) return result.data;
  if (Array.isArray(result.data?.data)) return result.data.data;
  if (Array.isArray(result.data?.logs)) return result.data.logs;
  if (Array.isArray(result.data?.sleep_logs)) return result.data.sleep_logs;
  return [];
};

const sleepLogsSortedAsc = computed(() => {
  return [...sleepLogs.value].sort((a, b) => {
    return new Date(a.sleep_date) - new Date(b.sleep_date);
  });
});

const trendLogs = computed(() => {
  return sleepLogsSortedAsc.value.slice(-7);
});

const lastSleepMinutes = computed(() => {
  if (!sleepLogs.value.length) return 0;
  return Number(sleepLogs.value[0]?.duration_minutes || 0);
});

const weeklyAverageHours = computed(() => {
  if (!sleepLogs.value.length) return 0;

  const lastSeven = sleepLogs.value.slice(0, 7);
  const totalMinutes = lastSeven.reduce((sum, log) => {
    return sum + Number(log.duration_minutes || 0);
  }, 0);

  return Number((totalMinutes / lastSeven.length / 60).toFixed(2));
});

const averageQualityScore = computed(() => {
  const validScores = sleepLogs.value
    .map((log) => Number(log.quality_score))
    .filter((score) => !Number.isNaN(score));

  if (!validScores.length) return 0;

  const total = validScores.reduce((sum, score) => sum + score, 0);
  return Math.round(total / validScores.length);
});

const maxDurationMinutes = computed(() => {
  const values = trendLogs.value.map((log) => Number(log.duration_minutes || 0));
  return Math.max(...values, 480);
});

const durationHours = (minutes) => {
  return Number((Number(minutes || 0) / 60).toFixed(1));
};

const formatDuration = (minutes) => {
  const total = Number(minutes || 0);

  if (total <= 0) return "0h";

  const hours = Math.floor(total / 60);
  const mins = total % 60;

  if (mins === 0) return `${hours}h`;

  return `${hours}h ${mins}m`;
};

const shortDate = (dateValue) => {
  if (!dateValue) return "-";
  return String(dateValue).slice(5);
};

const formatDateTime = (dateTime) => {
  if (!dateTime) return "-";
  return String(dateTime).replace("T", " ").slice(0, 16);
};

const buildDateTime = (dateValue, timeValue) => {
  return `${dateValue} ${timeValue}:00`;
};

const splitDateTime = (dateTime) => {
  const value = String(dateTime || "");
  const clean = value.replace("T", " ");

  return {
    date: clean.slice(0, 10),
    time: clean.slice(11, 16),
  };
};

const getBarHeight = (log) => {
  const minutes = Number(log.duration_minutes || 0);
  const max = maxDurationMinutes.value || 480;

  return Math.max((minutes / max) * 220, 8);
};

const loadSleepLogs = async () => {
  try {
    loading.value = true;
    error.value = "";

    const response = await fetch(`${API_BASE_URL}/health/sleep`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load sleep logs.");
    }

    sleepLogs.value = normalizeList(result);
  } catch (err) {
    console.error("Sleep load error:", err);
    error.value = err.message || "Failed to load sleep logs.";
  } finally {
    loading.value = false;
  }
};

const saveSleepLog = async () => {
  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    const payload = {
      sleep_date: form.value.sleep_date,
      bed_time: buildDateTime(form.value.sleep_date, form.value.bed_time),
      wake_time: buildDateTime(form.value.wake_date, form.value.wake_time),
      quality_score:
        form.value.quality_score === "" || form.value.quality_score === null
          ? null
          : Number(form.value.quality_score),
      notes: form.value.notes || null,
    };

    const url = editingId.value
      ? `${API_BASE_URL}/health/sleep/${editingId.value}`
      : `${API_BASE_URL}/health/sleep`;

    const method = editingId.value ? "PUT" : "POST";

    const response = await fetch(url, {
      method,
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token()}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      const validationErrors = result.errors
        ? Object.values(result.errors).flat().join(" ")
        : "";

      throw new Error(validationErrors || result.message || "Failed to save sleep log.");
    }

    successMessage.value = editingId.value
      ? "Sleep log updated successfully."
      : "Sleep log saved successfully.";

    resetForm();
    await loadSleepLogs();
  } catch (err) {
    console.error("Sleep save error:", err);
    error.value = err.message || "Failed to save sleep log.";
  } finally {
    loading.value = false;
  }
};

const startEdit = (log) => {
  const bed = splitDateTime(log.bed_time);
  const wake = splitDateTime(log.wake_time);

  editingId.value = log.id;

  form.value = {
    sleep_date: log.sleep_date || bed.date || today,
    bed_time: bed.time || "23:00",
    wake_date: wake.date || tomorrowDate(),
    wake_time: wake.time || "07:00",
    quality_score: log.quality_score ?? "",
    notes: log.notes || "",
  };

  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
};

const deleteSleepLog = async (id) => {
  if (!confirm("Are you sure you want to delete this sleep log?")) {
    return;
  }

  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    const response = await fetch(`${API_BASE_URL}/health/sleep/${id}`, {
      method: "DELETE",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to delete sleep log.");
    }

    successMessage.value = "Sleep log deleted successfully.";

    if (editingId.value === id) {
      resetForm();
    }

    await loadSleepLogs();
  } catch (err) {
    console.error("Sleep delete error:", err);
    error.value = err.message || "Failed to delete sleep log.";
  } finally {
    loading.value = false;
  }
};

const quickAdd = async (hours, quality) => {
  const now = new Date();
  const bed = new Date(now);
  bed.setDate(now.getDate() - 1);
  bed.setHours(23, 0, 0, 0);

  const wake = new Date(bed);
  wake.setHours(bed.getHours() + hours);

  form.value = {
    sleep_date: bed.toISOString().slice(0, 10),
    bed_time: bed.toTimeString().slice(0, 5),
    wake_date: wake.toISOString().slice(0, 10),
    wake_time: wake.toTimeString().slice(0, 5),
    quality_score: quality,
    notes: `Quick add ${hours} hours sleep`,
  };

  await saveSleepLog();
};

const resetForm = () => {
  editingId.value = null;

  form.value = {
    sleep_date: today,
    bed_time: "23:00",
    wake_date: tomorrowDate(),
    wake_time: "07:00",
    quality_score: 85,
    notes: "",
  };
};

onMounted(() => {
  loadSleepLogs();
});
</script>
