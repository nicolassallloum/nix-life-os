<template>
  <div class="space-y-6 p-4">
    <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Health</h1>
        <p class="text-sm text-gray-500">
          Track steps, weight, water, sleep, mood, medication, and daily health goals.
        </p>
      </div>

      <button class="refresh-btn" :disabled="loading" @click="refreshDashboard">
        {{ loading ? 'Loading...' : 'Refresh' }}
      </button>
    </div>

    <div v-if="errorMessage" class="error-box">
      {{ errorMessage }}
    </div>

    <div class="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-6">
      <button class="health-btn" @click="openModal('steps')">Add Steps</button>
      <button class="health-btn" @click="openModal('weight')">Add Weight</button>
      <button class="health-btn" @click="openModal('water')">Add Water</button>
      <button class="health-btn" @click="openModal('sleep')">Add Sleep</button>
      <button class="health-btn" @click="openModal('mood')">Add Mood</button>
      <button class="health-btn" @click="openModal('medication')">Add Medication</button>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="dashboard-card">
        <p class="card-label">Today Steps</p>
        <h3 class="card-value">{{ formatNumber(dashboard.todaySteps) }}</h3>
        <ProgressBar :percent="dashboard.progress.stepsPercent" />
        <p class="goal-text">Goal: {{ formatNumber(dashboard.goals.dailyStepsGoal) }} steps</p>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Today Water</p>
        <h3 class="card-value">{{ formatNumber(dashboard.todayWater) }} ml</h3>
        <ProgressBar :percent="dashboard.progress.waterPercent" />
        <p class="goal-text">Goal: {{ formatNumber(dashboard.goals.dailyWaterGoalMl) }} ml</p>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Today Calories</p>
        <h3 class="card-value">{{ formatNumber(dashboard.todayCalories) }} kcal</h3>
        <ProgressBar :percent="dashboard.progress.caloriesPercent" />
        <p class="goal-text">Goal: {{ formatNumber(dashboard.goals.dailyCaloriesGoal) }} kcal</p>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Current Weight</p>
        <h3 class="card-value">{{ dashboard.currentWeight }} kg</h3>
        <p class="goal-text">
          Target: {{ dashboard.goals.targetWeightKg ? `${dashboard.goals.targetWeightKg} kg` : '-' }}
        </p>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Last Sleep</p>
        <h3 class="card-value">{{ dashboard.lastSleep }} h</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Active Medications</p>
        <h3 class="card-value">{{ dashboard.activeMedications }}</h3>
        <p class="goal-text">Mood: {{ dashboard.todayMood }}</p>
      </div>
    </div>

    <div class="dashboard-card">
      <div class="mb-4 flex items-center justify-between">
        <div>
          <p class="card-label">Nutrition Limits Today</p>
          <h3 class="text-lg font-bold text-gray-900">Kidney-Friendly Tracking</h3>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
        <div class="limit-card">
          <p class="card-label">Protein</p>
          <h4 class="limit-value">{{ dashboard.todayProteinG }} g</h4>
          <ProgressBar :percent="dashboard.progress.proteinPercent" />
          <p class="goal-text">Limit: {{ displayLimit(dashboard.goals.proteinLimitG, 'g') }}</p>
        </div>

        <div class="limit-card">
          <p class="card-label">Sodium</p>
          <h4 class="limit-value">{{ dashboard.todaySodiumMg }} mg</h4>
          <ProgressBar :percent="dashboard.progress.sodiumPercent" />
          <p class="goal-text">Limit: {{ displayLimit(dashboard.goals.sodiumLimitMg, 'mg') }}</p>
        </div>

        <div class="limit-card">
          <p class="card-label">Potassium</p>
          <h4 class="limit-value">{{ dashboard.todayPotassiumMg }} mg</h4>
          <ProgressBar :percent="dashboard.progress.potassiumPercent" />
          <p class="goal-text">Limit: {{ displayLimit(dashboard.goals.potassiumLimitMg, 'mg') }}</p>
        </div>

        <div class="limit-card">
          <p class="card-label">Phosphorus</p>
          <h4 class="limit-value">{{ dashboard.todayPhosphorusMg }} mg</h4>
          <ProgressBar :percent="dashboard.progress.phosphorusPercent" />
          <p class="goal-text">Limit: {{ displayLimit(dashboard.goals.phosphorusLimitMg, 'mg') }}</p>
        </div>
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
import { defineComponent, h, onMounted, reactive, ref } from 'vue'
import HealthQuickActionModal from '@/components/health/HealthQuickActionModal.vue'
import { healthService } from '@/services/healthService'

const showModal = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const modalType = ref<'steps' | 'weight' | 'water' | 'sleep' | 'mood' | 'medication'>('steps')

const dashboard = reactive({
  todaySteps: 0,
  todayWater: 0,
  todayCalories: 0,
  todayProteinG: 0,
  todaySodiumMg: 0,
  todayPotassiumMg: 0,
  todayPhosphorusMg: 0,
  currentWeight: 0,
  lastSleep: 0,
  todayMood: '-',
  activeMedications: 0,
  goals: {
    dailyStepsGoal: 8000,
    targetWeightKg: null as number | null,
    dailyCaloriesGoal: 1800,
    dailyWaterGoalMl: 2000,
    proteinLimitG: null as number | null,
    sodiumLimitMg: null as number | null,
    potassiumLimitMg: null as number | null,
    phosphorusLimitMg: null as number | null,
  },
  progress: {
    stepsPercent: 0,
    waterPercent: 0,
    caloriesPercent: 0,
    proteinPercent: 0,
    sodiumPercent: 0,
    potassiumPercent: 0,
    phosphorusPercent: 0,
  },
})

const ProgressBar = defineComponent({
  props: {
    percent: {
      type: Number,
      default: 0,
    },
  },
  setup(props) {
    return () =>
      h('div', { class: 'progress-track' }, [
        h('div', {
          class: 'progress-fill',
          style: { width: `${Math.min(100, Math.max(0, Number(props.percent || 0)))}%` },
        }),
      ])
  },
})

function openModal(type: typeof modalType.value) {
  modalType.value = type
  showModal.value = true
}

function toNumber(value: unknown, fallback = 0): number {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : fallback
}

function formatNumber(value: unknown): string {
  return Math.round(toNumber(value)).toLocaleString()
}

function displayLimit(value: number | null, unit: string): string {
  return value ? `${formatNumber(value)} ${unit}` : '-'
}

async function refreshDashboard() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await healthService.dashboard()
    const data = response?.data?.data ?? response?.data ?? {}
    const goals = data.goals ?? {}
    const progress = data.progress ?? {}

    dashboard.todaySteps = toNumber(data.today_steps)
    dashboard.todayWater = toNumber(data.today_water_ml)
    dashboard.todayCalories = toNumber(data.today_calories)
    dashboard.todayProteinG = toNumber(data.today_protein_g)
    dashboard.todaySodiumMg = toNumber(data.today_sodium_mg)
    dashboard.todayPotassiumMg = toNumber(data.today_potassium_mg)
    dashboard.todayPhosphorusMg = toNumber(data.today_phosphorus_mg)
    dashboard.currentWeight = toNumber(data.current_weight_kg)
    dashboard.lastSleep = toNumber(data.last_sleep_hours)
    dashboard.todayMood = data.today_mood ?? '-'
    dashboard.activeMedications = toNumber(data.active_medications)

    dashboard.goals.dailyStepsGoal = toNumber(goals.daily_steps_goal, 8000)
    dashboard.goals.targetWeightKg = goals.target_weight_kg !== null && goals.target_weight_kg !== undefined
      ? toNumber(goals.target_weight_kg)
      : null
    dashboard.goals.dailyCaloriesGoal = toNumber(goals.daily_calories_goal, 1800)
    dashboard.goals.dailyWaterGoalMl = toNumber(goals.daily_water_goal_ml, 2000)
    dashboard.goals.proteinLimitG = goals.protein_limit_g !== null && goals.protein_limit_g !== undefined
      ? toNumber(goals.protein_limit_g)
      : null
    dashboard.goals.sodiumLimitMg = goals.sodium_limit_mg !== null && goals.sodium_limit_mg !== undefined
      ? toNumber(goals.sodium_limit_mg)
      : null
    dashboard.goals.potassiumLimitMg = goals.potassium_limit_mg !== null && goals.potassium_limit_mg !== undefined
      ? toNumber(goals.potassium_limit_mg)
      : null
    dashboard.goals.phosphorusLimitMg = goals.phosphorus_limit_mg !== null && goals.phosphorus_limit_mg !== undefined
      ? toNumber(goals.phosphorus_limit_mg)
      : null

    dashboard.progress.stepsPercent = toNumber(progress.steps_percent)
    dashboard.progress.waterPercent = toNumber(progress.water_percent)
    dashboard.progress.caloriesPercent = toNumber(progress.calories_percent)
    dashboard.progress.proteinPercent = toNumber(progress.protein_percent)
    dashboard.progress.sodiumPercent = toNumber(progress.sodium_percent)
    dashboard.progress.potassiumPercent = toNumber(progress.potassium_percent)
    dashboard.progress.phosphorusPercent = toNumber(progress.phosphorus_percent)
  } catch (error) {
    console.error('Failed to load health dashboard', error)
    errorMessage.value = 'Failed to load health dashboard data.'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  refreshDashboard()
})
</script>

<style scoped>
.health-btn,
.refresh-btn {
  border-radius: 1rem;
  background: white;
  padding: 1rem;
  font-weight: 700;
  color: #111827;
  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08);
  border: 1px solid #e5e7eb;
}

.refresh-btn {
  padding: 0.75rem 1rem;
}

.health-btn:hover,
.refresh-btn:hover {
  background: #f9fafb;
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.dashboard-card {
  border-radius: 1rem;
  background: white;
  padding: 1.25rem;
  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08);
}

.limit-card {
  border-radius: 0.875rem;
  background: #f9fafb;
  padding: 1rem;
  border: 1px solid #e5e7eb;
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

.limit-value {
  margin-top: 0.25rem;
  font-size: 1.25rem;
  font-weight: 800;
  color: #111827;
}

.goal-text {
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #6b7280;
}

.progress-track {
  margin-top: 0.75rem;
  height: 0.5rem;
  width: 100%;
  overflow: hidden;
  border-radius: 9999px;
  background: #e5e7eb;
}

.progress-fill {
  height: 100%;
  border-radius: 9999px;
  background: #111827;
  transition: width 0.25s ease;
}

.error-box {
  border-radius: 0.75rem;
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #991b1b;
  padding: 0.875rem 1rem;
  font-size: 0.875rem;
}
</style>
