<template>
  <div class="space-y-6 p-4">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Health</h1>
      <p class="text-sm text-gray-500">Track steps, weight, water, sleep, mood, and medication.</p>
    </div>

    <div class="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-6">
      <button class="health-btn" @click="openModal('steps')">
        Add Steps
      </button>

      <button class="health-btn" @click="openModal('weight')">
        Add Weight
      </button>

      <button class="health-btn" @click="openModal('water')">
        Add Water
      </button>

      <button class="health-btn" @click="openModal('sleep')">
        Add Sleep
      </button>

      <button class="health-btn" @click="openModal('mood')">
        Add Mood
      </button>

      <button class="health-btn" @click="openModal('medication')">
        Add Medication
      </button>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="dashboard-card">
        <p class="card-label">Today Steps</p>
        <h3 class="card-value">{{ dashboard.todaySteps }}</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Today Water</p>
        <h3 class="card-value">{{ dashboard.todayWater }} ml</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Current Weight</p>
        <h3 class="card-value">{{ dashboard.currentWeight }} kg</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Last Sleep</p>
        <h3 class="card-value">{{ dashboard.lastSleep }} h</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Today Mood</p>
        <h3 class="card-value capitalize">{{ dashboard.todayMood }}</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Active Medications</p>
        <h3 class="card-value">{{ dashboard.activeMedications }}</h3>
      </div>
    </div>

    <HealthQuickActionModal
      :show="showModal"
      :type="modalType"
      @close="showModal = false"
      @saved="refreshDashboard"
    />
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import HealthQuickActionModal from '@/components/health/HealthQuickActionModal.vue'

const showModal = ref(false)
const modalType = ref<'steps' | 'weight' | 'water' | 'sleep' | 'mood' | 'medication'>('steps')

const dashboard = reactive({
  todaySteps: 0,
  todayWater: 0,
  currentWeight: 0,
  lastSleep: 0,
  todayMood: '-',
  activeMedications: 0,
})

function openModal(type: typeof modalType.value) {
  modalType.value = type
  showModal.value = true
}

async function refreshDashboard() {
  /**
   * Later you can replace this with:
   * GET /api/v1/health/dashboard-summary
   */
  console.log('Health dashboard refreshed')
}
</script>

<style scoped>
.health-btn {
  border-radius: 1rem;
  background: white;
  padding: 1rem;
  font-weight: 700;
  color: #111827;
  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08);
  border: 1px solid #e5e7eb;
}

.health-btn:hover {
  background: #f9fafb;
}

.dashboard-card {
  border-radius: 1rem;
  background: white;
  padding: 1.25rem;
  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08);
}

.card-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.card-value {
  margin-top: 0.25rem;
  font-size: 1.5rem;
  font-weight: 800;
  color: #111827;
}
</style>
