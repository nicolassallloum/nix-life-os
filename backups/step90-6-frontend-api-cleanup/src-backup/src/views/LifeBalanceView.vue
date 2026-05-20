<template>
  <div class="min-h-screen bg-gray-50 px-6 py-6">
    <!-- Page Header -->
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900">
        Life Balance
      </h1>
      <p class="mt-1 text-sm text-gray-500">
        Your combined balance across finance, health, projects, productivity, and consistency.
      </p>
    </div>

    <!-- Loading State -->
    <div
      v-if="loading"
      class="rounded-2xl border border-gray-200 bg-white p-8 shadow-sm"
    >
      <div class="animate-pulse space-y-4">
        <div class="h-6 w-48 rounded bg-gray-200"></div>
        <div class="h-24 rounded bg-gray-200"></div>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div class="h-28 rounded bg-gray-200"></div>
          <div class="h-28 rounded bg-gray-200"></div>
          <div class="h-28 rounded bg-gray-200"></div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div
      v-else-if="errorMessage"
      class="rounded-2xl border border-red-200 bg-red-50 p-6 shadow-sm"
    >
      <h2 class="text-lg font-semibold text-red-700">
        Life Balance could not be loaded
      </h2>

      <p class="mt-2 text-sm text-red-600">
        {{ errorMessage }}
      </p>

      <button
        class="mt-4 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
        @click="loadLifeBalance"
      >
        Retry
      </button>
    </div>

    <!-- Main Content -->
    <div v-else>
      <!-- Overall Score -->
      <div class="mb-6 rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
        <div class="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-wide text-gray-500">
              Overall Life Balance Score
            </p>

            <div class="mt-3 flex items-end gap-3">
              <span class="text-6xl font-bold text-gray-900">
                {{ safeScore(summary.overall_score) }}
              </span>
              <span class="mb-2 text-xl font-semibold text-gray-400">
                / 100
              </span>
            </div>

            <p class="mt-3 text-sm text-gray-500">
              {{ overallStatusMessage }}
            </p>
          </div>

          <!-- Circular Progress -->
          <div class="flex justify-center lg:justify-end">
            <div
              class="relative flex h-36 w-36 items-center justify-center rounded-full"
              :style="overallCircleStyle"
            >
              <div class="flex h-28 w-28 flex-col items-center justify-center rounded-full bg-white shadow-inner">
                <span class="text-3xl font-bold text-gray-900">
                  {{ safeScore(summary.overall_score) }}
                </span>
                <span class="text-xs text-gray-500">
                  Score
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Score Cards -->
      <div class="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-5">
        <ScoreCard
          title="Finance"
          :score="safeScore(summary.finance_score)"
          description="Financial stability"
        />

        <ScoreCard
          title="Health"
          :score="safeScore(summary.health_score)"
          description="Health tracking"
        />

        <ScoreCard
          title="Projects"
          :score="safeScore(summary.projects_score)"
          description="Project progress"
        />

        <ScoreCard
          title="Productivity"
          :score="safeScore(summary.productivity_score)"
          description="Daily output"
        />

        <ScoreCard
          title="Consistency"
          :score="safeScore(summary.consistency_score)"
          description="Habit rhythm"
        />
      </div>

      <!-- Balance Breakdown -->
      <div class="mb-6 grid grid-cols-1 gap-6 xl:grid-cols-2">
        <!-- Score Bars -->
        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-bold text-gray-900">
            Balance Breakdown
          </h2>

          <p class="mt-1 text-sm text-gray-500">
            A detailed score view for each life area.
          </p>

          <div class="mt-6 space-y-5">
            <ScoreBar
              label="Finance"
              :score="safeScore(summary.finance_score)"
            />

            <ScoreBar
              label="Health"
              :score="safeScore(summary.health_score)"
            />

            <ScoreBar
              label="Projects"
              :score="safeScore(summary.projects_score)"
            />

            <ScoreBar
              label="Productivity"
              :score="safeScore(summary.productivity_score)"
            />

            <ScoreBar
              label="Consistency"
              :score="safeScore(summary.consistency_score)"
            />
          </div>
        </div>

        <!-- Radar Alternative / Visual Score Panel -->
        <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-bold text-gray-900">
            Life Balance Radar
          </h2>

          <p class="mt-1 text-sm text-gray-500">
            Simple visual radar-style summary without external chart dependency.
          </p>

          <div class="mt-6 flex items-center justify-center">
            <div class="relative h-72 w-72 rounded-full border border-gray-200 bg-gray-50">
              <div class="absolute inset-8 rounded-full border border-gray-200"></div>
              <div class="absolute inset-16 rounded-full border border-gray-200"></div>
              <div class="absolute inset-24 rounded-full border border-gray-200"></div>

              <RadarPoint
                label="Finance"
                :score="safeScore(summary.finance_score)"
                position="top"
              />

              <RadarPoint
                label="Health"
                :score="safeScore(summary.health_score)"
                position="right"
              />

              <RadarPoint
                label="Projects"
                :score="safeScore(summary.projects_score)"
                position="bottom-right"
              />

              <RadarPoint
                label="Productivity"
                :score="safeScore(summary.productivity_score)"
                position="bottom-left"
              />

              <RadarPoint
                label="Consistency"
                :score="safeScore(summary.consistency_score)"
                position="left"
              />

              <div class="absolute left-1/2 top-1/2 flex h-20 w-20 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-gray-900 text-white shadow-lg">
                <div class="text-center">
                  <div class="text-xl font-bold">
                    {{ safeScore(summary.overall_score) }}
                  </div>
                  <div class="text-[10px] uppercase tracking-wide">
                    Overall
                  </div>
                </div>
              </div>
            </div>
          </div>

          <p class="mt-4 text-center text-xs text-gray-500">
            This panel is safe even when chart libraries are not installed.
          </p>
        </div>
      </div>

      <!-- Recommendations -->
      <div class="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-bold text-gray-900">
              Recommendations
            </h2>
            <p class="mt-1 text-sm text-gray-500">
              Smart suggestions based on your current life balance.
            </p>
          </div>

          <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-semibold text-gray-600">
            {{ recommendations.length }} items
          </span>
        </div>

        <div v-if="recommendations.length" class="mt-5 space-y-3">
          <div
            v-for="(recommendation, index) in recommendations"
            :key="index"
            class="rounded-xl border border-gray-100 bg-gray-50 p-4"
          >
            <div class="flex gap-3">
              <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gray-900 text-sm font-bold text-white">
                {{ index + 1 }}
              </div>

              <p class="text-sm font-medium text-gray-700">
                {{ recommendation }}
              </p>
            </div>
          </div>
        </div>

        <div
          v-else
          class="mt-5 rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center"
        >
          <p class="text-sm font-medium text-gray-600">
            No recommendations available yet.
          </p>
          <p class="mt-1 text-xs text-gray-400">
            Add more finance, health, project, and productivity data to generate better insights.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  computed,
  defineComponent,
  h,
  onMounted,
  ref,
} from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "/api/v1";

const loading = ref(false);
const errorMessage = ref("");

const summary = ref({
  overall_score: 0,
  finance_score: 0,
  health_score: 0,
  projects_score: 0,
  productivity_score: 0,
  consistency_score: 0,
  recommendations: [],
});

const recommendations = computed(() => {
  if (!Array.isArray(summary.value.recommendations)) {
    return [];
  }

  return summary.value.recommendations.filter(Boolean);
});

const overallStatusMessage = computed(() => {
  const score = safeScore(summary.value.overall_score);

  if (score >= 85) {
    return "Excellent balance. Your main life areas are performing very well.";
  }

  if (score >= 70) {
    return "Good balance. Keep improving the lower-scoring areas.";
  }

  if (score >= 50) {
    return "Moderate balance. Focus on consistency and weaker areas.";
  }

  if (score > 0) {
    return "Low balance. Start with small improvements across each area.";
  }

  return "No balance data available yet.";
});

const overallCircleStyle = computed(() => {
  const score = safeScore(summary.value.overall_score);

  return {
    background: `conic-gradient(#111827 ${score * 3.6}deg, #e5e7eb 0deg)`,
  };
});

function safeScore(value) {
  const numberValue = Number(value);

  if (Number.isNaN(numberValue) || numberValue < 0) {
    return 0;
  }

  if (numberValue > 100) {
    return 100;
  }

  return Math.round(numberValue);
}

function getAuthToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("access_token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("nix_token") ||
    ""
  );
}

async function loadLifeBalance() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const token = getAuthToken();

    const response = await fetch(`${API_BASE_URL}/life-balance/summary`, {
      method: "GET",
      headers: {
        Accept: "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });

    const result = await response.json().catch(() => null);

    if (response.status === 401) {
      throw new Error("Unauthenticated. Please login again.");
    }

    if (response.status === 403) {
      throw new Error("You do not have permission to view Life Balance data.");
    }

    if (response.status === 404) {
      throw new Error("API route not found: /life-balance/summary.");
    }

    if (!response.ok) {
      throw new Error(
        result?.message || `Request failed with status ${response.status}.`
      );
    }

    const data = result?.data || {};

    summary.value = {
      overall_score: safeScore(data.overall_score),
      finance_score: safeScore(data.finance_score),
      health_score: safeScore(data.health_score),
      projects_score: safeScore(data.projects_score),
      productivity_score: safeScore(data.productivity_score),
      consistency_score: safeScore(data.consistency_score),
      recommendations: Array.isArray(data.recommendations)
        ? data.recommendations
        : [],
    };
  } catch (error) {
    errorMessage.value =
      error?.message || "Unexpected error while loading Life Balance data.";

    summary.value = {
      overall_score: 0,
      finance_score: 0,
      health_score: 0,
      projects_score: 0,
      productivity_score: 0,
      consistency_score: 0,
      recommendations: [],
    };
  } finally {
    loading.value = false;
  }
}

const ScoreCard = defineComponent({
  name: "ScoreCard",
  props: {
    title: {
      type: String,
      required: true,
    },
    score: {
      type: Number,
      required: true,
    },
    description: {
      type: String,
      default: "",
    },
  },
  setup(props) {
    return () =>
      h(
        "div",
        {
          class:
            "rounded-2xl border border-gray-200 bg-white p-5 shadow-sm transition hover:shadow-md",
        },
        [
          h("p", { class: "text-sm font-semibold text-gray-500" }, props.title),
          h("div", { class: "mt-3 flex items-end gap-1" }, [
            h(
              "span",
              { class: "text-4xl font-bold text-gray-900" },
              String(props.score)
            ),
            h("span", { class: "mb-1 text-sm font-semibold text-gray-400" }, "/100"),
          ]),
          h("p", { class: "mt-2 text-xs text-gray-500" }, props.description),
          h("div", { class: "mt-4 h-2 rounded-full bg-gray-100" }, [
            h("div", {
              class: "h-2 rounded-full bg-gray-900",
              style: {
                width: `${props.score}%`,
              },
            }),
          ]),
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
    score: {
      type: Number,
      required: true,
    },
  },
  setup(props) {
    return () =>
      h("div", {}, [
        h("div", { class: "mb-2 flex items-center justify-between" }, [
          h("span", { class: "text-sm font-semibold text-gray-700" }, props.label),
          h("span", { class: "text-sm font-bold text-gray-900" }, `${props.score}%`),
        ]),
        h("div", { class: "h-3 rounded-full bg-gray-100" }, [
          h("div", {
            class: "h-3 rounded-full bg-gray-900",
            style: {
              width: `${props.score}%`,
            },
          }),
        ]),
      ]);
  },
});

const RadarPoint = defineComponent({
  name: "RadarPoint",
  props: {
    label: {
      type: String,
      required: true,
    },
    score: {
      type: Number,
      required: true,
    },
    position: {
      type: String,
      required: true,
    },
  },
  setup(props) {
    const positionClassMap = {
      top: "left-1/2 top-4 -translate-x-1/2",
      right: "right-2 top-1/2 -translate-y-1/2",
      "bottom-right": "bottom-8 right-8",
      "bottom-left": "bottom-8 left-8",
      left: "left-2 top-1/2 -translate-y-1/2",
    };

    return () =>
      h(
        "div",
        {
          class: `absolute ${positionClassMap[props.position] || ""}`,
        },
        [
          h(
            "div",
            {
              class:
                "flex h-16 w-16 flex-col items-center justify-center rounded-full border border-gray-200 bg-white text-center shadow-sm",
            },
            [
              h("span", { class: "text-sm font-bold text-gray-900" }, String(props.score)),
              h("span", { class: "text-[10px] font-medium text-gray-500" }, props.label),
            ]
          ),
        ]
      );
  },
});

onMounted(() => {
  loadLifeBalance();
});
</script>