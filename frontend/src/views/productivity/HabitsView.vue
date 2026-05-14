<template>
  <main class="habits-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Productivity</p>
        <h1>Habits</h1>
        <p class="subtitle">Create habits, track daily check-ins, and monitor weekly consistency.</p>
      </div>
      <button class="primary-btn" type="button" @click="openCreateForm">+ Add Habit</button>
    </section>

    <section v-if="errorMessage" class="alert error">
      {{ errorMessage }}
    </section>

    <section class="summary-grid">
      <article class="summary-card">
        <span>Total Habits</span>
        <strong>{{ weeklySummary.total_habits }}</strong>
      </article>
      <article class="summary-card">
        <span>Active</span>
        <strong>{{ weeklySummary.active_habits }}</strong>
      </article>
      <article class="summary-card">
        <span>Completed</span>
        <strong>{{ weeklySummary.completed_check_ins }}</strong>
      </article>
      <article class="summary-card">
        <span>Completion Rate</span>
        <strong>{{ weeklySummary.completion_rate }}%</strong>
      </article>
    </section>

    <section class="panel chart-panel">
      <div class="panel-header">
        <div>
          <h2>Weekly Progress</h2>
          <p>Completed and missed check-ins for the selected week.</p>
        </div>
      </div>
      <div v-if="dailyProgress.length" class="progress-chart">
        <div v-for="day in dailyProgress" :key="day.date" class="chart-row">
          <span>{{ formatShortDate(day.date) }}</span>
          <div class="bar-track">
            <div class="bar-completed" :style="{ width: chartWidth(day.completed) }"></div>
            <div class="bar-missed" :style="{ width: chartWidth(day.missed) }"></div>
          </div>
          <strong>{{ day.completed }} / {{ day.total }}</strong>
        </div>
      </div>
      <div v-else class="empty-mini">No weekly habit data yet.</div>
    </section>

    <section class="panel">
      <div class="panel-header">
        <div>
          <h2>Habit List</h2>
          <p>Manage active, paused, and archived habits.</p>
        </div>
        <select v-model="filters.status" @change="loadHabits">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="paused">Paused</option>
          <option value="archived">Archived</option>
        </select>
      </div>

      <div v-if="loading" class="loading">Loading habits...</div>

      <div v-else-if="!habits.length" class="empty-state">
        <h3>No habits found</h3>
        <p>Create your first habit to start tracking consistency.</p>
        <button class="primary-btn" type="button" @click="openCreateForm">Create Habit</button>
      </div>

      <div v-else class="habit-grid">
        <article v-for="habit in habits" :key="habit.id" class="habit-card">
          <div class="habit-card-header">
            <div>
              <h3>{{ habit.name || habit.title }}</h3>
              <p>{{ habit.description || "No description" }}</p>
            </div>
            <span :class="['status-badge', habit.status]">{{ habit.status }}</span>
          </div>

          <div class="habit-meta">
            <span>Frequency: {{ habit.frequency }}</span>
            <span>Target: {{ habit.target_count }}</span>
            <span>Current streak: {{ habit.current_streak }}</span>
            <span>Best streak: {{ habit.best_streak }}</span>
          </div>

          <div class="habit-actions">
            <button type="button" @click="checkIn(habit, 'completed')">Check In</button>
            <button type="button" @click="checkIn(habit, 'missed')">Mark Missed</button>
            <button type="button" @click="openEditForm(habit)">Edit</button>
            <button class="danger" type="button" @click="deleteHabit(habit)">Delete</button>
          </div>
        </article>
      </div>
    </section>

    <section v-if="showForm" class="modal-backdrop" @click.self="closeForm">
      <form class="habit-form" @submit.prevent="submitForm">
        <div class="form-header">
          <h2>{{ editingHabit ? "Edit Habit" : "Create Habit" }}</h2>
          <button type="button" @click="closeForm">×</button>
        </div>

        <label>
          Name
          <input v-model.trim="form.name" type="text" placeholder="Example: Morning Walk" />
          <small v-if="validationErrors.name">{{ validationErrors.name[0] }}</small>
        </label>

        <label>
          Description
          <textarea v-model.trim="form.description" rows="3" placeholder="Describe the habit"></textarea>
        </label>

        <div class="form-grid">
          <label>
            Frequency
            <select v-model="form.frequency">
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
              <option value="monthly">Monthly</option>
            </select>
          </label>

          <label>
            Status
            <select v-model="form.status">
              <option value="active">Active</option>
              <option value="paused">Paused</option>
              <option value="archived">Archived</option>
            </select>
          </label>

          <label>
            Target Count
            <input v-model.number="form.target_count" type="number" min="1" max="100" />
          </label>

          <label>
            Priority
            <select v-model="form.priority">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="critical">Critical</option>
            </select>
          </label>
        </div>

        <label>
          Category
          <input v-model.trim="form.category" type="text" placeholder="Health, Study, Work..." />
        </label>

        <div class="form-actions">
          <button type="button" @click="closeForm">Cancel</button>
          <button class="primary-btn" type="submit" :disabled="saving">
            {{ saving ? "Saving..." : "Save Habit" }}
          </button>
        </div>
      </form>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import productivityService from "@/services/productivityService";

const habits = ref([]);
const dailyProgress = ref([]);
const loading = ref(false);
const saving = ref(false);
const showForm = ref(false);
const editingHabit = ref(null);
const errorMessage = ref("");
const validationErrors = ref({});

const filters = reactive({
  status: "",
});

const form = reactive({
  name: "",
  description: "",
  frequency: "daily",
  status: "active",
  target_count: 1,
  priority: "medium",
  category: "",
});

const weeklySummary = ref({
  total_habits: 0,
  active_habits: 0,
  completed_check_ins: 0,
  missed_check_ins: 0,
  completion_rate: 0,
});

const maxDailyTotal = computed(() => {
  return Math.max(...dailyProgress.value.map((day) => day.total || 0), 1);
});

function normalizeError(error) {
  validationErrors.value = error?.response?.data?.errors || {};
  errorMessage.value = error?.response?.data?.message || "Something went wrong. Please try again.";
}

async function loadHabits() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const params = {};
    if (filters.status) params.status = filters.status;

    const response = await productivityService.getHabits(params);
    habits.value = Array.isArray(response.data) ? response.data : response.data?.data || [];
  } catch (error) {
    normalizeError(error);
  } finally {
    loading.value = false;
  }
}

async function loadWeeklySummary() {
  try {
    const today = new Date();
    const endDate = today.toISOString().slice(0, 10);
    const start = new Date(today);
    start.setDate(today.getDate() - 6);
    const startDate = start.toISOString().slice(0, 10);

    const response = await productivityService.getHabitsWeeklySummary({
      start_date: startDate,
      end_date: endDate,
    });

    weeklySummary.value = response.data?.summary || weeklySummary.value;
    dailyProgress.value = response.data?.daily_progress || [];
  } catch (error) {
    normalizeError(error);
  }
}

function resetForm() {
  Object.assign(form, {
    name: "",
    description: "",
    frequency: "daily",
    status: "active",
    target_count: 1,
    priority: "medium",
    category: "",
  });
  validationErrors.value = {};
}

function openCreateForm() {
  editingHabit.value = null;
  resetForm();
  showForm.value = true;
}

function openEditForm(habit) {
  editingHabit.value = habit;
  Object.assign(form, {
    name: habit.name || habit.title || "",
    description: habit.description || "",
    frequency: habit.frequency || "daily",
    status: habit.status || "active",
    target_count: habit.target_count || 1,
    priority: habit.metadata?.priority || "medium",
    category: habit.metadata?.category || "",
  });
  validationErrors.value = {};
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  editingHabit.value = null;
}

async function submitForm() {
  saving.value = true;
  errorMessage.value = "";
  validationErrors.value = {};

  try {
    const payload = { ...form };

    if (editingHabit.value) {
      await productivityService.updateHabit(editingHabit.value.id, payload);
    } else {
      await productivityService.createHabit(payload);
    }

    closeForm();
    await Promise.all([loadHabits(), loadWeeklySummary()]);
  } catch (error) {
    normalizeError(error);
  } finally {
    saving.value = false;
  }
}

async function checkIn(habit, status) {
  errorMessage.value = "";

  try {
    const today = new Date().toISOString().slice(0, 10);
    await productivityService.checkInHabit(habit.id, {
      check_in_date: today,
      status,
      count: status === "completed" ? 1 : 0,
    });
    await Promise.all([loadHabits(), loadWeeklySummary()]);
  } catch (error) {
    normalizeError(error);
  }
}

async function deleteHabit(habit) {
  if (!window.confirm(`Delete habit: ${habit.name || habit.title}?`)) return;

  try {
    await productivityService.deleteHabit(habit.id);
    await Promise.all([loadHabits(), loadWeeklySummary()]);
  } catch (error) {
    normalizeError(error);
  }
}

function chartWidth(value) {
  return `${Math.round(((value || 0) / maxDailyTotal.value) * 100)}%`;
}

function formatShortDate(date) {
  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "2-digit",
  }).format(new Date(date));
}

onMounted(async () => {
  await Promise.all([loadHabits(), loadWeeklySummary()]);
});
</script>

<style scoped>
.habits-page {
  display: grid;
  gap: 1.5rem;
  padding: 1.5rem;
}

.page-header,
.panel-header,
.habit-card-header,
.form-header,
.form-actions,
.habit-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.eyebrow {
  margin: 0 0 0.25rem;
  color: #64748b;
  font-size: 0.8rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

h1,
h2,
h3,
p {
  margin: 0;
}

.subtitle,
.panel-header p,
.habit-card p {
  color: #64748b;
}

.primary-btn,
.habit-actions button,
.form-actions button {
  border: 0;
  border-radius: 0.75rem;
  cursor: pointer;
  font-weight: 700;
  padding: 0.7rem 1rem;
}

.primary-btn {
  background: #0f172a;
  color: white;
}

.summary-grid,
.habit-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.summary-card,
.panel,
.habit-card,
.habit-form {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 1rem;
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.06);
  padding: 1rem;
}

.summary-card span {
  color: #64748b;
  display: block;
}

.summary-card strong {
  display: block;
  font-size: 2rem;
  margin-top: 0.5rem;
}

.habit-card {
  display: grid;
  gap: 1rem;
}

.status-badge {
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 800;
  padding: 0.35rem 0.7rem;
  text-transform: capitalize;
}

.status-badge.active {
  background: #dcfce7;
  color: #166534;
}

.status-badge.paused {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.archived {
  background: #e2e8f0;
  color: #334155;
}

.habit-meta {
  color: #475569;
  display: grid;
  gap: 0.4rem;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
}

.habit-actions {
  flex-wrap: wrap;
  justify-content: flex-start;
}

.habit-actions button,
.form-actions button {
  background: #f1f5f9;
  color: #0f172a;
}

.habit-actions .danger {
  background: #fee2e2;
  color: #991b1b;
}

.alert.error {
  background: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 0.75rem;
  color: #991b1b;
  padding: 0.75rem 1rem;
}

.loading,
.empty-state,
.empty-mini {
  color: #64748b;
  padding: 2rem;
  text-align: center;
}

.progress-chart {
  display: grid;
  gap: 0.75rem;
  margin-top: 1rem;
}

.chart-row {
  align-items: center;
  display: grid;
  gap: 0.75rem;
  grid-template-columns: 90px 1fr 60px;
}

.bar-track {
  background: #e2e8f0;
  border-radius: 999px;
  display: flex;
  height: 12px;
  overflow: hidden;
}

.bar-completed {
  background: #22c55e;
}

.bar-missed {
  background: #ef4444;
}

.modal-backdrop {
  align-items: center;
  background: rgba(15, 23, 42, 0.45);
  display: flex;
  inset: 0;
  justify-content: center;
  padding: 1rem;
  position: fixed;
  z-index: 1000;
}

.habit-form {
  display: grid;
  gap: 1rem;
  max-width: 720px;
  width: 100%;
}

.habit-form label {
  color: #334155;
  display: grid;
  gap: 0.4rem;
  font-weight: 700;
}

.habit-form input,
.habit-form textarea,
.habit-form select,
.panel-header select {
  border: 1px solid #cbd5e1;
  border-radius: 0.75rem;
  padding: 0.7rem;
}

.habit-form small {
  color: #dc2626;
}

.form-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}
</style>
