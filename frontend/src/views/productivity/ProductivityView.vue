<template>
  <main class="page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Nix Life OS</p>
        <h1>Productivity</h1>
        <p>Organize tasks, habits, goals, happy wins, calendar events, and daily planning.</p>
      </div>

      <div class="header-actions">
        <RouterLink class="secondary-btn" to="/productivity/happy-wins">Happy Wins</RouterLink>
        <RouterLink class="primary-btn" to="/productivity/goals">Add Goal</RouterLink>
      </div>
    </section>

    <section v-if="error" class="alert error">
      {{ error }}
    </section>

    <section class="cards-grid">
      <article class="summary-card">
        <h3>Active Goals</h3>
        <strong>{{ dashboard.summary.active_goals }}</strong>
        <span>Currently in progress</span>
      </article>

      <article class="summary-card">
        <h3>Completed Goals</h3>
        <strong>{{ dashboard.summary.completed_goals }}</strong>
        <span>Finished goals</span>
      </article>

      <article class="summary-card">
        <h3>Happy Wins</h3>
        <strong>{{ dashboard.summary.happy_wins_count }}</strong>
        <span>{{ dashboard.summary.weekly_happy_wins_count }} this week</span>
      </article>

      <article class="summary-card">
        <h3>Weekly Score</h3>
        <strong>{{ dashboard.summary.weekly_productivity_score }}%</strong>
        <span>Productivity score</span>
      </article>
    </section>

    <section class="content-grid">
      <article class="content-card">
        <div class="card-header">
          <div>
            <h2>Productivity Workspace</h2>
            <p>Continue from the module shortcuts below.</p>
          </div>
          <button class="refresh-btn" type="button" :disabled="loading" @click="loadDashboard">
            {{ loading ? "Loading..." : "Refresh" }}
          </button>
        </div>

        <div class="shortcut-grid">
          <RouterLink class="shortcut-card" to="/productivity/dashboard">
            <strong>Dashboard</strong>
            <span>View KPIs and weekly charts</span>
          </RouterLink>

          <RouterLink class="shortcut-card" to="/productivity/goals">
            <strong>Goals</strong>
            <span>Create and track productivity goals</span>
          </RouterLink>

          <RouterLink class="shortcut-card" to="/productivity/happy-wins">
            <strong>Happy Wins</strong>
            <span>Log positive wins and motivation</span>
          </RouterLink>

          <RouterLink class="shortcut-card" to="/productivity/habits">
            <strong>Habits</strong>
            <span>Track routines and consistency</span>
          </RouterLink>

          <RouterLink class="shortcut-card" to="/productivity/tasks">
            <strong>Tasks</strong>
            <span>Manage daily work and priorities</span>
          </RouterLink>

          <RouterLink class="shortcut-card" to="/productivity/calendar">
            <strong>Calendar</strong>
            <span>Plan schedule and focus sessions</span>
          </RouterLink>
        </div>
      </article>

      <article class="content-card">
        <div class="card-header">
          <div>
            <h2>Latest Happy Wins</h2>
            <p>Recent positive productivity moments.</p>
          </div>
          <RouterLink class="text-link" to="/productivity/happy-wins">View all</RouterLink>
        </div>

        <div v-if="latestWins.length === 0" class="empty-mini">
          No happy wins yet.
        </div>

        <ul v-else class="wins-list">
          <li v-for="win in latestWins" :key="win.id">
            <div>
              <strong>{{ win.title }}</strong>
              <span>{{ formatDate(win.win_date) }} · Score {{ win.score }}/10</span>
            </div>
            <em v-if="win.mood">{{ win.mood }}</em>
          </li>
        </ul>
      </article>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import productivityService from "@/services/productivityService";

const loading = ref(false);
const error = ref("");

const emptyDashboard = () => ({
  summary: {
    active_goals: 0,
    completed_goals: 0,
    happy_wins_count: 0,
    weekly_happy_wins_count: 0,
    weekly_productivity_score: 0,
  },
  happy_wins: {
    latest_wins: [],
  },
});

const dashboard = ref(emptyDashboard());

const latestWins = computed(() =>
  Array.isArray(dashboard.value?.happy_wins?.latest_wins)
    ? dashboard.value.happy_wins.latest_wins
    : []
);

async function loadDashboard() {
  loading.value = true;
  error.value = "";

  try {
    const response = await productivityService.getDashboardSummary();
    const data = response?.data || {};
    const fallback = emptyDashboard();

    dashboard.value = {
      ...fallback,
      ...data,
      summary: {
        ...fallback.summary,
        ...data.summary,
      },
      happy_wins: {
        ...fallback.happy_wins,
        ...data.happy_wins,
        latest_wins: Array.isArray(data.happy_wins?.latest_wins)
          ? data.happy_wins.latest_wins
          : [],
      },
    };
  } catch (err) {
    error.value = err.response?.data?.message || err.message || "Unable to load productivity summary.";
  } finally {
    loading.value = false;
  }
}

function formatDate(value) {
  if (!value) return "-";

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
  }).format(new Date(value));
}

onMounted(loadDashboard);
</script>

<style scoped>
.page {
  display: grid;
  gap: 24px;
  padding: 24px;
}

.page-header,
.card-header,
.header-actions {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
}

.eyebrow {
  margin: 0 0 6px;
  color: #2563eb;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.page-header h1,
.content-card h2 {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  color: #111827;
}

.page-header p,
.content-card p,
.shortcut-card span,
.empty-mini,
.wins-list span {
  color: #6b7280;
}

.primary-btn,
.secondary-btn,
.refresh-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  text-decoration: none;
  padding: 11px 16px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: white;
}

.secondary-btn,
.refresh-btn {
  background: #eef2ff;
  color: #3730a3;
}

.alert {
  border-radius: 14px;
  padding: 12px 14px;
  font-weight: 700;
}

.alert.error {
  background: #fef2f2;
  color: #991b1b;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
}

.summary-card,
.content-card,
.shortcut-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 20px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.summary-card h3 {
  margin: 0 0 10px;
  color: #374151;
  font-size: 14px;
}

.summary-card strong {
  display: block;
  font-size: 30px;
  color: #111827;
}

.summary-card span {
  color: #6b7280;
  font-size: 13px;
}

.content-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(320px, 0.8fr);
  gap: 16px;
}

.shortcut-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(180px, 1fr));
  gap: 12px;
  margin-top: 16px;
}

.shortcut-card {
  display: grid;
  gap: 6px;
  text-decoration: none;
  color: #111827;
}

.text-link {
  color: #2563eb;
  font-weight: 800;
  text-decoration: none;
}

.wins-list {
  display: grid;
  gap: 12px;
  list-style: none;
  padding: 0;
  margin: 16px 0 0;
}

.wins-list li {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  background: #f8fafc;
}

.wins-list li div {
  display: grid;
  gap: 4px;
}

.wins-list em {
  color: #047857;
  font-style: normal;
  font-weight: 800;
}

@media (max-width: 1000px) {
  .cards-grid,
  .content-grid,
  .shortcut-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 620px) {
  .cards-grid,
  .shortcut-grid {
    grid-template-columns: 1fr;
  }

  .page-header,
  .card-header,
  .header-actions,
  .wins-list li {
    flex-direction: column;
  }
}
</style>
