<template>
  <section class="min-h-screen bg-slate-50 p-6">
    <!-- Header -->
    <div class="mb-8">
      <p class="text-sm font-semibold uppercase tracking-wide text-slate-500">
        Nix Life OS
      </p>

      <h1 class="mt-2 text-3xl font-bold text-slate-900">
        Unified Dashboard
      </h1>

      <p class="mt-2 text-slate-600">
        A unified view of your finance, health, projects, productivity, and life balance.
      </p>
    </div>

    <!-- Loading -->
    <div
      v-if="loading"
      class="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm"
    >
      <div class="mx-auto h-10 w-10 animate-spin rounded-full border-4 border-slate-200 border-t-slate-900"></div>
      <p class="mt-4 text-slate-600">
        Loading dashboard summary...
      </p>
    </div>

    <!-- Error -->
    <div
      v-else-if="error"
      class="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700 shadow-sm"
    >
      <h2 class="text-lg font-bold">
        Unable to load dashboard
      </h2>

      <p class="mt-2">
        {{ error }}
      </p>

      <button
        class="mt-4 rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
        @click="loadDashboard"
      >
        Retry
      </button>
    </div>

    <!-- Dashboard Content -->
    <div v-else>
      <!-- Main KPI Cards -->
      <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-sm font-semibold text-slate-500">
            Total Balance
          </p>
          <h2 class="mt-3 text-3xl font-bold text-slate-900">
            {{ formatCurrency(summary.total_balance) }}
          </h2>
          <p class="mt-2 text-sm text-slate-500">
            Current financial position
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-sm font-semibold text-slate-500">
            Monthly Income
          </p>
          <h2 class="mt-3 text-3xl font-bold text-emerald-700">
            {{ formatCurrency(summary.income) }}
          </h2>
          <p class="mt-2 text-sm text-slate-500">
            Income this month
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-sm font-semibold text-slate-500">
            Monthly Expense
          </p>
          <h2 class="mt-3 text-3xl font-bold text-red-700">
            {{ formatCurrency(summary.monthly_expense) }}
          </h2>
          <p class="mt-2 text-sm text-slate-500">
            Expenses this month
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p class="text-sm font-semibold text-slate-500">
            Savings Rate
          </p>
          <h2 class="mt-3 text-3xl font-bold text-blue-700">
            {{ safeNumber(summary.savings_rate) }}%
          </h2>
          <p class="mt-2 text-sm text-slate-500">
            Income saved percentage
          </p>
        </div>
      </div>

      <!-- Domain Cards -->
      <div class="mt-8 grid gap-6 lg:grid-cols-3">
        <!-- Health -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold text-slate-900">
              Health
            </h2>
            <span class="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700">
              Tracking
            </span>
          </div>

          <div class="mt-6 space-y-4">
            <div class="flex justify-between border-b border-slate-100 pb-3">
              <span class="text-slate-500">Today Steps</span>
              <strong class="text-slate-900">{{ safeNumber(summary.today_steps) }}</strong>
            </div>

            <div class="flex justify-between border-b border-slate-100 pb-3">
              <span class="text-slate-500">Calories</span>
              <strong class="text-slate-900">{{ safeNumber(summary.today_calories) }}</strong>
            </div>

            <div class="flex justify-between border-b border-slate-100 pb-3">
              <span class="text-slate-500">Water Intake</span>
              <strong class="text-slate-900">{{ safeNumber(summary.water_intake_ml) }} ml</strong>
            </div>

            <div class="flex justify-between">
              <span class="text-slate-500">Current Weight</span>
              <strong class="text-slate-900">{{ safeNumber(summary.current_weight_kg) }} kg</strong>
            </div>
          </div>
        </div>

        <!-- Projects -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold text-slate-900">
              Projects
            </h2>
            <span class="rounded-full bg-indigo-100 px-3 py-1 text-xs font-semibold text-indigo-700">
              Active Work
            </span>
          </div>

          <div class="mt-6 space-y-4">
            <div class="flex justify-between border-b border-slate-100 pb-3">
              <span class="text-slate-500">Total Projects</span>
              <strong class="text-slate-900">{{ safeNumber(summary.total_projects) }}</strong>
            </div>

            <div class="flex justify-between border-b border-slate-100 pb-3">
              <span class="text-slate-500">Active Projects</span>
              <strong class="text-slate-900">{{ safeNumber(summary.active_projects) }}</strong>
            </div>

            <div class="rounded-xl bg-slate-50 p-4">
              <p class="text-sm text-slate-500">
                Project completion overview
              </p>

              <div class="mt-3 h-3 overflow-hidden rounded-full bg-slate-200">
                <div
                  class="h-full rounded-full bg-slate-900"
                  :style="{ width: projectProgress + '%' }"
                ></div>
              </div>

              <p class="mt-2 text-sm font-semibold text-slate-700">
                {{ projectProgress }}% active ratio
              </p>
            </div>
          </div>
        </div>

        <!-- Life Balance -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold text-slate-900">
              Life Balance
            </h2>
            <span class="rounded-full bg-blue-100 px-3 py-1 text-xs font-semibold text-blue-700">
              Overview
            </span>
          </div>

          <div class="mt-6">
            <div class="rounded-2xl bg-slate-900 p-6 text-white">
              <p class="text-sm text-slate-300">
                Overall Balance Score
              </p>

              <h3 class="mt-3 text-4xl font-bold">
                {{ lifeBalanceScore }}%
              </h3>

              <p class="mt-2 text-sm text-slate-300">
                Based on finance, health, and project activity.
              </p>
            </div>

            <div class="mt-4 h-3 overflow-hidden rounded-full bg-slate-200">
              <div
                class="h-full rounded-full bg-blue-600"
                :style="{ width: lifeBalanceScore + '%' }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-slate-900">
              Recent Activity
            </h2>
            <p class="mt-1 text-sm text-slate-500">
              Latest actions across Nix Life OS.
            </p>
          </div>

          <button
            class="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            @click="loadDashboard"
          >
            Refresh
          </button>
        </div>

        <div v-if="recentActivity.length" class="mt-6 space-y-3">
          <div
            v-for="(activity, index) in recentActivity"
            :key="index"
            class="rounded-xl border border-slate-100 bg-slate-50 p-4"
          >
            <p class="font-semibold text-slate-800">
              {{ activity.title || activity.message || 'Activity' }}
            </p>

            <p class="mt-1 text-sm text-slate-500">
              {{ activity.description || activity.created_at || 'No additional details.' }}
            </p>
          </div>
        </div>

        <div v-else class="mt-6 rounded-xl bg-slate-50 p-6 text-center text-slate-500">
          No recent activity available.
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';

const loading = ref(false);
const error = ref('');
const summary = ref({
  total_balance: 0,
  income: 0,
  monthly_expense: 0,
  savings_rate: 0,
  today_steps: 0,
  today_calories: 0,
  water_intake_ml: 0,
  current_weight_kg: 0,
  active_projects: 0,
  total_projects: 0,
});

const recentActivity = ref([]);

const apiBaseUrl =
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1';

function getToken() {
  return (
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('nix_token') ||
    ''
  );
}

function safeNumber(value) {
  const numberValue = Number(value);

  if (Number.isNaN(numberValue) || value === null || value === undefined) {
    return 0;
  }

  return numberValue;
}

function formatCurrency(value) {
  const numberValue = safeNumber(value);

  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 2,
  }).format(numberValue);
}

const projectProgress = computed(() => {
  const total = safeNumber(summary.value.total_projects);
  const active = safeNumber(summary.value.active_projects);

  if (total <= 0) {
    return 0;
  }

  return Math.min(100, Math.round((active / total) * 100));
});

const lifeBalanceScore = computed(() => {
  const savingsRate = Math.min(100, safeNumber(summary.value.savings_rate));
  const stepsScore = Math.min(100, Math.round((safeNumber(summary.value.today_steps) / 8000) * 100));
  const waterScore = Math.min(100, Math.round((safeNumber(summary.value.water_intake_ml) / 2000) * 100));
  const projectScore = projectProgress.value;

  const score = Math.round((savingsRate + stepsScore + waterScore + projectScore) / 4);

  if (Number.isNaN(score)) {
    return 0;
  }

  return score;
});

async function apiGet(path) {
  const token = getToken();

  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      Authorization: token ? `Bearer ${token}` : '',
    },
  });

  if (response.status === 401) {
    throw new Error('Unauthorized. Please login again.');
  }

  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}.`);
  }

  return response.json();
}

async function loadDashboard() {
  loading.value = true;
  error.value = '';

  try {
    const summaryResponse = await apiGet('/dashboard/summary');

    summary.value = {
      ...summary.value,
      ...(summaryResponse.data || {}),
    };

    try {
      const activityResponse = await apiGet('/dashboard/recent-activity');
      recentActivity.value = activityResponse.data || [];
    } catch {
      recentActivity.value = [];
    }
  } catch (err) {
    error.value = err.message || 'Unable to load dashboard summary.';
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadDashboard();
});
</script>
