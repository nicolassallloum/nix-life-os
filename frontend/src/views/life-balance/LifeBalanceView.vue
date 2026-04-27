<script setup>
import { onMounted, ref, computed } from "vue";
import { Radar } from "vue-chartjs";
import {
  Chart as ChartJS,
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler,
  Tooltip,
  Legend,
} from "chart.js";

ChartJS.register(
  RadialLinearScale,
  PointElement,
  LineElement,
  Filler,
  Tooltip,
  Legend
);

const loading = ref(false);
const error = ref("");
const score = ref(null);

const token = localStorage.getItem("token");

const fetchLifeBalance = async () => {
  loading.value = true;
  error.value = "";

  try {
    const response = await fetch(
      "http://127.0.0.1:8000/api/v1/life-balance/today",
      {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      }
    );

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.message || "Failed to load Life Balance score");
    }

    score.value = result.data;
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
};

const radarData = computed(() => {
  if (!score.value) {
    return {
      labels: ["Finance", "Health", "Productivity"],
      datasets: [],
    };
  }

  return {
    labels: ["Finance", "Health", "Productivity"],
    datasets: [
      {
        label: "Life Balance Score",
        data: [
          score.value.finance_score,
          score.value.health_score,
          score.value.productivity_score,
        ],
        fill: true,
      },
    ],
  };
});

const radarOptions = {
  responsive: true,
  maintainAspectRatio: false,
  scales: {
    r: {
      suggestedMin: 0,
      suggestedMax: 100,
      ticks: {
        stepSize: 20,
      },
    },
  },
};

const statusClass = computed(() => {
  if (!score.value) return "bg-gray-100 text-gray-700";

  switch (score.value.status) {
    case "excellent":
      return "bg-green-100 text-green-700";
    case "balanced":
      return "bg-blue-100 text-blue-700";
    case "needs_attention":
      return "bg-yellow-100 text-yellow-700";
    case "critical":
      return "bg-red-100 text-red-700";
    default:
      return "bg-gray-100 text-gray-700";
  }
});

const statusLabel = computed(() => {
  if (!score.value) return "Unknown";

  return score.value.status
    .replace("_", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
});

onMounted(fetchLifeBalance);
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-8">
    <div class="max-w-7xl mx-auto space-y-8">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">
            Life Balance Index
          </h1>
          <p class="text-gray-500 mt-1">
            Combined score from Finance, Health, and Productivity.
          </p>
        </div>

        <button
          @click="fetchLifeBalance"
          class="px-5 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-800"
        >
          Refresh
        </button>
      </div>

      <div
        v-if="loading"
        class="bg-white rounded-2xl shadow-sm border p-8 text-gray-500"
      >
        Loading Life Balance score...
      </div>

      <div
        v-if="error"
        class="bg-red-50 border border-red-200 text-red-700 rounded-2xl p-5"
      >
        {{ error }}
      </div>

      <template v-if="score && !loading">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <p class="text-sm text-gray-500">Overall Score</p>
            <h2 class="text-4xl font-bold text-gray-900 mt-2">
              {{ score.overall_score }}
            </h2>
            <span
              class="inline-flex mt-4 px-3 py-1 rounded-full text-sm font-medium"
              :class="statusClass"
            >
              {{ statusLabel }}
            </span>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <p class="text-sm text-gray-500">Finance</p>
            <h2 class="text-4xl font-bold text-gray-900 mt-2">
              {{ score.finance_score }}
            </h2>
            <p class="text-sm text-gray-500 mt-3">
              Income, expenses, and cashflow.
            </p>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <p class="text-sm text-gray-500">Health</p>
            <h2 class="text-4xl font-bold text-gray-900 mt-2">
              {{ score.health_score }}
            </h2>
            <p class="text-sm text-gray-500 mt-3">
              Steps, hydration, and nutrition.
            </p>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <p class="text-sm text-gray-500">Productivity</p>
            <h2 class="text-4xl font-bold text-gray-900 mt-2">
              {{ score.productivity_score }}
            </h2>
            <p class="text-sm text-gray-500 mt-3">
              Tasks and project focus.
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <h3 class="text-xl font-semibold text-gray-900 mb-4">
              Life Balance Radar
            </h3>

            <div class="h-[420px]">
              <Radar :data="radarData" :options="radarOptions" />
            </div>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <h3 class="text-xl font-semibold text-gray-900 mb-4">
              Recommendations
            </h3>

            <div
              v-if="score.recommendations && score.recommendations.length"
              class="space-y-4"
            >
              <div
                v-for="(item, index) in score.recommendations"
                :key="index"
                class="border rounded-xl p-4"
              >
                <div class="flex items-center justify-between">
                  <h4 class="font-semibold text-gray-900">
                    {{ item.module }}
                  </h4>

                  <span class="text-xs px-2 py-1 rounded-full bg-gray-100 text-gray-600">
                    {{ item.priority }}
                  </span>
                </div>

                <p class="text-gray-600 mt-2">
                  {{ item.message }}
                </p>
              </div>
            </div>

            <div v-else class="text-gray-500">
              No recommendations available.
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <h3 class="font-semibold text-gray-900 mb-4">
              Finance Breakdown
            </h3>

            <div class="space-y-3 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-500">Income</span>
                <span class="font-medium">
                  {{ score.finance_breakdown?.income ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Expenses</span>
                <span class="font-medium">
                  {{ score.finance_breakdown?.expenses ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Net Cashflow</span>
                <span class="font-medium">
                  {{ score.finance_breakdown?.net_cashflow ?? 0 }}
                </span>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <h3 class="font-semibold text-gray-900 mb-4">
              Health Breakdown
            </h3>

            <div class="space-y-3 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-500">Steps</span>
                <span class="font-medium">
                  {{ score.health_breakdown?.steps ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Water ML</span>
                <span class="font-medium">
                  {{ score.health_breakdown?.water_ml ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Calories</span>
                <span class="font-medium">
                  {{ score.health_breakdown?.calories ?? 0 }}
                </span>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-2xl shadow-sm border p-6">
            <h3 class="font-semibold text-gray-900 mb-4">
              Productivity Breakdown
            </h3>

            <div class="space-y-3 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-500">Total Tasks</span>
                <span class="font-medium">
                  {{ score.productivity_breakdown?.total_tasks ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Completed Tasks</span>
                <span class="font-medium">
                  {{ score.productivity_breakdown?.completed_tasks ?? 0 }}
                </span>
              </div>

              <div class="flex justify-between">
                <span class="text-gray-500">Active Projects</span>
                <span class="font-medium">
                  {{ score.productivity_breakdown?.active_projects ?? 0 }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
