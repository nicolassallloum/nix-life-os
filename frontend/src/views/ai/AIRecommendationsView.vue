<template>
  <div class="ai-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Nix Life OS AI Engine</p>
        <h1>AI Recommendations</h1>
        <p class="subtitle">
          Smart rule-based insights generated from finance, health, productivity, goals, habits, and life balance data.
        </p>
      </div>

      <div class="header-actions">
        <button class="btn secondary" :disabled="loadingScores" @click="loadDailyScores(true)">
          Refresh Scores
        </button>

        <button class="btn primary" :disabled="generating" @click="generateRecommendations">
          <span v-if="generating">Generating...</span>
          <span v-else>Generate Recommendations</span>
        </button>
      </div>
    </section>

    <section v-if="errorMessage" class="alert error">
      {{ errorMessage }}
    </section>

    <section v-if="successMessage" class="alert success">
      {{ successMessage }}
    </section>

    <section class="score-grid">
      <div class="score-card main">
        <p>Life Balance</p>
        <h2>{{ latestScore?.life_balance_score ?? '—' }}</h2>
        <span :class="['badge', latestScore?.classification || 'neutral']">
          {{ formatLabel(latestScore?.classification || 'No Score') }}
        </span>
      </div>

      <div class="score-card">
        <p>Finance</p>
        <h2>{{ latestScore?.finance_score ?? '—' }}</h2>
      </div>

      <div class="score-card">
        <p>Health</p>
        <h2>{{ latestScore?.health_score ?? '—' }}</h2>
      </div>

      <div class="score-card">
        <p>Productivity</p>
        <h2>{{ latestScore?.productivity_score ?? '—' }}</h2>
      </div>

      <div class="score-card">
        <p>Goals</p>
        <h2>{{ latestScore?.goals_score ?? '—' }}</h2>
      </div>

      <div class="score-card">
        <p>Habits</p>
        <h2>{{ latestScore?.habits_score ?? '—' }}</h2>
      </div>
    </section>

    <section class="filters-card">
      <div class="filter-group">
        <label>Module</label>
        <select v-model="filters.module" @change="loadRecommendations">
          <option value="">All Modules</option>
          <option value="finance">Finance</option>
          <option value="health">Health</option>
          <option value="productivity">Productivity</option>
          <option value="life_balance">Life Balance</option>
          <option value="goals">Goals</option>
          <option value="habits">Habits</option>
          <option value="system">System</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Status</label>
        <select v-model="filters.status" @change="loadRecommendations">
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="viewed">Viewed</option>
          <option value="accepted">Accepted</option>
          <option value="dismissed">Dismissed</option>
          <option value="completed">Completed</option>
          <option value="expired">Expired</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Severity</label>
        <select v-model="filters.severity" @change="loadRecommendations">
          <option value="">All Severities</option>
          <option value="critical">Critical</option>
          <option value="high">High</option>
          <option value="medium">Medium</option>
          <option value="low">Low</option>
          <option value="positive">Positive</option>
          <option value="info">Info</option>
        </select>
      </div>

      <div class="filter-group checkbox">
        <label>
          <input v-model="filters.active_only" type="checkbox" @change="loadRecommendations" />
          Active only
        </label>
      </div>

      <button class="btn secondary" @click="resetFilters">
        Reset
      </button>
    </section>

    <section class="summary-row">
      <div>
        <strong>Total:</strong> {{ summary.total || 0 }}
      </div>
      <div>
        <strong>Pending:</strong> {{ summary.pending || 0 }}
      </div>
      <div>
        <strong>Viewed:</strong> {{ summary.viewed || 0 }}
      </div>
      <div>
        <strong>Accepted:</strong> {{ summary.accepted || 0 }}
      </div>
      <div>
        <strong>Dismissed:</strong> {{ summary.dismissed || 0 }}
      </div>
      <div>
        <strong>Completed:</strong> {{ summary.completed || 0 }}
      </div>
    </section>

    <section v-if="loadingRecommendations" class="loading-card">
      Loading AI recommendations...
    </section>

    <section v-else-if="recommendations.length === 0" class="empty-card">
      <h3>No AI recommendations found</h3>
      <p>
        Generate recommendations or change your filters to see AI insights.
      </p>
      <button class="btn primary" :disabled="generating" @click="generateRecommendations">
        Generate Recommendations
      </button>
    </section>

    <section v-else class="recommendation-list">
      <article
        v-for="recommendation in recommendations"
        :key="recommendation.id"
        class="recommendation-card"
      >
        <div class="recommendation-top">
          <div>
            <div class="card-badges">
              <span :class="['badge', recommendation.severity]">
                {{ formatLabel(recommendation.severity) }}
              </span>

              <span :class="['badge', recommendation.status]">
                {{ formatLabel(recommendation.status) }}
              </span>

              <span class="badge neutral">
                {{ formatLabel(recommendation.module) }}
              </span>
            </div>

            <h3>{{ recommendation.title }}</h3>
          </div>

          <div class="score-mini">
            <span>Confidence</span>
            <strong>{{ recommendation.confidence_score }}</strong>
          </div>
        </div>

        <p class="message">
          {{ recommendation.message }}
        </p>

        <div v-if="recommendation.action_text" class="action-box">
          <strong>Recommended Action:</strong>
          <p>{{ recommendation.action_text }}</p>
        </div>

        <div class="meta-grid">
          <div>
            <span>Type</span>
            <strong>{{ formatLabel(recommendation.recommendation_type) }}</strong>
          </div>
          <div>
            <span>Priority</span>
            <strong>{{ recommendation.priority }}</strong>
          </div>
          <div>
            <span>Impact</span>
            <strong>{{ recommendation.impact_score }}</strong>
          </div>
          <div>
            <span>Period</span>
            <strong>{{ recommendation.period_key }}</strong>
          </div>
        </div>

        <details class="details">
          <summary>Rule and metric details</summary>
          <pre>{{ prettyJson(recommendation.source_data) }}</pre>
        </details>

        <div class="card-actions">
          <button
            class="btn ghost"
            :disabled="isActionLoading(recommendation.id)"
            @click="markViewed(recommendation)"
          >
            Mark Viewed
          </button>

          <button
            class="btn success"
            :disabled="isActionLoading(recommendation.id)"
            @click="acceptRecommendation(recommendation)"
          >
            Accept
          </button>

          <button
            class="btn warning"
            :disabled="isActionLoading(recommendation.id)"
            @click="dismissRecommendation(recommendation)"
          >
            Dismiss
          </button>

          <button
            class="btn primary"
            :disabled="isActionLoading(recommendation.id)"
            @click="completeRecommendation(recommendation)"
          >
            Complete
          </button>

          <button
            class="btn secondary"
            :disabled="isActionLoading(recommendation.id)"
            @click="submitUsefulFeedback(recommendation)"
          >
            Useful +5
          </button>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import aiRecommendationService from '@/services/aiRecommendationService'

const recommendations = ref([])
const summary = ref({})
const dailyScores = ref([])
const latestScore = computed(() => dailyScores.value?.[0] || null)

const loadingRecommendations = ref(false)
const loadingScores = ref(false)
const generating = ref(false)
const actionLoadingId = ref(null)

const errorMessage = ref('')
const successMessage = ref('')

const filters = reactive({
  module: '',
  status: '',
  severity: '',
  active_only: false,
  limit: 50,
})

onMounted(async () => {
  await Promise.all([
    loadRecommendations(),
    loadDailyScores(false),
  ])
})

function clearMessages() {
  errorMessage.value = ''
  successMessage.value = ''
}

function handleError(error, fallbackMessage) {
  console.error(error)

  errorMessage.value =
    error?.response?.data?.message ||
    error?.message ||
    fallbackMessage ||
    'Something went wrong.'
}

async function loadRecommendations() {
  clearMessages()
  loadingRecommendations.value = true

  try {
    const response = await aiRecommendationService.getRecommendations({
      module: filters.module,
      status: filters.status,
      severity: filters.severity,
      active_only: filters.active_only,
      limit: filters.limit,
    })

    recommendations.value = response.data?.recommendations || []
    summary.value = response.data?.summary || {}
  } catch (error) {
    handleError(error, 'Failed to load AI recommendations.')
  } finally {
    loadingRecommendations.value = false
  }
}

async function loadDailyScores(generateToday = false) {
  clearMessages()
  loadingScores.value = true

  try {
    const response = await aiRecommendationService.getDailyScores({
      generate_today: generateToday,
      limit: 30,
    })

    dailyScores.value = response.data?.scores || []

    if (generateToday) {
      successMessage.value = 'Daily AI scores refreshed successfully.'
    }
  } catch (error) {
    handleError(error, 'Failed to load daily AI scores.')
  } finally {
    loadingScores.value = false
  }
}

async function generateRecommendations() {
  clearMessages()
  generating.value = true

  try {
    const response = await aiRecommendationService.generateRecommendations({
      store_daily_score: true,
    })

    const generatedCount = response.data?.generated_count || 0
    const skippedCount = response.data?.skipped_count || 0

    successMessage.value = `AI generation completed. Generated: ${generatedCount}, Skipped: ${skippedCount}.`

    await Promise.all([
      loadRecommendations(),
      loadDailyScores(false),
    ])
  } catch (error) {
    handleError(error, 'Failed to generate AI recommendations.')
  } finally {
    generating.value = false
  }
}

async function markViewed(recommendation) {
  await runRecommendationAction(
    recommendation,
    () => aiRecommendationService.markViewed(recommendation.id),
    'Recommendation marked as viewed.'
  )
}

async function acceptRecommendation(recommendation) {
  await runRecommendationAction(
    recommendation,
    () => aiRecommendationService.acceptRecommendation(recommendation.id),
    'Recommendation accepted successfully.'
  )
}

async function dismissRecommendation(recommendation) {
  const reason = window.prompt('Dismiss reason:', 'Not relevant for today')

  await runRecommendationAction(
    recommendation,
    () => aiRecommendationService.dismissRecommendation(recommendation.id, reason),
    'Recommendation dismissed successfully.'
  )
}

async function completeRecommendation(recommendation) {
  await runRecommendationAction(
    recommendation,
    () => aiRecommendationService.completeRecommendation(recommendation.id),
    'Recommendation completed successfully.'
  )
}

async function submitUsefulFeedback(recommendation) {
  await runRecommendationAction(
    recommendation,
    () => aiRecommendationService.submitFeedback(recommendation.id, {
      feedback_type: 'useful',
      feedback_value: 5,
      feedback_comment: 'This recommendation is useful.',
    }),
    'Feedback submitted successfully.'
  )
}

async function runRecommendationAction(recommendation, action, message) {
  clearMessages()
  actionLoadingId.value = recommendation.id

  try {
    await action()
    successMessage.value = message
    await loadRecommendations()
  } catch (error) {
    handleError(error, 'Failed to update recommendation.')
  } finally {
    actionLoadingId.value = null
  }
}

function resetFilters() {
  filters.module = ''
  filters.status = ''
  filters.severity = ''
  filters.active_only = false
  filters.limit = 50

  loadRecommendations()
}

function isActionLoading(id) {
  return actionLoadingId.value === id
}

function formatLabel(value) {
  if (!value) return 'N/A'

  return String(value)
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}

function prettyJson(value) {
  return JSON.stringify(value || {}, null, 2)
}
</script>

<style scoped>
.ai-page {
  padding: 24px;
  color: #111827;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.eyebrow {
  margin: 0 0 6px;
  color: #6366f1;
  font-size: 13px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

h1 {
  margin: 0;
  font-size: 32px;
  font-weight: 800;
}

.subtitle {
  max-width: 760px;
  margin: 8px 0 0;
  color: #6b7280;
  line-height: 1.6;
}

.header-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.btn {
  border: 0;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s ease;
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

.btn.ghost {
  background: #f3f4f6;
  color: #374151;
}

.btn.success {
  background: #dcfce7;
  color: #166534;
}

.btn.warning {
  background: #fef3c7;
  color: #92400e;
}

.alert {
  border-radius: 14px;
  padding: 14px 16px;
  margin-bottom: 16px;
  font-weight: 700;
}

.alert.error {
  background: #fee2e2;
  color: #991b1b;
}

.alert.success {
  background: #dcfce7;
  color: #166534;
}

.score-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}

.score-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 18px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
}

.score-card.main {
  grid-column: span 2;
}

.score-card p {
  margin: 0;
  color: #6b7280;
  font-weight: 700;
}

.score-card h2 {
  margin: 8px 0;
  font-size: 30px;
}

.filters-card {
  display: flex;
  align-items: end;
  gap: 14px;
  flex-wrap: wrap;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 16px;
  margin-bottom: 16px;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filter-group label {
  font-size: 13px;
  color: #374151;
  font-weight: 700;
}

.filter-group select {
  min-width: 170px;
  border: 1px solid #d1d5db;
  border-radius: 12px;
  padding: 10px;
  background: white;
}

.filter-group.checkbox {
  padding-bottom: 10px;
}

.summary-row {
  display: flex;
  gap: 18px;
  flex-wrap: wrap;
  margin-bottom: 16px;
  color: #4b5563;
}

.loading-card,
.empty-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 28px;
  text-align: center;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
}

.empty-card h3 {
  margin-top: 0;
}

.empty-card p {
  color: #6b7280;
}

.recommendation-list {
  display: grid;
  gap: 16px;
}

.recommendation-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 22px;
  padding: 20px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.06);
}

.recommendation-top {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.card-badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 10px;
}

.badge {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
}

.badge.critical {
  background: #fee2e2;
  color: #991b1b;
}

.badge.high {
  background: #ffedd5;
  color: #9a3412;
}

.badge.medium {
  background: #fef3c7;
  color: #92400e;
}

.badge.low {
  background: #e0f2fe;
  color: #075985;
}

.badge.positive,
.badge.completed,
.badge.accepted,
.badge.good,
.badge.excellent {
  background: #dcfce7;
  color: #166534;
}

.badge.pending,
.badge.viewed {
  background: #eef2ff;
  color: #3730a3;
}

.badge.dismissed,
.badge.expired,
.badge.risk,
.badge.critical {
  background: #fee2e2;
  color: #991b1b;
}

.badge.neutral,
.badge.info,
.badge.needs_attention {
  background: #f3f4f6;
  color: #374151;
}

.recommendation-card h3 {
  margin: 0;
  font-size: 22px;
}

.score-mini {
  text-align: right;
}

.score-mini span {
  display: block;
  color: #6b7280;
  font-size: 12px;
  font-weight: 700;
}

.score-mini strong {
  font-size: 24px;
}

.message {
  color: #374151;
  line-height: 1.7;
}

.action-box {
  background: #f9fafb;
  border-left: 4px solid #4f46e5;
  border-radius: 14px;
  padding: 14px;
  margin: 14px 0;
}

.action-box p {
  margin: 6px 0 0;
  color: #4b5563;
}

.meta-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin: 16px 0;
}

.meta-grid div {
  background: #f9fafb;
  border-radius: 14px;
  padding: 12px;
}

.meta-grid span {
  display: block;
  color: #6b7280;
  font-size: 12px;
  font-weight: 700;
}

.meta-grid strong {
  display: block;
  margin-top: 4px;
  color: #111827;
}

.details {
  margin: 14px 0;
}

.details summary {
  cursor: pointer;
  color: #4f46e5;
  font-weight: 800;
}

pre {
  background: #111827;
  color: #f9fafb;
  border-radius: 14px;
  padding: 14px;
  overflow-x: auto;
  font-size: 12px;
}

.card-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

@media (max-width: 1200px) {
  .score-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .score-card.main {
    grid-column: span 1;
  }
}

@media (max-width: 768px) {
  .ai-page {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
  }

  .score-grid,
  .meta-grid {
    grid-template-columns: 1fr;
  }

  .recommendation-top {
    flex-direction: column;
  }

  .score-mini {
    text-align: left;
  }
}
</style>
