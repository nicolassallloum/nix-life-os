<template>
  <section class="ai-widget">
    <div class="widget-header">
      <div>
        <p class="eyebrow">AI Engine</p>
        <h2>AI Recommendations</h2>
        <p class="subtitle">
          Latest smart insights from your life balance, health, finance, productivity, goals, and habits.
        </p>
      </div>

      <RouterLink to="/ai/recommendations" class="open-link">
        Open AI Center
      </RouterLink>
    </div>

    <div v-if="loading" class="state-card">
      Loading AI insights...
    </div>

    <div v-else-if="errorMessage" class="error-card">
      {{ errorMessage }}
    </div>

    <div v-else>
      <div class="score-row">
        <div class="score-card main">
          <span>Life Balance</span>
          <strong>{{ latestScore?.life_balance_score ?? '—' }}</strong>
          <small :class="['classification', latestScore?.classification || 'neutral']">
            {{ formatLabel(latestScore?.classification || 'No Score') }}
          </small>
        </div>

        <div class="score-card">
          <span>Finance</span>
          <strong>{{ latestScore?.finance_score ?? '—' }}</strong>
        </div>

        <div class="score-card">
          <span>Health</span>
          <strong>{{ latestScore?.health_score ?? '—' }}</strong>
        </div>

        <div class="score-card">
          <span>Productivity</span>
          <strong>{{ latestScore?.productivity_score ?? '—' }}</strong>
        </div>
      </div>

      <div class="summary-row">
        <div>
          <span>Total</span>
          <strong>{{ recommendationSummary.total || 0 }}</strong>
        </div>

        <div>
          <span>Pending</span>
          <strong>{{ recommendationSummary.pending || 0 }}</strong>
        </div>

        <div>
          <span>Accepted</span>
          <strong>{{ recommendationSummary.accepted || 0 }}</strong>
        </div>

        <div>
          <span>Completed</span>
          <strong>{{ recommendationSummary.completed || 0 }}</strong>
        </div>
      </div>

      <div v-if="topRecommendation" class="top-recommendation">
        <div class="badges">
          <span :class="['badge', topRecommendation.severity]">
            {{ formatLabel(topRecommendation.severity) }}
          </span>

          <span class="badge neutral">
            {{ formatLabel(topRecommendation.module) }}
          </span>

          <span :class="['badge', topRecommendation.status]">
            {{ formatLabel(topRecommendation.status) }}
          </span>
        </div>

        <h3>{{ topRecommendation.title }}</h3>
        <p>{{ topRecommendation.message }}</p>

        <div v-if="topRecommendation.action_text" class="action-box">
          {{ topRecommendation.action_text }}
        </div>
      </div>

      <div v-else class="empty-card">
        No active AI recommendations yet.
      </div>

      <div class="actions">
        <button class="btn secondary" :disabled="refreshing" @click="refreshScores">
          {{ refreshing ? 'Refreshing...' : 'Refresh Scores' }}
        </button>

        <button class="btn primary" :disabled="generating" @click="generateRecommendations">
          {{ generating ? 'Generating...' : 'Generate AI Recommendations' }}
        </button>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import aiRecommendationService from '@/services/aiRecommendationService'

const loading = ref(false)
const refreshing = ref(false)
const generating = ref(false)
const errorMessage = ref('')

const scores = ref([])
const recommendations = ref([])
const recommendationSummary = ref({})

const latestScore = computed(() => scores.value?.[0] || null)

const topRecommendation = computed(() => {
  return recommendations.value?.[0] || null
})

onMounted(async () => {
  await loadWidgetData()
})

async function loadWidgetData() {
  loading.value = true
  errorMessage.value = ''

  try {
    await Promise.all([
      loadScores(false),
      loadRecommendations(),
    ])
  } catch (error) {
    handleError(error, 'Failed to load AI dashboard widget.')
  } finally {
    loading.value = false
  }
}

async function loadScores(generateToday = false) {
  const response = await aiRecommendationService.getDailyScores({
    generate_today: generateToday,
    limit: 1,
  })

  scores.value = response.data?.scores || []
}

async function loadRecommendations() {
  const response = await aiRecommendationService.getRecommendations({
    active_only: true,
    limit: 5,
  })

  recommendations.value = response.data?.recommendations || []
  recommendationSummary.value = response.data?.summary || {}
}

async function refreshScores() {
  refreshing.value = true
  errorMessage.value = ''

  try {
    await loadScores(true)
  } catch (error) {
    handleError(error, 'Failed to refresh AI scores.')
  } finally {
    refreshing.value = false
  }
}

async function generateRecommendations() {
  generating.value = true
  errorMessage.value = ''

  try {
    await aiRecommendationService.generateRecommendations({
      store_daily_score: true,
    })

    await Promise.all([
      loadScores(false),
      loadRecommendations(),
    ])
  } catch (error) {
    handleError(error, 'Failed to generate AI recommendations.')
  } finally {
    generating.value = false
  }
}

function handleError(error, fallbackMessage) {
  console.error(error)

  errorMessage.value =
    error?.response?.data?.message ||
    error?.message ||
    fallbackMessage ||
    'Something went wrong.'
}

function formatLabel(value) {
  if (!value) return 'N/A'

  return String(value)
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}
</script>

<style scoped>
.ai-widget {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 24px;
  padding: 24px;
  box-shadow: 0 16px 32px rgba(15, 23, 42, 0.06);
  margin-bottom: 24px;
}

.widget-header {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  align-items: flex-start;
  margin-bottom: 20px;
}

.eyebrow {
  margin: 0 0 6px;
  color: #6366f1;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

h2 {
  margin: 0;
  color: #111827;
  font-size: 26px;
  font-weight: 900;
}

.subtitle {
  margin: 8px 0 0;
  color: #6b7280;
  line-height: 1.6;
}

.open-link {
  background: #eef2ff;
  color: #3730a3;
  text-decoration: none;
  font-weight: 800;
  padding: 10px 14px;
  border-radius: 14px;
  white-space: nowrap;
}

.score-row {
  display: grid;
  grid-template-columns: 1.4fr repeat(3, 1fr);
  gap: 14px;
  margin-bottom: 16px;
}

.score-card {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 18px;
}

.score-card span {
  display: block;
  color: #6b7280;
  font-weight: 800;
  margin-bottom: 8px;
}

.score-card strong {
  display: block;
  color: #111827;
  font-size: 32px;
  font-weight: 500;
}

.classification {
  display: inline-flex;
  margin-top: 10px;
  padding: 5px 10px;
  border-radius: 999px;
  font-weight: 900;
  font-size: 12px;
}

.classification.good,
.classification.excellent {
  background: #dcfce7;
  color: #166534;
}

.classification.needs_attention {
  background: #fef3c7;
  color: #92400e;
}

.classification.risk,
.classification.critical {
  background: #fee2e2;
  color: #991b1b;
}

.classification.neutral {
  background: #f3f4f6;
  color: #374151;
}

.summary-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin-bottom: 16px;
}

.summary-row div {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 14px;
}

.summary-row span {
  display: block;
  color: #6b7280;
  font-size: 13px;
  font-weight: 800;
}

.summary-row strong {
  display: block;
  margin-top: 4px;
  color: #111827;
  font-size: 24px;
}

.top-recommendation {
  background: #f8fafc;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 18px;
}

.badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 10px;
}

.badge {
  display: inline-flex;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 900;
}

.badge.critical,
.badge.high {
  background: #fee2e2;
  color: #991b1b;
}

.badge.medium {
  background: #fef3c7;
  color: #92400e;
}

.badge.low {
  background: #e0f2fe;
  color: #075985;
}

.badge.pending,
.badge.viewed {
  background: #eef2ff;
  color: #3730a3;
}

.badge.accepted,
.badge.completed,
.badge.positive {
  background: #dcfce7;
  color: #166534;
}

.badge.dismissed,
.badge.expired {
  background: #fee2e2;
  color: #991b1b;
}

.badge.neutral,
.badge.info {
  background: #f3f4f6;
  color: #374151;
}

.top-recommendation h3 {
  margin: 0 0 8px;
  color: #111827;
  font-size: 20px;
}

.top-recommendation p {
  color: #4b5563;
  line-height: 1.6;
}

.action-box {
  background: #ffffff;
  border-left: 4px solid #4f46e5;
  border-radius: 12px;
  padding: 12px;
  color: #374151;
  font-weight: 700;
}

.actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 18px;
}

.btn {
  border: 0;
  border-radius: 14px;
  padding: 11px 15px;
  font-weight: 900;
  cursor: pointer;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn.primary {
  background: #4f46e5;
  color: white;
}

.btn.secondary {
  background: #eef2ff;
  color: #3730a3;
}

.state-card,
.empty-card,
.error-card {
  border-radius: 18px;
  padding: 18px;
  font-weight: 800;
}

.state-card,
.empty-card {
  background: #f9fafb;
  color: #4b5563;
}

.error-card {
  background: #fee2e2;
  color: #991b1b;
}

@media (max-width: 1100px) {
  .score-row {
    grid-template-columns: repeat(2, 1fr);
  }

  .summary-row {
    grid-template-columns: repeat(2, 1fr);
  }

  .widget-header {
    flex-direction: column;
  }
}

@media (max-width: 640px) {
  .score-row,
  .summary-row {
    grid-template-columns: 1fr;
  }
}
</style>
