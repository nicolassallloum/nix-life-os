<script setup>
import { onMounted, ref, computed } from "vue";

import DashboardStatCard from "@/components/dashboard/DashboardStatCard.vue";
import DashboardProgressCard from "@/components/dashboard/DashboardProgressCard.vue";
import DashboardRecentActivity from "@/components/dashboard/DashboardRecentActivity.vue";
import DashboardMiniChart from "@/components/dashboard/DashboardMiniChart.vue";

import {
  getUnifiedDashboardSummary,
  getUnifiedDashboardKpis,
  getUnifiedDashboardActivity,
} from "@/services/dashboardApi";

const loading = ref(true);
const errorMessage = ref("");

const summary = ref({
  finance: {
    total_balance: 0,
    monthly_income: 0,
    monthly_expense: 0,
    savings_rate: 0,
  },
  health: {
    today_steps: 0,
    today_calories: 0,
    today_water_ml: 0,
    weight_kg: 0,
  },
  projects: {
    total_projects: 0,
    active_projects: 0,
    completed_projects: 0,
    average_progress: 0,
  },
});

const kpis = ref({
  finance_chart: {
    labels: [],
    values: [],
  },
  steps_chart: {
    labels: [],
    values: [],
  },
  calories_chart: {
    labels: [],
    values: [],
  },
  projects_chart: {
    labels: [],
    values: [],
  },
});

const activities = ref([]);

const formattedBalance = computed(() => {
  const value = Number(summary.value.finance?.total_balance || 0);

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(value);
});

const formattedIncome = computed(() => {
  const value = Number(summary.value.finance?.monthly_income || 0);

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(value);
});

const formattedExpense = computed(() => {
  const value = Number(summary.value.finance?.monthly_expense || 0);

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(value);
});

async function loadDashboard() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const [summaryResponse, kpisResponse, activityResponse] = await Promise.all([
      getUnifiedDashboardSummary(),
      getUnifiedDashboardKpis(),
      getUnifiedDashboardActivity(),
    ]);

    summary.value = summaryResponse.data || summaryResponse;
    kpis.value = kpisResponse.data || kpisResponse;
    activities.value = activityResponse.data || activityResponse || [];
  } catch (error) {
    console.error(error);

    errorMessage.value =
      error.response?.data?.message ||
      "Unable to load dashboard data. Please check backend API and token.";
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadDashboard();
});
</script>

<template>
  <main class="min-h-screen bg-gray-50 p-6">
    <div class="mx-auto max-w-7xl space-y-6">
      <!-- Header -->
      <section class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <p class="text-sm font-semibold uppercase tracking-wide text-gray-500">
            NIX LIFE OS
          </p>

          <h1 class="mt-1 text-3xl font-bold tracking-tight text-gray-950">
            Unified Dashboard
          </h1>

          <p class="mt-2 text-gray-500">
            Your finance, health, projects, and daily activity in one operating view.
          </p>
        </div>

        <button
          @click="loadDashboard"
          class="rounded-xl bg-gray-900 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-gray-800"
        >
          Refresh Dashboard
        </button>
      </section>

      <!-- Error -->
      <section
        v-if="errorMessage"
        class="rounded-2xl border border-red-100 bg-red-50 p-4 text-sm font-medium text-red-700"
      >
        {{ errorMessage }}
      </section>

      <!-- Loading -->
      <section
        v-if="loading"
        class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4"
      >
        <div
          v-for="item in 4"
          :key="item"
          class="h-32 animate-pulse rounded-2xl bg-white shadow-sm"
        ></div>
      </section>

      <template v-else>
        <!-- Main Cards -->
        <section class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">
          <DashboardStatCard
            title="Total Balance"
            :value="formattedBalance"
            :subtitle="`Income: ${formattedIncome}`"
            icon="💰"
            tone="green"
          />

          <DashboardStatCard
            title="Today Steps"
            :value="summary.health.today_steps || 0"
            subtitle="Daily movement progress"
            icon="👟"
            tone="blue"
          />

          <DashboardStatCard
            title="Today Calories"
            :value="summary.health.today_calories || 0"
            subtitle="Calories logged today"
            icon="🔥"
            tone="orange"
          />

          <DashboardStatCard
            title="Active Projects"
            :value="summary.projects.active_projects || 0"
            :subtitle="`${summary.projects.total_projects || 0} total projects`"
            icon="📌"
            tone="purple"
          />
        </section>

        <!-- Secondary KPI Cards -->
        <section class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">
          <DashboardStatCard
            title="Monthly Expense"
            :value="formattedExpense"
            subtitle="Current month spending"
            icon="💸"
            tone="red"
          />

          <DashboardStatCard
            title="Savings Rate"
            :value="`${summary.finance.savings_rate || 0}%`"
            subtitle="Pay-yourself performance"
            icon="🏦"
            tone="green"
          />

          <DashboardStatCard
            title="Water Intake"
            :value="`${summary.health.today_water_ml || 0} ml`"
            subtitle="Today hydration"
            icon="💧"
            tone="blue"
          />

          <DashboardStatCard
            title="Current Weight"
            :value="`${summary.health.weight_kg || 0} kg`"
            subtitle="Latest health record"
            icon="⚖️"
            tone="purple"
          />
        </section>

        <!-- Progress Section -->
        <section class="grid grid-cols-1 gap-5 lg:grid-cols-3">
          <DashboardProgressCard
            title="Average Project Progress"
            :value="summary.projects.average_progress || 0"
            subtitle="Across all active projects"
          />

          <DashboardProgressCard
            title="Completed Projects"
            :value="
              summary.projects.total_projects
                ? Math.round((summary.projects.completed_projects / summary.projects.total_projects) * 100)
                : 0
            "
            :subtitle="`${summary.projects.completed_projects || 0} completed projects`"
          />

          <DashboardProgressCard
            title="Finance Savings Goal"
            :value="summary.finance.savings_rate || 0"
            subtitle="Monthly saving performance"
          />
        </section>

        <!-- Charts -->
        <section class="grid grid-cols-1 gap-5 xl:grid-cols-2">
          <DashboardMiniChart
            title="Finance Trend"
            type="line"
            :labels="kpis.finance_chart.labels"
            :values="kpis.finance_chart.values"
          />

          <DashboardMiniChart
            title="Steps Trend"
            type="bar"
            :labels="kpis.steps_chart.labels"
            :values="kpis.steps_chart.values"
          />

          <DashboardMiniChart
            title="Calories Trend"
            type="line"
            :labels="kpis.calories_chart.labels"
            :values="kpis.calories_chart.values"
          />

          <DashboardMiniChart
            title="Project Progress"
            type="bar"
            :labels="kpis.projects_chart.labels"
            :values="kpis.projects_chart.values"
          />
        </section>

        <!-- Recent Activity -->
        <section class="grid grid-cols-1 gap-5 xl:grid-cols-3">
          <div class="xl:col-span-2">
            <DashboardRecentActivity :activities="activities" />
          </div>

          <div class="rounded-2xl border border-gray-100 bg-gray-900 p-6 text-white shadow-sm">
            <p class="text-sm font-semibold uppercase tracking-wide text-gray-400">
              AI Insight
            </p>

            <h3 class="mt-3 text-2xl font-bold">
              Your operating system is active.
            </h3>

            <p class="mt-3 text-sm leading-6 text-gray-300">
              Finance, health, and project data are now connected into one unified
              decision dashboard. The next step can add AI recommendations,
              alerts, and smart daily planning.
            </p>

            <div class="mt-6 rounded-xl bg-white/10 p-4">
              <p class="text-sm text-gray-300">
                Suggested next module:
              </p>

              <p class="mt-1 font-semibold">
                STEP 18 — AI Insights Engine
              </p>
            </div>
          </div>
        </section>
      </template>
    </div>
  </main>
</template>