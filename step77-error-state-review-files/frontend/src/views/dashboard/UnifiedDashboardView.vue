<template>
  <div class="p-6 space-y-8">
    <!-- Header -->
     <AIRecommendationWidget />
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-slate-500 uppercase tracking-wide">
          NIX LIFE OS
        </p>
        <h1 class="text-4xl font-bold text-slate-950">
          Unified Dashboard
        </h1>
        <p class="text-slate-500 mt-2 max-w-2xl">
          Your finance, health, projects, and daily activity in one operating view.
        </p>
      </div>

      <button
        @click="loadDashboard"
        :disabled="loading"
        class="bg-slate-950 text-white px-6 py-4 rounded-2xl font-semibold hover:bg-slate-800 disabled:opacity-60"
      >
        {{ loading ? "Refreshing..." : "Refresh Dashboard" }}
      </button>
    </div>

    <!-- Error -->
    <div
      v-if="error"
      class="bg-red-50 border border-red-200 text-red-700 rounded-2xl p-4 font-medium"
    >
      {{ error }}
    </div>

    <!-- KPI Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
      <KpiCard
        title="Total Balance"
        :value="formatMoney(dashboard.total_balance)"
        :subtitle="`Income: ${formatMoney(dashboard.income)}`"
        icon="💰"
      />

      <KpiCard
        title="Today Steps"
        :value="formatNumber(dashboard.today_steps)"
        subtitle="Daily movement progress"
        icon="👟"
      />

      <KpiCard
        title="Today Calories"
        :value="formatNumber(dashboard.today_calories)"
        subtitle="Calories logged today"
        icon="🔥"
      />

      <KpiCard
        title="Active Projects"
        :value="formatNumber(dashboard.active_projects)"
        :subtitle="`${formatNumber(dashboard.total_projects)} total projects`"
        icon="📌"
      />

      <KpiCard
        title="Monthly Expense"
        :value="formatMoney(dashboard.monthly_expense)"
        subtitle="Current month spending"
        icon="💸"
      />

      <KpiCard
        title="Savings Rate"
        :value="`${formatNumber(dashboard.savings_rate)}%`"
        subtitle="Pay-yourself performance"
        icon="🏦"
      />

      <KpiCard
        title="Water Intake"
        :value="`${formatNumber(dashboard.water_intake_ml)} ml`"
        subtitle="Today hydration"
        icon="💧"
      />

      <KpiCard
        title="Current Weight"
        :value="`${formatNumber(dashboard.current_weight_kg)} kg`"
        subtitle="Latest health record"
        icon="⚖️"
      />
    </div>

    <!-- Recent Activity -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 p-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-bold text-slate-900">Recent Activity</h2>
        <span class="text-sm text-slate-500">{{ recentActivity.length }} items</span>
      </div>

      <div v-if="recentActivity.length === 0" class="text-slate-500">
        No recent activity found.
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="item in recentActivity"
          :key="item.id || item.title || item.created_at"
          class="border border-slate-100 rounded-xl p-4"
        >
          <p class="font-semibold text-slate-900">
            {{ item.title || item.message || item.description || "Activity" }}
          </p>
          <p class="text-sm text-slate-500">
            {{ item.created_at || item.date || "" }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import AIRecommendationWidget from '@/components/ai/AIRecommendationWidget.vue'
import { computed, defineComponent, h, onMounted, ref } from "vue";
import {
  getUnifiedDashboardSummary,
  getUnifiedDashboardKpis,
  getUnifiedDashboardActivity,
} from "@/services/dashboardApi";

const loading = ref(false);
const error = ref("");

const dashboardRaw = ref({});
const kpisRaw = ref({});
const recentActivity = ref([]);

const defaultDashboard = {
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
};

const dashboard = computed(() => ({
  ...defaultDashboard,
  ...(dashboardRaw.value || {}),
  ...(kpisRaw.value || {}),
}));

function normalizePayload(response) {
  if (!response) return {};
  if (response.data && !Array.isArray(response.data)) return response.data;
  return response;
}

function normalizeActivity(response) {
  if (!response) return [];
  if (Array.isArray(response.data)) return response.data;
  if (Array.isArray(response.data?.data)) return response.data.data;
  if (Array.isArray(response.activities)) return response.activities;
  return [];
}

function formatMoney(value) {
  const number = Number(value || 0);
  return `$${number.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

function formatNumber(value) {
  const number = Number(value || 0);
  return number.toLocaleString();
}

async function loadDashboard() {
  loading.value = true;
  error.value = "";

  try {
    const [summaryResponse, kpisResponse, activityResponse] = await Promise.all([
      getUnifiedDashboardSummary(),
      getUnifiedDashboardKpis().catch(() => ({ data: {} })),
      getUnifiedDashboardActivity().catch(() => ({ data: [] })),
    ]);

    dashboardRaw.value = normalizePayload(summaryResponse);
    kpisRaw.value = normalizePayload(kpisResponse);
    recentActivity.value = normalizeActivity(activityResponse);
  } catch (err) {
    error.value = err.message || "Unable to load dashboard data. Please check backend API and token.";
    dashboardRaw.value = {};
    kpisRaw.value = {};
    recentActivity.value = [];
  } finally {
    loading.value = false;
  }
}

const KpiCard = defineComponent({
  name: "KpiCard",
  props: {
    title: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number],
      required: true,
    },
    subtitle: {
      type: String,
      default: "",
    },
    icon: {
      type: String,
      default: "📊",
    },
  },
  setup(props) {
    return () =>
      h(
        "div",
        {
          class:
            "bg-white rounded-2xl shadow-sm border border-slate-100 p-6 flex items-start justify-between gap-4",
        },
        [
          h("div", {}, [
            h("p", { class: "text-slate-500 font-semibold" }, props.title),
            h("p", { class: "text-3xl font-bold text-slate-950 mt-4" }, props.value),
            h("p", { class: "text-slate-500 mt-2" }, props.subtitle),
          ]),
          h(
            "div",
            {
              class:
                "w-16 h-16 rounded-2xl bg-slate-100 flex items-center justify-center text-2xl",
            },
            props.icon
          ),
        ]
      );
  },
});

onMounted(loadDashboard);
</script>