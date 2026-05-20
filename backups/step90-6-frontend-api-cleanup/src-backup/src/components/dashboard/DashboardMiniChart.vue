<script setup>
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  LineElement,
  BarElement,
  CategoryScale,
  LinearScale,
  PointElement,
  ArcElement,
} from "chart.js";

import { Line, Bar, Doughnut } from "vue-chartjs";
import { computed } from "vue";

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  LineElement,
  BarElement,
  CategoryScale,
  LinearScale,
  PointElement,
  ArcElement
);

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    default: "line",
  },
  labels: {
    type: Array,
    default: () => [],
  },
  values: {
    type: Array,
    default: () => [],
  },
});

const chartData = computed(() => ({
  labels: props.labels,
  datasets: [
    {
      label: props.title,
      data: props.values,
      borderWidth: 2,
      tension: 0.4,
      fill: false,
    },
  ],
}));

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false,
    },
  },
  scales: {
    y: {
      beginAtZero: true,
    },
  },
};
</script>

<template>
  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
    <div class="mb-4">
      <h3 class="text-lg font-bold text-gray-900">
        {{ title }}
      </h3>
    </div>

    <div class="h-64">
      <Line
        v-if="type === 'line'"
        :data="chartData"
        :options="chartOptions"
      />

      <Bar
        v-else-if="type === 'bar'"
        :data="chartData"
        :options="chartOptions"
      />

      <Doughnut
        v-else
        :data="chartData"
        :options="{
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom',
            },
          },
        }"
      />
    </div>
  </div>
</template>