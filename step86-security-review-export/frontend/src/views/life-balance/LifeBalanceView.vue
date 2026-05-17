<template>
  <main class="p-6 space-y-8">
    <section class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
      <div>
        <p class="text-sm font-semibold uppercase tracking-wide text-slate-500">NIX LIFE OS</p>
        <h1 class="mt-1 text-4xl font-bold text-slate-950">Life Balance AI</h1>
        <p class="mt-2 max-w-3xl text-slate-500">
          Unified recommendations combining finance, health, projects, and productivity data.
        </p>
      </div>

      <button
        type="button"
        class="rounded-2xl bg-slate-950 px-6 py-4 font-semibold text-white hover:bg-slate-800 disabled:opacity-60"
        :disabled="loading"
        @click="loadLifeBalance"
      >
        {{ loading ? 'Refreshing...' : 'Refresh AI Recommendations' }}
      </button>
    </section>

    <section v-if="error" class="rounded-2xl border border-red-200 bg-red-50 p-4 font-medium text-red-700">
      {{ error }}
    </section>

    <section v-if="loading" class="rounded-2xl border border-slate-100 bg-white p-6 text-slate-500 shadow-sm">
      Loading Life Balance AI recommendations...
    </section>

    <section v-else class="space-y-8">
      <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <article class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm lg:col-span-1">
          <p class="font-semibold text-slate-500">Overall Life Balance Score</p>

          <div class="mt-6 flex items-center justify-center">
            <div class="relative flex h-52 w-52 items-center justify-center rounded-full border-[18px] border-slate-100">
              <div class="absolute inset-[-18px] rounded-full" :style="scoreRingStyle"></div>
              <div class="relative flex h-40 w-40 flex-col items-center justify-center rounded-full bg-white shadow-inner">
                <p class="text-5xl font-bold text-slate-950">{{ score }}</p>
                <p class="text-sm text-slate-500">/ 100</p>
              </div>
            </div>
          </div>

          <p class="mt-6 text-center font-semibold" :class="scoreLabelClass">
            {{ scoreLabel }}
          </p>

          <p class="mt-4 text-center text-sm text-slate-500">
            {{ aiPayload.summary || 'No summary available yet.' }}
          </p>
        </article>

        <article class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm lg:col-span-2">
          <div class="mb-6 flex items-center justify-between gap-4">
            <div>
              <h2 class="text-xl font-bold text-slate-900">AI Category Breakdown</h2>
              <p class="mt-1 text-sm text-slate-500">Score contribution by life area.</p>
            </div>
            <span class="rounded-full px-4 py-2 text-sm font-bold" :class="statusBadgeClass">
              {{ formatLabel(aiPayload.status || 'empty') }}
            </span>
          </div>

          <div class="space-y-5">
            <ScoreBar label="Finance" :value="categoryScore('finance')" icon="💰" />
            <ScoreBar label="Health" :value="categoryScore('health')" icon="🩺" />
            <ScoreBar label="Projects" :value="categoryScore('projects')" icon="📌" />
            <ScoreBar label="Productivity" :value="categoryScore('productivity')" icon="⚡" />
          </div>
        </article>
      </div>

      <div class="grid grid-cols-1 gap-6 md:grid-cols-4">
        <KpiCard title="Finance" :value="`${categoryScore('finance')}%`" subtitle="Accounts, transactions, income, budgets" icon="💸" />
        <KpiCard title="Health" :value="`${categoryScore('health')}%`" subtitle="Nutrition, hydration, weight, steps" icon="❤️" />
        <KpiCard title="Projects" :value="`${categoryScore('projects')}%`" subtitle="Progress, active work, overdue projects" icon="🚀" />
        <KpiCard title="Productivity" :value="`${categoryScore('productivity')}%`" subtitle="Tasks, habits, goals, calendar" icon="📈" />
      </div>

      <section class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
        <div class="mb-6 flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-xl font-bold text-slate-900">AI Recommendations</h2>
            <p class="mt-1 text-sm text-slate-500">
              Prioritized actions generated from your available Life Balance data.
            </p>
          </div>
          <span class="rounded-full bg-slate-100 px-4 py-2 text-sm font-bold text-slate-700">
            {{ recommendations.length }} item(s)
          </span>
        </div>

        <div v-if="!aiPayload.has_data" class="rounded-2xl border border-dashed border-slate-200 bg-slate-50 p-6 text-slate-600">
          No enough data is available yet. Add finance, health, projects, and productivity records to activate Life Balance AI recommendations.
        </div>

        <div v-else-if="recommendations.length === 0" class="rounded-2xl border border-dashed border-slate-200 bg-slate-50 p-6 text-slate-600">
          No recommendations available right now. Your available data does not show urgent action items.
        </div>

        <div v-else class="space-y-4">
          <article
            v-for="(item, index) in recommendations"
            :key="`${item.category}-${item.priority}-${index}`"
            class="rounded-2xl border border-slate-100 p-5 shadow-sm"
          >
            <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
              <div>
                <div class="mb-3 flex flex-wrap gap-2">
                  <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-wide text-slate-600">
                    {{ formatLabel(item.category) }}
                  </span>
                  <span class="rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide" :class="priorityClass(item.priority)">
                    {{ formatLabel(item.priority) }} Priority
                  </span>
                </div>

                <h3 class="text-lg font-bold text-slate-950">{{ item.title }}</h3>
                <p class="mt-2 text-slate-600">{{ item.description }}</p>
              </div>
            </div>

            <div v-if="item.action" class="mt-4 rounded-xl bg-slate-50 p-4 text-sm text-slate-700">
              <strong>Recommended action:</strong> {{ item.action }}
            </div>
          </article>
        </div>
      </section>
    </section>
  </main>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from 'vue'
import lifeBalanceService from '@/services/lifeBalanceService'

const loading = ref(false)
const error = ref('')
const aiPayload = ref({
  has_data: false,
  score: 0,
  status: 'empty',
  summary: '',
  categories: {},
  recommendations: [],
})

const recommendations = computed(() => {
  return Array.isArray(aiPayload.value?.recommendations)
    ? aiPayload.value.recommendations
    : []
})

const score = computed(() => Math.round(Number(aiPayload.value?.score || 0)))

const scoreLabel = computed(() => {
  if (!aiPayload.value?.has_data) return 'Empty State'
  if (score.value >= 80) return 'Excellent Balance'
  if (score.value >= 60) return 'Balanced'
  if (score.value >= 40) return 'Needs Attention'
  return 'Critical Balance'
})

const scoreLabelClass = computed(() => {
  if (!aiPayload.value?.has_data) return 'text-slate-500'
  if (score.value >= 80) return 'text-green-600'
  if (score.value >= 60) return 'text-blue-600'
  if (score.value >= 40) return 'text-yellow-600'
  return 'text-red-600'
})

const statusBadgeClass = computed(() => {
  const status = aiPayload.value?.status || 'empty'
  if (status === 'excellent') return 'bg-green-100 text-green-700'
  if (status === 'balanced') return 'bg-blue-100 text-blue-700'
  if (status === 'needs_attention') return 'bg-yellow-100 text-yellow-700'
  if (status === 'critical') return 'bg-red-100 text-red-700'
  return 'bg-slate-100 text-slate-600'
})

const scoreRingStyle = computed(() => {
  const value = Math.min(Math.max(score.value, 0), 100)
  return {
    background: `conic-gradient(#0f172a ${value * 3.6}deg, transparent 0deg)`,
  }
})

function categoryScore(category) {
  return Math.round(Number(aiPayload.value?.categories?.[category]?.score || 0))
}

function formatLabel(value) {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}

function priorityClass(priority) {
  if (priority === 'critical') return 'bg-red-100 text-red-700'
  if (priority === 'high') return 'bg-orange-100 text-orange-700'
  if (priority === 'medium') return 'bg-yellow-100 text-yellow-700'
  return 'bg-green-100 text-green-700'
}

async function loadLifeBalance() {
  loading.value = true
  error.value = ''

  try {
    const response = await lifeBalanceService.getAiRecommendations()
    aiPayload.value = response?.data || response || {}
  } catch (err) {
    error.value = err.message || 'Unable to load Life Balance AI recommendations.'
    aiPayload.value = {
      has_data: false,
      score: 0,
      status: 'empty',
      summary: '',
      categories: {},
      recommendations: [],
    }
  } finally {
    loading.value = false
  }
}

const KpiCard = defineComponent({
  name: 'KpiCard',
  props: {
    title: { type: String, required: true },
    value: { type: [String, Number], required: true },
    subtitle: { type: String, default: '' },
    icon: { type: String, default: '📊' },
  },
  setup(props) {
    return () =>
      h('div', { class: 'flex items-start justify-between gap-4 rounded-2xl border border-slate-100 bg-white p-6 shadow-sm' }, [
        h('div', {}, [
          h('p', { class: 'font-semibold text-slate-500' }, props.title),
          h('p', { class: 'mt-4 text-3xl font-bold text-slate-950' }, props.value),
          h('p', { class: 'mt-2 text-slate-500' }, props.subtitle),
        ]),
        h('div', { class: 'flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-2xl' }, props.icon),
      ])
  },
})

const ScoreBar = defineComponent({
  name: 'ScoreBar',
  props: {
    label: { type: String, required: true },
    value: { type: [String, Number], required: true },
    icon: { type: String, default: '📊' },
  },
  setup(props) {
    return () => {
      const value = Math.min(Math.max(Number(props.value || 0), 0), 100)

      return h('div', {}, [
        h('div', { class: 'mb-2 flex items-center justify-between' }, [
          h('div', { class: 'font-semibold text-slate-700' }, `${props.icon} ${props.label}`),
          h('div', { class: 'font-bold text-slate-900' }, `${Math.round(value)}%`),
        ]),
        h('div', { class: 'h-3 overflow-hidden rounded-full bg-slate-100' }, [
          h('div', {
            class: 'h-3 rounded-full bg-slate-950',
            style: { width: `${value}%` },
          }),
        ]),
      ])
    }
  },
})

onMounted(loadLifeBalance)
</script>
