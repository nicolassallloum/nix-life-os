<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "http://127.0.0.1:8000/api/v1";
const token = localStorage.getItem("token");

const selectedDate = ref(new Date().toISOString().substring(0, 10));
const summary = ref(null);
const warnings = ref([]);

async function loadSummary() {
  const response = await fetch(
    `${API_BASE}/health/nutrition/summary/daily?date=${selectedDate.value}`,
    {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  summary.value = data.summary;
  warnings.value = data.warnings || [];
}

onMounted(loadSummary);
</script>

<template>
  <div>
    <div class="mb-8 flex items-center justify-between">
      <div>
        <h2 class="text-3xl font-bold text-gray-900">Nutrition Dashboard</h2>
        <p class="text-gray-500 mt-1">
          Daily CKD-safe nutrient monitoring
        </p>
      </div>

      <input
        v-model="selectedDate"
        @change="loadSummary"
        type="date"
        class="rounded-xl border border-gray-300 px-4 py-2"
      />
    </div>

    <div v-if="summary" class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Calories</p>
        <h3 class="text-3xl font-bold">{{ summary.calories }}</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Protein</p>
        <h3 class="text-3xl font-bold">{{ summary.protein_g }}g</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Sodium</p>
        <h3 class="text-3xl font-bold">{{ summary.sodium_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Potassium</p>
        <h3 class="text-3xl font-bold">{{ summary.potassium_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Phosphorus</p>
        <h3 class="text-3xl font-bold">{{ summary.phosphorus_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Carbs</p>
        <h3 class="text-3xl font-bold">{{ summary.carbs_g }}g</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Fat</p>
        <h3 class="text-3xl font-bold">{{ summary.fat_g }}g</h3>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow p-6">
      <h3 class="text-xl font-bold mb-4">CKD Safety Warnings</h3>

      <div v-if="warnings.length === 0" class="text-green-700 bg-green-50 p-4 rounded-xl">
        No nutrient limits exceeded for this day.
      </div>

      <div
        v-for="warning in warnings"
        :key="warning.nutrient"
        class="mb-3 rounded-xl p-4"
        :class="warning.status === 'exceeded' ? 'bg-red-50 text-red-700' : 'bg-yellow-50 text-yellow-700'"
      >
        <strong>{{ warning.label }}:</strong>
        {{ warning.message }}
        <span>({{ warning.percentage }}%)</span>
      </div>
    </div>
  </div>
</template>