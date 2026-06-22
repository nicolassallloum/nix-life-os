<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import healthService from "@/services/healthService";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const sportTypes = [
  "Walking",
  "Running",
  "Cycling",
  "Swimming",
  "Gym",
  "Football",
  "Basketball",
  "Yoga",
  "Other",
];

const records = ref([]);

const summary = reactive({
  total_calories_today: 0,
  total_calories_week: 0,
  total_minutes_today: 0,
  total_minutes_week: 0,
});

const form = reactive({
  id: null,
  sport_type: "Walking",
  calories_burned: 0,
  duration_minutes: 30,
  activity_date: new Date().toISOString().slice(0, 10),
  notes: "",
});

const isEditing = computed(() => Boolean(form.id));

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function formatNumber(value) {
  return Math.round(toNumber(value)).toLocaleString();
}

function formatDecimal(value) {
  return toNumber(value).toLocaleString(undefined, {
    maximumFractionDigits: 2,
  });
}

function resetForm() {
  form.id = null;
  form.sport_type = "Walking";
  form.calories_burned = 0;
  form.duration_minutes = 30;
  form.activity_date = new Date().toISOString().slice(0, 10);
  form.notes = "";
}

function normalizeRecords(payload) {
  if (Array.isArray(payload?.records)) return payload.records;
  if (Array.isArray(payload?.data?.records)) return payload.data.records;
  if (Array.isArray(payload)) return payload;
  return [];
}

function applySummary(payload) {
  const nextSummary = payload?.summary || payload?.data?.summary || {};

  summary.total_calories_today = toNumber(nextSummary.total_calories_today);
  summary.total_calories_week = toNumber(nextSummary.total_calories_week);
  summary.total_minutes_today = toNumber(nextSummary.total_minutes_today);
  summary.total_minutes_week = toNumber(nextSummary.total_minutes_week);
}

async function loadSports() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await healthService.sports.list();
    const payload = response?.data?.data ?? response?.data ?? {};

    records.value = normalizeRecords(payload);
    applySummary(payload);
  } catch (error) {
    console.error("Sport tracking load error:", error);
    errorMessage.value =
      error?.response?.data?.message ||
      error?.message ||
      "Unable to load sport activities.";
  } finally {
    loading.value = false;
  }
}

function buildPayload() {
  return {
    sport_type: form.sport_type,
    calories_burned: toNumber(form.calories_burned),
    duration_minutes: Math.max(1, Math.round(toNumber(form.duration_minutes, 1))),
    activity_date: form.activity_date,
    notes: form.notes || null,
  };
}

async function saveSport() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const payload = buildPayload();

    if (form.id) {
      await healthService.sports.update(form.id, payload);
      successMessage.value = "Sport activity updated successfully.";
    } else {
      await healthService.sports.create(payload);
      successMessage.value = "Sport activity added successfully.";
    }

    resetForm();
    await loadSports();
  } catch (error) {
    console.error("Sport tracking save error:", error);

    const validationErrors = error?.errors || error?.response?.data?.errors;
    if (validationErrors) {
      errorMessage.value = Object.values(validationErrors).flat().join(" ");
    } else {
      errorMessage.value =
        error?.response?.data?.message ||
        error?.message ||
        "Unable to save sport activity.";
    }
  } finally {
    saving.value = false;
  }
}

function editSport(record) {
  form.id = record.id;
  form.sport_type = record.sport_type || "Walking";
  form.calories_burned = toNumber(record.calories_burned);
  form.duration_minutes = toNumber(record.duration_minutes, 30);
  form.activity_date =
    record.activity_date || new Date().toISOString().slice(0, 10);
  form.notes = record.notes || "";

  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function deleteSport(id) {
  if (!confirm("Delete this sport activity?")) {
    return;
  }

  errorMessage.value = "";
  successMessage.value = "";

  try {
    await healthService.sports.delete(id);
    successMessage.value = "Sport activity deleted successfully.";
    await loadSports();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.message ||
      "Unable to delete sport activity.";
  }
}

onMounted(() => {
  loadSports();
});
</script>

<template>
  <section class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Sport Tracking
        </h1>
        <p class="mt-1 text-sm text-gray-500">
          Track sport activity, calories burned, duration, dates, and notes.
        </p>
      </div>

      <div class="flex flex-wrap gap-3">
        <RouterLink
          to="/health"
          class="rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50"
        >
          Back to Health
        </RouterLink>

        <button
          type="button"
          class="rounded-xl bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-60"
          :disabled="loading"
          @click="loadSports"
        >
          {{ loading ? "Refreshing..." : "Refresh" }}
        </button>
      </div>
    </div>

    <div
      v-if="errorMessage"
      class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div
      v-if="successMessage"
      class="rounded-xl border border-green-200 bg-green-50 p-4 text-sm font-semibold text-green-700"
    >
      {{ successMessage }}
    </div>

    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <p class="text-sm font-medium text-gray-500">Today Calories Burned</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">
          {{ formatNumber(summary.total_calories_today) }}
          <span class="text-base text-gray-500">kcal</span>
        </p>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <p class="text-sm font-medium text-gray-500">This Week Calories</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">
          {{ formatNumber(summary.total_calories_week) }}
          <span class="text-base text-gray-500">kcal</span>
        </p>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <p class="text-sm font-medium text-gray-500">Today Duration</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">
          {{ formatNumber(summary.total_minutes_today) }}
          <span class="text-base text-gray-500">min</span>
        </p>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <p class="text-sm font-medium text-gray-500">This Week Duration</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">
          {{ formatNumber(summary.total_minutes_week) }}
          <span class="text-base text-gray-500">min</span>
        </p>
      </div>
    </div>

    <div class="grid gap-6 xl:grid-cols-3">
      <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm xl:col-span-1">
        <h2 class="text-xl font-bold text-gray-900">
          {{ isEditing ? "Edit Sport Activity" : "Add Sport Activity" }}
        </h2>

        <form class="mt-5 space-y-4" @submit.prevent="saveSport">
          <div>
            <label class="mb-1 block text-sm font-semibold text-gray-700">
              Sport Type
            </label>
            <select
              v-model="form.sport_type"
              class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-gray-900 focus:outline-none"
              required
            >
              <option v-for="type in sportTypes" :key="type" :value="type">
                {{ type }}
              </option>
            </select>
          </div>

          <div>
            <label class="mb-1 block text-sm font-semibold text-gray-700">
              Activity Date
            </label>
            <input
              v-model="form.activity_date"
              type="date"
              class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-gray-900 focus:outline-none"
              required
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-semibold text-gray-700">
              Duration Minutes
            </label>
            <input
              v-model.number="form.duration_minutes"
              type="number"
              min="1"
              class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-gray-900 focus:outline-none"
              required
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-semibold text-gray-700">
              Calories Burned
            </label>
            <input
              v-model.number="form.calories_burned"
              type="number"
              min="0"
              step="0.01"
              class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-gray-900 focus:outline-none"
              required
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-semibold text-gray-700">
              Notes
            </label>
            <textarea
              v-model="form.notes"
              rows="4"
              class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 placeholder:text-gray-400 focus:border-gray-900 focus:outline-none"
              placeholder="Optional notes..."
            ></textarea>
          </div>

          <div class="flex flex-wrap gap-3">
            <button
              type="submit"
              class="rounded-xl bg-gray-900 px-5 py-2 text-sm font-semibold text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="saving"
            >
              {{ saving ? "Saving..." : isEditing ? "Update Activity" : "Save Activity" }}
            </button>

            <button
              type="button"
              class="rounded-xl border border-gray-300 bg-white px-5 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50"
              @click="resetForm"
            >
              Reset
            </button>
          </div>
        </form>
      </div>

      <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm xl:col-span-2">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">
              Sport Activity History
            </h2>
            <p class="text-sm text-gray-500">
              Latest records first.
            </p>
          </div>
        </div>

        <div
          v-if="loading"
          class="mt-5 rounded-xl bg-gray-50 p-6 text-center text-sm font-medium text-gray-600"
        >
          Loading sport activities...
        </div>

        <div
          v-else-if="records.length === 0"
          class="mt-5 rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center"
        >
          <p class="text-base font-bold text-gray-900">
            No sport activities yet.
          </p>
          <p class="mt-1 text-sm text-gray-500">
            Add your first sport activity using the form.
          </p>
        </div>

        <div v-else class="mt-5 overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left font-bold text-gray-700">Date</th>
                <th class="px-4 py-3 text-left font-bold text-gray-700">Sport</th>
                <th class="px-4 py-3 text-left font-bold text-gray-700">Duration</th>
                <th class="px-4 py-3 text-left font-bold text-gray-700">Calories</th>
                <th class="px-4 py-3 text-left font-bold text-gray-700">Notes</th>
                <th class="px-4 py-3 text-right font-bold text-gray-700">Actions</th>
              </tr>
            </thead>

            <tbody class="divide-y divide-gray-100 bg-white">
              <tr v-for="record in records" :key="record.id">
                <td class="whitespace-nowrap px-4 py-3 text-gray-900">
                  {{ record.activity_date }}
                </td>
                <td class="whitespace-nowrap px-4 py-3 font-semibold text-gray-900">
                  {{ record.sport_type }}
                </td>
                <td class="whitespace-nowrap px-4 py-3 text-gray-700">
                  {{ formatNumber(record.duration_minutes) }} min
                </td>
                <td class="whitespace-nowrap px-4 py-3 text-gray-700">
                  {{ formatDecimal(record.calories_burned) }} kcal
                </td>
                <td class="max-w-xs truncate px-4 py-3 text-gray-500">
                  {{ record.notes || "-" }}
                </td>
                <td class="whitespace-nowrap px-4 py-3 text-right">
                  <button
                    type="button"
                    class="mr-2 rounded-lg bg-indigo-50 px-3 py-1 text-xs font-bold text-indigo-700 hover:bg-indigo-100"
                    @click="editSport(record)"
                  >
                    Edit
                  </button>

                  <button
                    type="button"
                    class="rounded-lg bg-red-50 px-3 py-1 text-xs font-bold text-red-700 hover:bg-red-100"
                    @click="deleteSport(record.id)"
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
  </section>
</template>
