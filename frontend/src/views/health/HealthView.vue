<template>
  <section class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">
          Health Dashboard
        </h1>
        <p class="mt-1 text-sm text-gray-500">
          Daily and weekly overview for steps, weight, nutrition, hydration, sleep, mood, and medications.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-60"
        :disabled="loading"
        @click="loadHealthDashboard"
      >
        {{ loading ? "Refreshing..." : "Refresh Dashboard" }}
      </button>
    </div>

    <!-- Health Quick Actions -->
    <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
      <div class="mb-4 flex flex-col gap-1">
        <h2 class="text-lg font-bold text-gray-900">
          Health Tools
        </h2>
        <p class="text-sm text-gray-500">
          Open detailed tracking pages for each health area.
        </p>
      </div>

      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-7">
        <RouterLink
          to="/health/steps"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">👟</span>
            <span>Steps</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/weight"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">⚖️</span>
            <span>Weight</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/nutrition"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">🍽️</span>
            <span>Nutrition</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/custom-foods"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">🥗</span>
            <span>Custom Foods</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/hydration"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">💧</span>
            <span>Hydration</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/sleep"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">😴</span>
            <span>Sleep</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/mood"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">😊</span>
            <span>Mood</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/medications"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">💊</span>
            <span>Medications</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/lab-tests"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">🧪</span>
            <span>Lab Tests</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/alerts"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">🚨</span>
            <span>Alerts</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/reports"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">📊</span>
            <span>Reports</span>
          </div>
        </RouterLink>

        <RouterLink
          to="/health/ai-insights"
          class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm font-semibold text-gray-700 transition hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700"
        >
          <div class="flex items-center gap-3">
            <span class="text-xl">🧠</span>
            <span>AI Insights</span>
          </div>
        </RouterLink>
      </div>
    </div>

    <!-- Loading State -->
    <div
      v-if="loading"
      class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm"
    >
      <p class="text-sm font-medium text-gray-700">
        Loading health dashboard...
      </p>
      <div class="mt-4 grid gap-4 md:grid-cols-4">
        <div
          v-for="item in 8"
          :key="item"
          class="h-28 animate-pulse rounded-2xl bg-gray-100"
        />
      </div>
    </div>

    <!-- Error State -->
    <div
      v-else-if="error"
      class="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700"
    >
      <h2 class="text-lg font-bold">
        Unable to load Health Dashboard
      </h2>
      <p class="mt-2 text-sm">
        {{ error }}
      </p>
      <button
        type="button"
        class="mt-4 rounded-xl bg-red-700 px-4 py-2 text-sm font-semibold text-white hover:bg-red-800"
        @click="loadHealthDashboard"
      >
        Try Again
      </button>
    </div>

    <!-- Dashboard Content -->
    <div v-else class="space-y-6">
      <!-- KPI Cards -->
      <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div
          v-for="card in kpiCards"
          :key="card.title"
          class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-sm font-medium text-gray-500">
                {{ card.title }}
              </p>
              <p class="mt-2 text-2xl font-bold text-gray-900">
                {{ card.value }}
              </p>
              <p class="mt-1 text-xs text-gray-500">
                {{ card.note }}
              </p>
            </div>

            <div class="rounded-2xl bg-gray-100 px-3 py-2 text-xl">
              {{ card.icon }}
            </div>
          </div>
        </div>
      </div>

      <!-- Daily + Weekly Summary -->
      <div class="grid gap-4 xl:grid-cols-2">
        <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
          <h2 class="text-lg font-bold text-gray-900">
            Daily Summary
          </h2>

          <div class="mt-4 grid gap-3 sm:grid-cols-2">
            <SummaryRow label="Steps Today" :value="`${daily.steps} steps`" />
            <SummaryRow label="Water Today" :value="`${daily.waterMl} ml`" />
            <SummaryRow label="Calories Today" :value="`${daily.calories} kcal`" />
            <SummaryRow label="Protein Today" :value="`${daily.protein} g / ${goalValue('protein_limit_g', '-')} g`" />
            <SummaryRow label="Sodium Today" :value="`${daily.sodium} mg / ${goalValue('sodium_limit_mg', '-')} mg`" />
            <SummaryRow label="Potassium Today" :value="`${daily.potassium} mg / ${goalValue('potassium_limit_mg', '-')} mg`" />
            <SummaryRow label="Phosphorus Today" :value="`${daily.phosphorus} mg / ${goalValue('phosphorus_limit_mg', '-')} mg`" />
            <SummaryRow label="Sleep Today" :value="`${daily.sleepHours} hours`" />
            <SummaryRow label="Medications" :value="`${daily.medications} active`" />
          </div>
        </div>

        <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
          <h2 class="text-lg font-bold text-gray-900">
            Weekly Summary
          </h2>

          <div class="mt-4 grid gap-3 sm:grid-cols-2">
            <SummaryRow label="Weekly Steps" :value="`${weekly.steps} steps`" />
            <SummaryRow label="Average Steps" :value="`${weekly.averageSteps} / day`" />
            <SummaryRow label="Weekly Water" :value="`${weekly.waterMl} ml`" />
            <SummaryRow label="Average Sleep" :value="`${weekly.averageSleep} hours`" />
            <SummaryRow label="Mood Average" :value="weekly.averageMood" />
            <SummaryRow label="Nutrition Status" :value="nutritionStatus" />
          </div>
        </div>
      </div>

      <!-- Chart Ready Sections -->
      <div class="grid gap-4 xl:grid-cols-2">
        <ChartCard
          title="Steps Trend"
          subtitle="Last 30 days"
          :items="stepsChart"
          value-key="steps"
          empty-message="No step data available yet."
        />

        <ChartCard
          title="Hydration Trend"
          subtitle="Water intake logs"
          :items="hydrationChart"
          value-key="amount_ml"
          empty-message="No hydration data available yet."
        />

        <ChartCard
          title="Weight Trend"
          subtitle="Latest weight records"
          :items="weightChart"
          value-key="weight_kg"
          empty-message="No weight data available yet."
        />

        <ChartCard
          title="Sleep Trend"
          subtitle="Sleep duration records"
          :items="sleepChart"
          value-key="duration_hours"
          empty-message="No sleep data available yet."
        />
      </div>

      <!-- Module Status -->
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <h2 class="text-lg font-bold text-gray-900">
          Health Module Data Status
        </h2>

        <div class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <StatusPill label="Steps" :count="steps.length" />
          <StatusPill label="Weight" :count="weight.length" />
          <StatusPill label="Nutrition" :count="nutrition.length" />
          <StatusPill label="Hydration" :count="hydration.length" />
          <StatusPill label="Sleep" :count="sleep.length" />
          <StatusPill label="Mood" :count="mood.length" />
          <StatusPill label="Medications" :count="medications.length" />
          <StatusPill label="Dashboard API" :count="dashboardLoaded ? 1 : 0" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "/api/v1";

const loading = ref(false);
const error = ref("");

const dashboardSummary = ref(null);
const nutritionSummary = ref(null);

const steps = ref([]);
const weight = ref([]);
const nutrition = ref([]);
const hydration = ref([]);
const sleep = ref([]);
const mood = ref([]);
const medications = ref([]);

const dashboardLoaded = ref(false);

function getToken() {
  return (
    localStorage.getItem("nix_token") ||
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

async function apiGet(endpoint) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: "GET",
    headers: {
      Accept: "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(data?.message || `API request failed: ${endpoint}`);
  }

  return data;
}

function normalizeArray(payload) {
  if (Array.isArray(payload?.data)) {
    return payload.data;
  }

  if (Array.isArray(payload?.data?.data)) {
    return payload.data.data;
  }

  if (Array.isArray(payload?.items)) {
    return payload.items;
  }

  if (Array.isArray(payload)) {
    return payload;
  }

  return [];
}

function toNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function getDateValue(item) {
  return (
    item?.date ||
    item?.log_date ||
    item?.logged_at ||
    item?.created_at ||
    item?.sleep_date ||
    item?.taken_at ||
    ""
  );
}

function isToday(dateValue) {
  if (!dateValue) {
    return false;
  }

  const today = new Date().toISOString().slice(0, 10);
  return String(dateValue).slice(0, 10) === today;
}

function isWithinLastDays(dateValue, days = 7) {
  if (!dateValue) {
    return false;
  }

  const date = new Date(dateValue);
  if (Number.isNaN(date.getTime())) {
    return false;
  }

  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = diffMs / (1000 * 60 * 60 * 24);

  return diffDays >= 0 && diffDays <= days;
}

function sumBy(items, keys) {
  return items.reduce((total, item) => {
    const value = keys
      .map((key) => item?.[key])
      .find((candidate) => candidate !== undefined && candidate !== null);

    return total + toNumber(value);
  }, 0);
}

function latestValue(items, keys, fallback = null) {
  if (!items.length) {
    return fallback;
  }

  const sorted = [...items].sort((a, b) => {
    const dateA = new Date(getDateValue(a)).getTime() || 0;
    const dateB = new Date(getDateValue(b)).getTime() || 0;

    return dateB - dateA;
  });

  const latest = sorted[0];

  for (const key of keys) {
    if (latest?.[key] !== undefined && latest?.[key] !== null) {
      return latest[key];
    }
  }

  return fallback;
}

async function loadHealthDashboard() {
  loading.value = true;
  error.value = "";

  try {
    const [
      dashboardResponse,
      stepsResponse,
      weightResponse,
      nutritionResponse,
      nutritionSummaryResponse,
      hydrationResponse,
      sleepResponse,
      moodResponse,
      medicationsResponse,
    ] = await Promise.allSettled([
      apiGet("/health/dashboard"),
      apiGet("/health/steps"),
      apiGet("/health/weight"),
      apiGet("/health/nutrition"),
      apiGet("/health/nutrition/summary"),
      apiGet("/health/hydration"),
      apiGet("/health/sleep"),
      apiGet("/health/mood"),
      apiGet("/health/medications"),
    ]);

    if (dashboardResponse.status === "fulfilled") {
      dashboardSummary.value = dashboardResponse.value?.data || null;
      dashboardLoaded.value = true;
    }

    if (stepsResponse.status === "fulfilled") {
      steps.value = normalizeArray(stepsResponse.value);
    }

    if (weightResponse.status === "fulfilled") {
      weight.value = normalizeArray(weightResponse.value);
    }

    if (nutritionResponse.status === "fulfilled") {
      nutrition.value = normalizeArray(nutritionResponse.value);
    }

    if (nutritionSummaryResponse.status === "fulfilled") {
      nutritionSummary.value = nutritionSummaryResponse.value?.data || null;
    }

    if (hydrationResponse.status === "fulfilled") {
      hydration.value = normalizeArray(hydrationResponse.value);
    }

    if (sleepResponse.status === "fulfilled") {
      sleep.value = normalizeArray(sleepResponse.value);
    }

    if (moodResponse.status === "fulfilled") {
      mood.value = normalizeArray(moodResponse.value);
    }

    if (medicationsResponse.status === "fulfilled") {
      medications.value = normalizeArray(medicationsResponse.value);
    }

    const failed = [
      dashboardResponse,
      stepsResponse,
      weightResponse,
      nutritionResponse,
      nutritionSummaryResponse,
      hydrationResponse,
      sleepResponse,
      moodResponse,
      medicationsResponse,
    ].filter((result) => result.status === "rejected");

    if (failed.length >= 5) {
      throw new Error("Most health dashboard APIs failed. Please check backend services.");
    }

    error.value = "";
  } catch (err) {
    error.value = err?.message || "Unexpected error while loading health dashboard.";
  } finally {
    loading.value = false;
  }
}

const todayStepsFromApi = computed(() => {
  return toNumber(dashboardSummary.value?.today_steps);
});

const todayWaterFromApi = computed(() => {
  return toNumber(dashboardSummary.value?.today_water_ml);
});

const latestWeightFromApi = computed(() => {
  return dashboardSummary.value?.current_weight_kg ?? null;
});

const dashboardGoals = computed(() => dashboardSummary.value?.goals ?? {});
const dashboardProgress = computed(() => dashboardSummary.value?.progress ?? {});

function percentValue(key) {
  return Math.min(100, Math.max(0, toNumber(dashboardProgress.value?.[key])));
}

function goalValue(key, fallback = null) {
  const value = dashboardGoals.value?.[key];
  return value === null || value === undefined ? fallback : value;
}

const todayStepsFromLogs = computed(() => {
  const todayLogs = steps.value.filter((item) => isToday(getDateValue(item)));
  return sumBy(todayLogs, ["steps", "step_count", "count"]);
});

const todayWaterFromLogs = computed(() => {
  const todayLogs = hydration.value.filter((item) => isToday(getDateValue(item)));
  return sumBy(todayLogs, ["amount_ml", "water_ml", "quantity_ml", "ml"]);
});

const daily = computed(() => {
  const todayNutritionLogs = nutrition.value.filter((item) => isToday(getDateValue(item)));
  const todaySleepLogs = sleep.value.filter((item) => isToday(getDateValue(item)));

  return {
    steps: todayStepsFromApi.value || todayStepsFromLogs.value,
    waterMl: todayWaterFromApi.value || todayWaterFromLogs.value,
    calories:
      dashboardSummary.value?.today_calories ??
      nutritionSummary.value?.total_calories ??
      sumBy(todayNutritionLogs, ["calories", "total_calories"]),
    protein:
      dashboardSummary.value?.today_protein_g ??
      nutritionSummary.value?.total_protein ??
      sumBy(todayNutritionLogs, ["protein_g", "protein"]),
    sodium:
      dashboardSummary.value?.today_sodium_mg ??
      nutritionSummary.value?.total_sodium ??
      sumBy(todayNutritionLogs, ["sodium_mg", "sodium"]),
    potassium:
      dashboardSummary.value?.today_potassium_mg ??
      nutritionSummary.value?.total_potassium ??
      sumBy(todayNutritionLogs, ["potassium_mg", "potassium"]),
    phosphorus:
      dashboardSummary.value?.today_phosphorus_mg ??
      nutritionSummary.value?.total_phosphorus ??
      sumBy(todayNutritionLogs, ["phosphorus_mg", "phosphorus"]),
    sleepHours: dashboardSummary.value?.last_sleep_hours ?? sumBy(todaySleepLogs, ["duration_hours", "sleep_hours", "hours"]),
    medications: dashboardSummary.value?.active_medications ?? medications.value.length,
  };
});

const weekly = computed(() => {
  const weekSteps = steps.value.filter((item) => isWithinLastDays(getDateValue(item), 7));
  const weekHydration = hydration.value.filter((item) => isWithinLastDays(getDateValue(item), 7));
  const weekSleep = sleep.value.filter((item) => isWithinLastDays(getDateValue(item), 7));
  const weekMood = mood.value.filter((item) => isWithinLastDays(getDateValue(item), 7));

  const stepsTotal = sumBy(weekSteps, ["steps", "step_count", "count"]);
  const waterTotal = sumBy(weekHydration, ["amount_ml", "water_ml", "quantity_ml", "ml"]);
  const sleepTotal = sumBy(weekSleep, ["duration_hours", "sleep_hours", "hours"]);
  const moodTotal = sumBy(weekMood, ["mood_score", "score", "rating"]);

  return {
    steps: stepsTotal,
    averageSteps: Math.round(stepsTotal / 7),
    waterMl: waterTotal,
    averageSleep: weekSleep.length ? (sleepTotal / weekSleep.length).toFixed(1) : "0.0",
    averageMood: weekMood.length ? (moodTotal / weekMood.length).toFixed(1) : "No Data",
  };
});

const currentWeight = computed(() => {
  return latestWeightFromApi.value ?? latestValue(weight.value, ["weight_kg", "weight"], null);
});

const latestMood = computed(() => {
  if (dashboardSummary.value?.today_mood && dashboardSummary.value.today_mood !== "-") {
    return dashboardSummary.value.today_mood;
  }

  const value = latestValue(mood.value, ["mood_label", "mood", "status"], null);
  const score = latestValue(mood.value, ["mood_score", "score", "rating"], null);

  if (value) {
    return value;
  }

  if (score !== null) {
    return `${score}/5`;
  }

  return "No Data";
});

const nutritionStatus = computed(() => {
  const trackedPercents = [
    percentValue("protein_percent"),
    percentValue("sodium_percent"),
    percentValue("potassium_percent"),
    percentValue("phosphorus_percent"),
  ];

  if (trackedPercents.some((value) => value > 100)) {
    return "Review Limits";
  }

  if (trackedPercents.some((value) => value > 0)) {
    return "Within Limits";
  }

  const status = nutritionSummary.value?.status;

  if (!status) {
    return "No Data";
  }

  const hasExceeded = Object.values(status).some((value) => value !== "within_limit");

  return hasExceeded ? "Review Limits" : "Within Limits";
});

const kpiCards = computed(() => [
  {
    title: "Steps Today",
    value: `${daily.value.steps}`,
    note: `Goal: ${goalValue("daily_steps_goal", 8000)} | ${percentValue("steps_percent")}%`,
    icon: "👟",
  },
  {
    title: "Current Weight",
    value: currentWeight.value ? `${currentWeight.value} kg` : "No Data",
    note: goalValue("target_weight_kg") ? `Target: ${goalValue("target_weight_kg")} kg` : "Latest weight log",
    icon: "⚖️",
  },
  {
    title: "Calories Today",
    value: `${daily.value.calories}`,
    note: `Goal: ${goalValue("daily_calories_goal", 1800)} | ${percentValue("calories_percent")}%`,
    icon: "🍽️",
  },
  {
    title: "Water Today",
    value: `${daily.value.waterMl} ml`,
    note: `Goal: ${goalValue("daily_water_goal_ml", 2000)} ml | ${percentValue("water_percent")}%`,
    icon: "💧",
  },
  {
    title: "Sleep Today",
    value: `${daily.value.sleepHours} h`,
    note: "Sleep duration",
    icon: "😴",
  },
  {
    title: "Mood",
    value: latestMood.value,
    note: "Latest mood log",
    icon: "🙂",
  },
  {
    title: "Medications",
    value: `${daily.value.medications}`,
    note: "Active medication records",
    icon: "💊",
  },
  {
    title: "Nutrition Limits",
    value: nutritionStatus.value,
    note: "Kidney-friendly limits",
    icon: "🧪",
  },
]);

const stepsChart = computed(() => steps.value.slice(-10));
const hydrationChart = computed(() => hydration.value.slice(-10));
const weightChart = computed(() => weight.value.slice(-10));
const sleepChart = computed(() => sleep.value.slice(-10));

const SummaryRow = defineComponent({
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number],
      required: true,
    },
  },
  setup(props) {
    return () =>
      h("div", { class: "rounded-xl bg-gray-50 p-4" }, [
        h("p", { class: "text-xs font-medium text-gray-500" }, props.label),
        h("p", { class: "mt-1 text-lg font-bold text-gray-900" }, props.value),
      ]);
  },
});

const StatusPill = defineComponent({
  props: {
    label: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
  setup(props) {
    return () =>
      h(
        "div",
        {
          class:
            "flex items-center justify-between rounded-xl border border-gray-200 bg-gray-50 px-4 py-3",
        },
        [
          h("span", { class: "text-sm font-medium text-gray-700" }, props.label),
          h(
            "span",
            {
              class:
                "rounded-full bg-white px-3 py-1 text-xs font-bold text-gray-900 shadow-sm",
            },
            props.count > 0 ? `${props.count}` : "0"
          ),
        ]
      );
  },
});

const ChartCard = defineComponent({
  props: {
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    valueKey: {
      type: String,
      required: true,
    },
    emptyMessage: {
      type: String,
      required: true,
    },
  },
  setup(props) {
    const maxValue = computed(() => {
      const values = props.items.map((item) => toNumber(item?.[props.valueKey]));
      return Math.max(...values, 1);
    });

    return () =>
      h("div", { class: "rounded-2xl border border-gray-200 bg-white p-5 shadow-sm" }, [
        h("div", {}, [
          h("h2", { class: "text-lg font-bold text-gray-900" }, props.title),
          h("p", { class: "mt-1 text-sm text-gray-500" }, props.subtitle),
        ]),

        props.items.length === 0
          ? h(
              "div",
              {
                class:
                  "mt-4 rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center text-sm text-gray-500",
              },
              props.emptyMessage
            )
          : h(
              "div",
              { class: "mt-4 flex h-44 items-end gap-2 rounded-xl bg-gray-50 p-4" },
              props.items.map((item, index) => {
                const value = toNumber(item?.[props.valueKey]);
                const height = Math.max((value / maxValue.value) * 100, 8);

                return h("div", { class: "flex flex-1 flex-col items-center gap-2" }, [
                  h("div", {
                    class: "w-full rounded-t-lg bg-gray-900",
                    style: {
                      height: `${height}%`,
                    },
                    title: String(value),
                  }),
                  h(
                    "span",
                    { class: "text-[10px] text-gray-500" },
                    String(index + 1)
                  ),
                ]);
              })
            ),
      ]);
  },
});

onMounted(() => {
  loadHealthDashboard();
});
</script>
