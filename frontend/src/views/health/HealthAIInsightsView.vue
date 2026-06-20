<template>
  <section class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div>
        <p class="text-sm font-semibold uppercase tracking-wide text-emerald-600">
          Health / AI Insights
        </p>
        <h1 class="mt-1 text-2xl font-bold text-gray-900">
          Health AI Insights
        </h1>
        <p class="mt-1 max-w-3xl text-sm text-gray-500">
          AI-assisted health observations for nutrition, hydration, weight, steps, medications, lab trends, and kidney-friendly recommendations.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-60"
        :disabled="loading"
        @click="loadInsights"
      >
        {{ loading ? "Refreshing..." : "Refresh Insights" }}
      </button>
    </div>

    <div class="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
      <strong>Medical safety note:</strong>
      These insights are for tracking and awareness only. They are not a diagnosis and should not replace your doctor or renal dietitian’s advice.
    </div>

    <div v-if="loading" class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
      <p class="text-sm font-medium text-gray-700">Loading Health AI insights...</p>
      <div class="mt-4 grid gap-4 md:grid-cols-4">
        <div v-for="item in 4" :key="item" class="h-24 animate-pulse rounded-2xl bg-gray-100" />
      </div>
      <div class="mt-4 space-y-3">
        <div v-for="item in 3" :key="`card-${item}`" class="h-32 animate-pulse rounded-2xl bg-gray-100" />
      </div>
    </div>

    <div v-else-if="error" class="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
      <h2 class="text-lg font-bold">Unable to load Health AI Insights</h2>
      <p class="mt-2 text-sm">{{ error }}</p>
      <button
        type="button"
        class="mt-4 rounded-xl bg-red-700 px-4 py-2 text-sm font-semibold text-white hover:bg-red-800"
        @click="loadInsights"
      >
        Try Again
      </button>
    </div>

    <div v-else class="space-y-6">
      <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <SummaryCard title="Total Insights" :value="summary.total_insights" note="Generated observations" icon="🧠" />
        <SummaryCard title="Critical Warnings" :value="summary.critical_warnings" note="Needs attention" icon="⚠️" />
        <SummaryCard title="Warnings" :value="summary.warnings" note="Monitor closely" icon="🟠" />
        <SummaryCard title="Health Data" :value="summary.has_health_data ? 'Available' : 'Empty'" note="Source data status" icon="🩺" />
      </div>

      <div v-if="!summary.has_health_data" class="rounded-2xl border border-dashed border-gray-300 bg-white p-8 text-center shadow-sm">
        <div class="text-4xl">📋</div>
        <h2 class="mt-3 text-lg font-bold text-gray-900">
          {{ emptyState.title || "No health data yet" }}
        </h2>
        <p class="mx-auto mt-2 max-w-2xl text-sm text-gray-500">
          {{ emptyState.message || "Start tracking nutrition, hydration, weight, steps, medications, or lab results to receive Health AI insights." }}
        </p>
      </div>

      <div v-else-if="insights.length === 0" class="rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
        <div class="text-4xl">✅</div>
        <h2 class="mt-3 text-lg font-bold text-gray-900">No warnings detected</h2>
        <p class="mt-2 text-sm text-gray-500">
          Your available health data did not generate any warnings at this time.
        </p>
      </div>

      <div v-else class="grid gap-4 xl:grid-cols-2">
        <article
          v-for="insight in insights"
          :key="`${insight.type}-${insight.title}-${insight.created_at}`"
          class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm"
        >
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <span :class="severityClass(insight.severity)">
                  {{ normalizeSeverity(insight.severity) }}
                </span>
                <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-gray-600">
                  {{ formatType(insight.type) }}
                </span>
              </div>

              <h2 class="mt-3 text-lg font-bold text-gray-900">
                {{ insight.title }}
              </h2>
            </div>

            <span class="rounded-2xl bg-gray-100 px-3 py-2 text-xl">
              {{ sourceIcon(insight.source) }}
            </span>
          </div>

          <p class="mt-4 text-sm leading-6 text-gray-600">
            {{ insight.message }}
          </p>

          <div class="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
            <p class="text-xs font-bold uppercase tracking-wide text-emerald-700">
              Recommendation
            </p>
            <p class="mt-1 text-sm leading-6 text-emerald-900">
              {{ insight.recommendation }}
            </p>
          </div>

          <div class="mt-4 flex flex-wrap items-center gap-2 text-xs text-gray-500">
            <span>Source: {{ formatType(insight.source) }}</span>
            <span v-if="insight.created_at">•</span>
            <span v-if="insight.created_at">Generated: {{ formatDate(insight.created_at) }}</span>
          </div>

          <div v-if="hasMetrics(insight.metrics)" class="mt-4 grid gap-2 sm:grid-cols-2">
            <div
              v-for="(value, key) in insight.metrics"
              :key="key"
              class="rounded-xl bg-gray-50 px-3 py-2 text-xs"
            >
              <span class="font-semibold text-gray-500">{{ formatType(key) }}:</span>
              <span class="ml-1 text-gray-800">{{ value ?? 'N/A' }}</span>
            </div>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from "vue";
import healthService from "@/services/healthService";

const loading = ref(false);
const error = ref("");
const payload = ref({
  summary: {},
  insights: [],
  empty_state: null,
});

const summary = computed(() => ({
  total_insights: payload.value?.summary?.total_insights ?? 0,
  critical_warnings: payload.value?.summary?.critical_warnings ?? 0,
  warnings: payload.value?.summary?.warnings ?? 0,
  recommendations: payload.value?.summary?.recommendations ?? 0,
  has_health_data: Boolean(payload.value?.summary?.has_health_data),
}));

const insights = computed(() => Array.isArray(payload.value?.insights) ? payload.value.insights : []);
const emptyState = computed(() => payload.value?.empty_state || {});

async function loadInsights() {
  loading.value = true;
  error.value = "";

  try {
    const response = await healthService.aiInsights();
    const data = response.data?.data || response.data || {};

    payload.value = {
      summary: data.summary || {},
      insights: Array.isArray(data.insights) ? data.insights : [],
      empty_state: data.empty_state || null,
    };
  } catch (err) {
    error.value = err.response?.data?.message || err.message || "Failed to load Health AI insights.";
  } finally {
    loading.value = false;
  }
}

function normalizeSeverity(severity) {
  return String(severity || "info").toUpperCase();
}

function severityClass(severity) {
  const base = "rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide";
  const value = String(severity || "info").toLowerCase();

  if (["critical", "danger"].includes(value)) {
    return `${base} bg-red-100 text-red-700`;
  }

  if (value === "warning") {
    return `${base} bg-amber-100 text-amber-700`;
  }

  if (value === "success") {
    return `${base} bg-emerald-100 text-emerald-700`;
  }

  return `${base} bg-blue-100 text-blue-700`;
}

function formatType(value) {
  return String(value || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatDate(value) {
  if (!value) return "";
  return new Date(value).toLocaleString();
}

function sourceIcon(source) {
  const icons = {
    nutrition: "🥗",
    hydration: "💧",
    weight: "⚖️",
    steps: "🚶",
    medications: "💊",
    labs: "🧪",
    kidney_health: "🩺",
  };

  return icons[source] || "🧠";
}

function hasMetrics(metrics) {
  return metrics && typeof metrics === "object" && Object.keys(metrics).length > 0;
}

const SummaryCard = defineComponent({
  name: "SummaryCard",
  props: {
    title: { type: String, required: true },
    value: { type: [String, Number], required: true },
    note: { type: String, required: true },
    icon: { type: String, required: true },
  },
  setup(props) {
    return () => h("div", { class: "rounded-2xl border border-gray-200 bg-white p-5 shadow-sm" }, [
      h("div", { class: "flex items-start justify-between gap-4" }, [
        h("div", {}, [
          h("p", { class: "text-sm font-medium text-gray-500" }, props.title),
          h("p", { class: "mt-2 text-2xl font-bold text-gray-900" }, String(props.value)),
          h("p", { class: "mt-1 text-xs text-gray-500" }, props.note),
        ]),
        h("div", { class: "rounded-2xl bg-gray-100 px-3 py-2 text-xl" }, props.icon),
      ]),
    ]);
  },
});

onMounted(() => {
  loadInsights();
});
</script>
