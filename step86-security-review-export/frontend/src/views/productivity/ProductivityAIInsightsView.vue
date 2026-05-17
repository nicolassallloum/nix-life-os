<script setup>
import { computed, onMounted, ref } from 'vue'
import productivityService from '@/services/productivityService'

const loading = ref(false)
const errorMessage = ref('')
const insights = ref(null)

const score = computed(() => insights.value?.productivity_score ?? 0)
const scoreLabel = computed(() => insights.value?.score_label ?? 'No Data')
const weeklySummary = computed(() => insights.value?.weekly_summary ?? {})
const hasData = computed(() => Boolean(insights.value?.has_data))

const scoreClass = computed(() => {
  if (score.value >= 85) return 'bg-emerald-50 text-emerald-700 border-emerald-200'
  if (score.value >= 70) return 'bg-blue-50 text-blue-700 border-blue-200'
  if (score.value >= 50) return 'bg-amber-50 text-amber-700 border-amber-200'
  if (score.value > 0) return 'bg-orange-50 text-orange-700 border-orange-200'
  return 'bg-slate-50 text-slate-700 border-slate-200'
})

const sections = computed(() => [
  {
    key: 'task_priority_recommendations',
    title: 'Task Priority Recommendations',
    description: 'AI recommendations for overdue, urgent, and high-priority tasks.',
    empty: 'No task priority recommendations right now.',
    items: insights.value?.task_priority_recommendations ?? [],
  },
  {
    key: 'habit_consistency_insights',
    title: 'Habit Consistency Insights',
    description: 'Consistency signals based on active habits and check-ins.',
    empty: 'No habit consistency warnings right now.',
    items: insights.value?.habit_consistency_insights ?? [],
  },
  {
    key: 'goal_progress_recommendations',
    title: 'Goal Progress Recommendations',
    description: 'Progress guidance for active, overdue, and due-soon goals.',
    empty: 'No goal progress recommendations right now.',
    items: insights.value?.goal_progress_recommendations ?? [],
  },
  {
    key: 'calendar_overload_warnings',
    title: 'Calendar Overload Warnings',
    description: 'Warnings for busy days, heavy schedules, and missing focus time.',
    empty: 'No calendar overload warnings right now.',
    items: insights.value?.calendar_overload_warnings ?? [],
  },
])

const summaryCards = computed(() => [
  { label: 'Tasks Completed', value: weeklySummary.value.tasks_completed ?? 0 },
  { label: 'Pending Tasks', value: weeklySummary.value.tasks_pending ?? 0 },
  { label: 'Overdue Tasks', value: weeklySummary.value.overdue_tasks ?? 0 },
  { label: 'Active Habits', value: weeklySummary.value.active_habits ?? 0 },
  { label: 'Habit Check-ins', value: weeklySummary.value.habit_check_ins_this_week ?? 0 },
  { label: 'Active Goals', value: weeklySummary.value.goals_active ?? 0 },
  { label: 'Avg. Goal Progress', value: `${weeklySummary.value.average_goal_progress ?? 0}%` },
  { label: 'Calendar Events', value: weeklySummary.value.calendar_events_this_week ?? 0 },
])

function severityClass(severity) {
  const classes = {
    success: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    info: 'bg-blue-50 text-blue-700 border-blue-200',
    warning: 'bg-amber-50 text-amber-700 border-amber-200',
    danger: 'bg-red-50 text-red-700 border-red-200',
    error: 'bg-red-50 text-red-700 border-red-200',
  }

  return classes[severity] || 'bg-slate-50 text-slate-700 border-slate-200'
}

async function loadInsights() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await productivityService.getAIInsights()
    insights.value = response.data
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.message ||
      'Unable to load Productivity AI Insights. Please try again.'
  } finally {
    loading.value = false
  }
}

onMounted(loadInsights)
</script>

<template>
  <section class="space-y-6">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <p class="text-sm font-semibold uppercase tracking-wide text-indigo-600">
          Productivity AI
        </p>
        <h1 class="mt-1 text-3xl font-black text-slate-950">
          Productivity AI Insights
        </h1>
        <p class="mt-2 max-w-3xl text-sm text-slate-600">
          Analyze tasks, habits, goals, and calendar activity to detect risks,
          productivity patterns, and practical recommendations.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
        :disabled="loading"
        @click="loadInsights"
      >
        {{ loading ? 'Refreshing...' : 'Refresh Insights' }}
      </button>
    </div>

    <div
      v-if="loading"
      class="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm"
    >
      <div class="mx-auto h-10 w-10 animate-spin rounded-full border-4 border-slate-200 border-t-slate-900"></div>
      <p class="mt-4 text-sm font-medium text-slate-600">
        Loading productivity insights...
      </p>
    </div>

    <div
      v-else-if="errorMessage"
      class="rounded-2xl border border-red-200 bg-red-50 p-5 text-red-700 shadow-sm"
    >
      <h2 class="text-base font-bold">Unable to Load Insights</h2>
      <p class="mt-1 text-sm">{{ errorMessage }}</p>
    </div>

    <template v-else-if="insights">
      <div class="grid gap-4 lg:grid-cols-3">
        <div :class="['rounded-2xl border p-6 shadow-sm', scoreClass]">
          <p class="text-sm font-semibold uppercase tracking-wide">Productivity Score</p>
          <div class="mt-4 flex items-end gap-2">
            <span class="text-5xl font-black leading-none">{{ score }}</span>
            <span class="pb-1 text-sm font-bold">/ 100</span>
          </div>
          <p class="mt-3 text-lg font-bold">{{ scoreLabel }}</p>
          <p class="mt-2 text-sm opacity-80">
            Score is calculated from task completion, habit consistency,
            goal progress, and calendar balance.
          </p>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm lg:col-span-2">
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-black text-slate-950">Weekly Summary</h2>
              <p class="text-sm text-slate-500">
                {{ weeklySummary.period?.week_start }} to {{ weeklySummary.period?.week_end }}
              </p>
            </div>

            <span
              class="rounded-full px-3 py-1 text-xs font-bold"
              :class="hasData ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'"
            >
              {{ hasData ? 'Data Available' : 'Empty State' }}
            </span>
          </div>

          <div class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <div
              v-for="card in summaryCards"
              :key="card.label"
              class="rounded-xl border border-slate-100 bg-slate-50 p-4"
            >
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {{ card.label }}
              </p>
              <p class="mt-2 text-2xl font-black text-slate-950">
                {{ card.value }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="!hasData"
        class="rounded-2xl border border-blue-200 bg-blue-50 p-5 text-blue-800 shadow-sm"
      >
        <h2 class="text-base font-bold">Start tracking your productivity</h2>
        <p class="mt-1 text-sm">
          Add tasks, habits, goals, or calendar events to generate richer AI insights.
        </p>
      </div>

      <div class="grid gap-5 xl:grid-cols-2">
        <article
          v-for="section in sections"
          :key="section.key"
          class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
        >
          <div>
            <h2 class="text-lg font-black text-slate-950">{{ section.title }}</h2>
            <p class="mt-1 text-sm text-slate-500">{{ section.description }}</p>
          </div>

          <div v-if="section.items.length" class="mt-5 space-y-3">
            <div
              v-for="item in section.items"
              :key="`${section.key}-${item.title}-${item.severity}`"
              class="rounded-xl border p-4"
              :class="severityClass(item.severity)"
            >
              <div class="flex items-start justify-between gap-3">
                <h3 class="font-bold">{{ item.title }}</h3>
                <span class="rounded-full bg-white/70 px-2 py-1 text-xs font-bold uppercase">
                  {{ item.severity || 'info' }}
                </span>
              </div>
              <p class="mt-2 text-sm">{{ item.message }}</p>
              <p v-if="item.action" class="mt-3 text-sm font-semibold">
                Action: {{ item.action }}
              </p>
            </div>
          </div>

          <div
            v-else
            class="mt-5 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-5 text-sm text-slate-500"
          >
            {{ section.empty }}
          </div>
        </article>
      </div>
    </template>
  </section>
</template>
