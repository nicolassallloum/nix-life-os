<template>
  <section class="productivity-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Productivity Module</p>
        <h1>Productivity Dashboard</h1>
        <p class="subtitle">
          Track tasks, habits, goals, calendar events, charts, and daily progress from one screen.
        </p>
      </div>

      <button class="refresh-button" type="button" :disabled="loading" @click="loadDashboard">
        {{ loading ? "Loading..." : "Refresh" }}
      </button>
    </header>

    <div v-if="loading" class="state-card">
      <div class="spinner"></div>
      <h2>Loading productivity dashboard...</h2>
      <p>Please wait while the productivity summary is being loaded.</p>
    </div>

    <div v-else-if="error" class="state-card error-state">
      <h2>Unable to load Productivity Dashboard</h2>
      <p>{{ error }}</p>
      <button class="refresh-button" type="button" @click="loadDashboard">Try Again</button>
    </div>

    <div v-else-if="dashboard?.summary?.empty_state" class="state-card empty-state">
      <h2>No productivity data yet</h2>
      <p>
        Create productivity tasks, habits, goals, or calendar events to start seeing dashboard KPIs and charts.
      </p>
    </div>

    <template v-else-if="dashboard">
      <div class="daily-progress-card">
        <div>
          <p class="eyebrow">Daily Progress</p>
          <h2>{{ dashboard.summary.daily_progress_percentage }}%</h2>
          <p>
            Completed today: {{ dashboard.summary.total_completed_today }} · Open items:
            {{ dashboard.summary.total_open_items }}
          </p>
        </div>
        <div class="progress-ring" :style="progressRingStyle">
          <span>{{ dashboard.summary.daily_progress_percentage }}%</span>
        </div>
      </div>

      <div class="kpi-grid">
        <article class="kpi-card">
          <p>Tasks</p>
          <h3>{{ dashboard.tasks.total_tasks }}</h3>
          <small>
            {{ dashboard.tasks.completed_tasks }} completed · {{ dashboard.tasks.overdue_tasks }} overdue
          </small>
        </article>

        <article class="kpi-card">
          <p>Habits</p>
          <h3>{{ dashboard.habits.total_habits }}</h3>
          <small>
            {{ dashboard.habits.completed_today }} completed today · {{ dashboard.habits.best_streak }} best streak
          </small>
        </article>

        <article class="kpi-card">
          <p>Goals</p>
          <h3>{{ dashboard.goals.total_goals }}</h3>
          <small>
            {{ dashboard.goals.average_progress_percentage }}% average progress ·
            {{ dashboard.goals.overdue_goals }} overdue
          </small>
        </article>

        <article class="kpi-card">
          <p>Calendar</p>
          <h3>{{ dashboard.calendar.today_events }}</h3>
          <small>
            Today · {{ dashboard.calendar.upcoming_events }} upcoming
          </small>
        </article>
      </div>

      <div class="summary-grid">
        <article class="panel">
          <div class="panel-header">
            <h2>Task Summary</h2>
            <span>{{ dashboard.tasks.completion_rate }}%</span>
          </div>
          <dl class="metric-list">
            <div><dt>Todo</dt><dd>{{ dashboard.tasks.todo_tasks }}</dd></div>
            <div><dt>In Progress</dt><dd>{{ dashboard.tasks.in_progress_tasks }}</dd></div>
            <div><dt>Due Today</dt><dd>{{ dashboard.tasks.due_today }}</dd></div>
            <div><dt>Overdue</dt><dd>{{ dashboard.tasks.overdue_tasks }}</dd></div>
          </dl>
        </article>

        <article class="panel">
          <div class="panel-header">
            <h2>Habit Summary</h2>
            <span>{{ dashboard.habits.consistency_rate }}%</span>
          </div>
          <dl class="metric-list">
            <div><dt>Active</dt><dd>{{ dashboard.habits.active_habits }}</dd></div>
            <div><dt>Completed Today</dt><dd>{{ dashboard.habits.completed_today }}</dd></div>
            <div><dt>Missed Today</dt><dd>{{ dashboard.habits.missed_today }}</dd></div>
            <div><dt>Paused</dt><dd>{{ dashboard.habits.paused_habits }}</dd></div>
          </dl>
        </article>

        <article class="panel">
          <div class="panel-header">
            <h2>Goals Summary</h2>
            <span>{{ dashboard.goals.completion_rate }}%</span>
          </div>
          <dl class="metric-list">
            <div><dt>Active</dt><dd>{{ dashboard.goals.active_goals }}</dd></div>
            <div><dt>Completed</dt><dd>{{ dashboard.goals.completed_goals }}</dd></div>
            <div><dt>Due This Week</dt><dd>{{ dashboard.goals.due_this_week }}</dd></div>
            <div><dt>On Hold</dt><dd>{{ dashboard.goals.on_hold_goals }}</dd></div>
          </dl>
        </article>

        <article class="panel">
          <div class="panel-header">
            <h2>Calendar Summary</h2>
            <span>{{ dashboard.calendar.week_events }}</span>
          </div>
          <dl class="metric-list">
            <div><dt>Today</dt><dd>{{ dashboard.calendar.today_events }}</dd></div>
            <div><dt>This Week</dt><dd>{{ dashboard.calendar.week_events }}</dd></div>
            <div><dt>Upcoming</dt><dd>{{ dashboard.calendar.upcoming_events }}</dd></div>
            <div><dt>Cancelled</dt><dd>{{ dashboard.calendar.cancelled_events }}</dd></div>
          </dl>
        </article>
      </div>

      <div class="chart-grid">
        <article class="panel">
          <h2>Tasks by Status</h2>
          <ChartBars :items="dashboard.charts.tasks_by_status" />
        </article>

        <article class="panel">
          <h2>Goals by Status</h2>
          <ChartBars :items="dashboard.charts.goals_by_status" />
        </article>

        <article class="panel">
          <h2>Habit Completion - Last 7 Days</h2>
          <ChartBars :items="habitChartItems" label-key="date" value-key="completed" />
        </article>

        <article class="panel">
          <h2>Calendar Events - Next 7 Days</h2>
          <ChartBars :items="calendarChartItems" label-key="date" value-key="events" />
        </article>
      </div>

      <article class="panel">
        <div class="panel-header">
          <h2>Next Calendar Events</h2>
          <span>{{ dashboard.calendar.next_events.length }}</span>
        </div>

        <div v-if="dashboard.calendar.next_events.length === 0" class="mini-empty">
          No upcoming calendar events.
        </div>

        <ul v-else class="event-list">
          <li v-for="event in dashboard.calendar.next_events" :key="event.id">
            <div>
              <strong>{{ event.title }}</strong>
              <span>{{ formatDateTime(event.start_time) }}</span>
            </div>
            <em>{{ event.event_type }}</em>
          </li>
        </ul>
      </article>
    </template>
  </section>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from "vue";
import productivityService from "@/services/productivityService";

const loading = ref(false);
const error = ref("");
const dashboard = ref(null);

const ChartBars = defineComponent({
  name: "ChartBars",
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    labelKey: {
      type: String,
      default: "label",
    },
    valueKey: {
      type: String,
      default: "value",
    },
  },
  setup(props) {
    const maxValue = computed(() => {
      const values = props.items.map((item) => Number(item[props.valueKey] || 0));
      return Math.max(...values, 1);
    });

    return () =>
      h(
        "div",
        { class: "chart-bars" },
        props.items.map((item) => {
          const value = Number(item[props.valueKey] || 0);
          const width = `${Math.max((value / maxValue.value) * 100, value > 0 ? 8 : 0)}%`;

          return h("div", { class: "chart-row", key: item[props.labelKey] }, [
            h("div", { class: "chart-row-top" }, [
              h("span", formatLabel(item[props.labelKey])),
              h("strong", value),
            ]),
            h("div", { class: "chart-track" }, [
              h("div", { class: "chart-fill", style: { width } }),
            ]),
          ]);
        })
      );
  },
});

const progressRingStyle = computed(() => ({
  background: `conic-gradient(#0f172a ${dashboard.value?.summary?.daily_progress_percentage || 0}%, #e2e8f0 0)`,
}));

const habitChartItems = computed(() => dashboard.value?.charts?.habit_completion_last_7_days || []);
const calendarChartItems = computed(() => dashboard.value?.charts?.calendar_next_7_days || []);

async function loadDashboard() {
  loading.value = true;
  error.value = "";

  try {
    const response = await productivityService.getDashboardSummary();
    dashboard.value = response.data;
  } catch (err) {
    error.value = err.response?.data?.message || err.message || "Unexpected dashboard error.";
  } finally {
    loading.value = false;
  }
}

function formatLabel(value) {
  return String(value || "-").replaceAll("_", " ");
}

function formatDateTime(value) {
  if (!value) return "-";
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

onMounted(loadDashboard);
</script>

<style scoped>
.productivity-page {
  display: grid;
  gap: 24px;
}

.page-header,
.daily-progress-card,
.panel,
.kpi-card,
.state-card {
  border: 1px solid #e2e8f0;
  border-radius: 24px;
  background: #ffffff;
  box-shadow: 0 16px 40px rgba(15, 23, 42, 0.06);
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 28px;
}

.eyebrow {
  margin: 0 0 8px;
  color: #64748b;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

h1,
h2,
h3,
p {
  margin: 0;
}

h1 {
  color: #0f172a;
  font-size: 32px;
  font-weight: 900;
}

.subtitle {
  margin-top: 8px;
  color: #64748b;
}

.refresh-button {
  border: 0;
  border-radius: 14px;
  background: #0f172a;
  color: #ffffff;
  cursor: pointer;
  font-weight: 800;
  padding: 12px 18px;
}

.refresh-button:disabled {
  cursor: not-allowed;
  opacity: 0.7;
}

.state-card {
  display: grid;
  gap: 10px;
  justify-items: center;
  padding: 48px 24px;
  text-align: center;
}

.state-card p {
  color: #64748b;
}

.error-state {
  border-color: #fecaca;
  background: #fff7f7;
}

.empty-state {
  border-style: dashed;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 4px solid #e2e8f0;
  border-top-color: #0f172a;
  border-radius: 999px;
  animation: spin 0.9s linear infinite;
}

.daily-progress-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 28px;
}

.daily-progress-card h2 {
  font-size: 44px;
  font-weight: 900;
  color: #0f172a;
}

.daily-progress-card p:not(.eyebrow) {
  color: #64748b;
}

.progress-ring {
  display: grid;
  place-items: center;
  width: 124px;
  height: 124px;
  border-radius: 999px;
}

.progress-ring span {
  display: grid;
  place-items: center;
  width: 92px;
  height: 92px;
  border-radius: 999px;
  background: white;
  color: #0f172a;
  font-size: 22px;
  font-weight: 900;
}

.kpi-grid,
.summary-grid,
.chart-grid {
  display: grid;
  gap: 16px;
}

.kpi-grid {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.summary-grid,
.chart-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.kpi-card,
.panel {
  padding: 22px;
}

.kpi-card p {
  color: #64748b;
  font-weight: 800;
}

.kpi-card h3 {
  margin-top: 8px;
  color: #0f172a;
  font-size: 34px;
  font-weight: 900;
}

.kpi-card small {
  display: block;
  margin-top: 8px;
  color: #64748b;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 18px;
}

.panel h2 {
  color: #0f172a;
  font-size: 18px;
  font-weight: 900;
}

.panel-header span {
  border-radius: 999px;
  background: #f1f5f9;
  color: #0f172a;
  font-size: 12px;
  font-weight: 900;
  padding: 7px 10px;
}

.metric-list {
  display: grid;
  gap: 10px;
  margin: 0;
}

.metric-list div {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 10px;
}

.metric-list dt {
  color: #64748b;
}

.metric-list dd {
  margin: 0;
  color: #0f172a;
  font-weight: 900;
}

.chart-bars {
  display: grid;
  gap: 14px;
  margin-top: 18px;
}

.chart-row-top {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  color: #334155;
  font-size: 13px;
  text-transform: capitalize;
}

.chart-track {
  height: 10px;
  margin-top: 6px;
  overflow: hidden;
  border-radius: 999px;
  background: #e2e8f0;
}

.chart-fill {
  height: 100%;
  border-radius: 999px;
  background: #0f172a;
}

.event-list {
  display: grid;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.event-list li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 14px;
}

.event-list strong,
.event-list span {
  display: block;
}

.event-list span,
.event-list em,
.mini-empty {
  color: #64748b;
  font-size: 13px;
}

.event-list em {
  text-transform: capitalize;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 1100px) {
  .kpi-grid,
  .summary-grid,
  .chart-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 720px) {
  .page-header,
  .daily-progress-card {
    align-items: flex-start;
    flex-direction: column;
  }

  .kpi-grid,
  .summary-grid,
  .chart-grid {
    grid-template-columns: 1fr;
  }
}
</style>
