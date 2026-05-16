<template>
  <div class="p-6 space-y-8">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <p class="text-sm font-semibold text-slate-500 uppercase tracking-wide">
          NIX LIFE OS
        </p>
        <h1 class="text-4xl font-bold text-slate-950">
          Life Balance
        </h1>
        <p class="text-slate-500 mt-2 max-w-2xl">
          A unified score combining finance, health, projects, productivity, and daily lifestyle signals.
        </p>
      </div>

      <button
        @click="loadLifeBalance"
        :disabled="loading"
        class="bg-slate-950 text-white px-6 py-4 rounded-2xl font-semibold hover:bg-slate-800 disabled:opacity-60"
      >
        {{ loading ? "Refreshing..." : "Refresh Score" }}
      </button>
    </div>

    <div
      v-if="error"
      class="bg-red-50 border border-red-200 text-red-700 rounded-2xl p-4 font-medium"
    >
      {{ error }}
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 lg:col-span-1">
        <p class="text-slate-500 font-semibold">Overall Life Balance Score</p>

        <div class="mt-6 flex items-center justify-center">
          <div class="relative w-52 h-52 rounded-full border-[18px] border-slate-100 flex items-center justify-center">
            <div
              class="absolute inset-[-18px] rounded-full"
              :style="scoreRingStyle"
            ></div>

            <div class="relative bg-white w-40 h-40 rounded-full flex flex-col items-center justify-center shadow-inner">
              <p class="text-5xl font-bold text-slate-950">
                {{ score }}
              </p>
              <p class="text-sm text-slate-500">/ 100</p>
            </div>
          </div>
        </div>

        <p class="text-center mt-6 font-semibold" :class="scoreLabelClass">
          {{ scoreLabel }}
        </p>
      </div>

      <div class="bg-white rounded-2xl shadow-sm border border-slate-100 p-6 lg:col-span-2">
        <h2 class="text-xl font-bold text-slate-900 mb-6">
          Balance Breakdown
        </h2>

        <div class="space-y-5">
          <ScoreBar label="Finance" :value="balance.finance_score" icon="💰" />
          <ScoreBar label="Health" :value="balance.health_score" icon="🩺" />
          <ScoreBar label="Projects" :value="balance.projects_score" icon="📌" />
          <ScoreBar label="Productivity" :value="balance.productivity_score" icon="⚡" />
          <ScoreBar label="Consistency" :value="balance.consistency_score" icon="🔁" />
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <KpiCard
        title="Finance Health"
        :value="`${formatNumber(balance.finance_score)}%`"
        subtitle="Balance, spending, and savings"
        icon="💸"
      />

      <KpiCard
        title="Health Health"
        :value="`${formatNumber(balance.health_score)}%`"
        subtitle="Weight, hydration, meals, and activity"
        icon="❤️"
      />

      <KpiCard
        title="Project Progress"
        :value="`${formatNumber(balance.projects_score)}%`"
        subtitle="Active project completion"
        icon="🚀"
      />

      <KpiCard
        title="Daily Consistency"
        :value="`${formatNumber(balance.consistency_score)}%`"
        subtitle="Routine and tracking consistency"
        icon="📈"
      />
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 p-6">
      <h2 class="text-xl font-bold text-slate-900 mb-4">
        Recommendations
      </h2>

      <div v-if="recommendations.length === 0" class="text-slate-500">
        No recommendations available yet.
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="item in recommendations"
          :key="item"
          class="border border-slate-100 rounded-xl p-4 text-slate-700"
        >
          {{ item }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from "vue";
import { apiRequest } from "../../../services/api";

const loading = ref(false);
const error = ref("");

const defaultBalance = {
  overall_score: 0,
  finance_score: 0,
  health_score: 0,
  projects_score: 0,
  productivity_score: 0,
  consistency_score: 0,
};

const balanceRaw = ref({});
const recommendations = ref([]);

const balance = computed(() => ({
  ...defaultBalance,
  ...(balanceRaw.value || {}),
}));

const score = computed(() => Math.round(Number(balance.value.overall_score || 0)));

const scoreLabel = computed(() => {
  if (score.value >= 80) return "Excellent Balance";
  if (score.value >= 65) return "Good Balance";
  if (score.value >= 50) return "Needs Attention";
  return "Critical Balance";
});

const scoreLabelClass = computed(() => {
  if (score.value >= 80) return "text-green-600";
  if (score.value >= 65) return "text-blue-600";
  if (score.value >= 50) return "text-yellow-600";
  return "text-red-600";
});

const scoreRingStyle = computed(() => {
  const value = Math.min(Math.max(score.value, 0), 100);

  return {
    background: `conic-gradient(#0f172a ${value * 3.6}deg, transparent 0deg)`,
  };
});

function normalizePayload(response) {
  if (!response) return {};

  const data = response.data || response;

  if (data.score && typeof data.score === "object") return data.score;
  if (data.life_balance && typeof data.life_balance === "object") return data.life_balance;
  if (data.balance && typeof data.balance === "object") return data.balance;

  return data;
}

function normalizeRecommendations(response) {
  const data = response?.data || response || {};

  if (Array.isArray(data.recommendations)) return data.recommendations;
  if (Array.isArray(data.insights)) return data.insights;
  if (Array.isArray(data.tips)) return data.tips;

  return [];
}

function formatNumber(value) {
  return Math.round(Number(value || 0)).toLocaleString();
}

async function loadLifeBalance() {
  loading.value = true;
  error.value = "";

  try {
    let response;

    try {
      response = await apiRequest("/life-balance/summary");
    } catch {
      response = await apiRequest("/life-balance");
    }

    balanceRaw.value = normalizePayload(response);
    recommendations.value = normalizeRecommendations(response);

    if (!balanceRaw.value.overall_score && balanceRaw.value.score) {
      balanceRaw.value.overall_score = balanceRaw.value.score;
    }
  } catch (err) {
    error.value =
      err.message ||
      "Unable to load life balance data. Please check backend API and token.";

    balanceRaw.value = {};
    recommendations.value = [];
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

const ScoreBar = defineComponent({
  name: "ScoreBar",
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number],
      required: true,
    },
    icon: {
      type: String,
      default: "📊",
    },
  },
  setup(props) {
    return () => {
      const value = Math.min(Math.max(Number(props.value || 0), 0), 100);

      return h("div", {}, [
        h("div", { class: "flex justify-between items-center mb-2" }, [
          h("div", { class: "font-semibold text-slate-700" }, `${props.icon} ${props.label}`),
          h("div", { class: "font-bold text-slate-900" }, `${Math.round(value)}%`),
        ]),
        h("div", { class: "h-3 bg-slate-100 rounded-full overflow-hidden" }, [
          h("div", {
            class: "h-3 bg-slate-950 rounded-full",
            style: { width: `${value}%` },
          }),
        ]),
      ]);
    };
  },
});

onMounted(loadLifeBalance);
</script>