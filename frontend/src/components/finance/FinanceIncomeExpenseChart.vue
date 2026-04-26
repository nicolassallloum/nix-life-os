<script setup>
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from "chart.js";

import { Bar } from "vue-chartjs";

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
);

const chartData = {
  labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
  datasets: [
    {
      label: "Income",
      data: [2200, 2400, 2600, 2800, 3000, 3200],
      backgroundColor: "#10b981",
      borderRadius: 8,
    },
    {
      label: "Expenses",
      data: [1400, 1550, 1600, 1650, 1700, 1800],
      backgroundColor: "#ef4444",
      borderRadius: 8,
    },
  ],
};

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: "bottom",
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
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 h-[420px]">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-900">
        Income vs Expenses
      </h2>
      <p class="text-sm text-slate-500 mt-1">
        Monthly comparison between money earned and money spent.
      </p>
    </div>

    <div class="h-[320px]">
      <Bar :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>