<template>
  <main class="goals-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Productivity</p>
        <h1>Goals</h1>
        <p class="subtitle">
          Create goals, update progress, track target dates, and link goals with tasks or habits.
        </p>
      </div>

      <button class="primary-btn" type="button" @click="openCreateForm">
        + Add Goal
      </button>
    </section>

    <section v-if="errorMessage" class="alert error">
      {{ errorMessage }}
    </section>

    <section v-if="successMessage" class="alert success">
      {{ successMessage }}
    </section>

    <section class="summary-grid">
      <article class="summary-card">
        <span>Total Goals</span>
        <strong>{{ summary.total }}</strong>
      </article>

      <article class="summary-card">
        <span>Active</span>
        <strong>{{ summary.active }}</strong>
      </article>

      <article class="summary-card">
        <span>Completed</span>
        <strong>{{ summary.completed }}</strong>
      </article>

      <article class="summary-card danger">
        <span>Overdue</span>
        <strong>{{ summary.overdue }}</strong>
      </article>

      <article class="summary-card">
        <span>Average Progress</span>
        <strong>{{ summary.averageProgress }}%</strong>
      </article>
    </section>

    <section class="filters-card">
      <label>
        Status
        <select v-model="filters.status" @change="loadGoals">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="completed">Completed</option>
          <option value="on_hold">On Hold</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </label>

      <label>
        Priority
        <select v-model="filters.priority" @change="loadGoals">
          <option value="">All Priorities</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
          <option value="critical">Critical</option>
        </select>
      </label>

      <label>
        Search
        <input
          v-model.trim="filters.search"
          type="text"
          placeholder="Search goals..."
          @keyup.enter="loadGoals"
        />
      </label>

      <button class="secondary-btn" type="button" @click="loadGoals">
        Apply
      </button>
    </section>

    <section v-if="showForm" class="form-card">
      <div class="form-header">
        <h2>{{ editingGoal ? "Edit Goal" : "Create Goal" }}</h2>
        <button class="icon-btn" type="button" @click="closeForm">×</button>
      </div>

      <form @submit.prevent="submitGoal">
        <div class="form-grid">
          <label class="full">
            Title
            <input v-model.trim="form.title" type="text" placeholder="Goal title" />
            <small v-if="validationErrors.title">{{ validationErrors.title[0] }}</small>
          </label>

          <label class="full">
            Description
            <textarea
              v-model.trim="form.description"
              rows="3"
              placeholder="Goal description"
            ></textarea>
            <small v-if="validationErrors.description">{{ validationErrors.description[0] }}</small>
          </label>

          <label>
            Status
            <select v-model="form.status">
              <option value="active">Active</option>
              <option value="completed">Completed</option>
              <option value="on_hold">On Hold</option>
              <option value="cancelled">Cancelled</option>
            </select>
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

          <label>
            Category
            <input v-model.trim="form.category" type="text" placeholder="Project, health, finance..." />
          </label>

          <label>
            Progress %
            <input v-model.number="form.progress_percentage" type="number" min="0" max="100" step="1" />
            <small v-if="validationErrors.progress_percentage">
              {{ validationErrors.progress_percentage[0] }}
            </small>
          </label>

          <label>
            Target Date
            <input v-model="form.target_date" type="date" />
            <small v-if="validationErrors.target_date">{{ validationErrors.target_date[0] }}</small>
          </label>
        </div>

        <div class="form-actions">
          <button class="secondary-btn" type="button" @click="closeForm">
            Cancel
          </button>

          <button class="primary-btn" type="submit" :disabled="saving">
            {{ saving ? "Saving..." : editingGoal ? "Update Goal" : "Create Goal" }}
          </button>
        </div>
      </form>
    </section>

    <section v-if="loading" class="loading-card">
      Loading goals...
    </section>

    <section v-else-if="goals.length === 0" class="empty-state">
      <h2>No goals found</h2>
      <p>Create your first goal to start tracking progress and target dates.</p>
      <button class="primary-btn" type="button" @click="openCreateForm">
        Create Goal
      </button>
    </section>

    <section v-else class="goals-list">
      <article
        v-for="goal in goals"
        :key="goal.id"
        class="goal-card"
        :class="{
          completed: goal.status === 'completed',
          overdue: goal.is_overdue,
        }"
      >
        <div class="goal-card-header">
          <div>
            <h3>{{ goal.title }}</h3>
            <p v-if="goal.description">{{ goal.description }}</p>
            <p v-else class="muted">No description</p>
          </div>

          <span :class="['status-badge', goal.status]">
            {{ formatStatus(goal.status) }}
          </span>
        </div>

        <div class="progress-block">
          <div class="progress-top">
            <span>Progress</span>
            <strong>{{ Number(goal.progress_percentage || 0).toFixed(0) }}%</strong>
          </div>

          <div class="progress-track">
            <div
              class="progress-fill"
              :style="{ width: `${Math.min(Number(goal.progress_percentage || 0), 100)}%` }"
            ></div>
          </div>
        </div>

        <div class="goal-meta">
          <span :class="['priority-badge', goal.priority]">
            Priority: {{ formatPriority(goal.priority) }}
          </span>

          <span v-if="goal.category">
            Category: {{ goal.category }}
          </span>

          <span v-if="goal.target_date" :class="{ dangerText: goal.is_overdue }">
            Target: {{ formatDate(goal.target_date) }}
          </span>

          <span v-if="goal.is_overdue" class="dangerText">
            Overdue
          </span>

          <span>
            Linked Tasks: {{ linkedTaskCount(goal) }}
          </span>

          <span>
            Linked Habits: {{ linkedHabitCount(goal) }}
          </span>
        </div>

        <div class="quick-progress">
          <label>
            Update Progress
            <input
              v-model.number="progressDrafts[goal.id]"
              type="number"
              min="0"
              max="100"
              step="1"
            />
          </label>

          <button class="secondary-btn" type="button" @click="updateProgress(goal)">
            Save Progress
          </button>

          <button class="secondary-btn" type="button" @click="recalculateProgress(goal)">
            Recalculate
          </button>
        </div>

        <div class="link-grid">
          <label>
            Link Task ID
            <input
              v-model.trim="linkForms[goal.id].task_id"
              type="text"
              placeholder="Paste productivity task UUID"
            />
          </label>

          <button class="secondary-btn" type="button" @click="linkTask(goal)">
            Link Task
          </button>

          <label>
            Link Habit ID
            <input
              v-model.trim="linkForms[goal.id].habit_id"
              type="text"
              placeholder="Paste productivity habit UUID"
            />
          </label>

          <button class="secondary-btn" type="button" @click="linkHabit(goal)">
            Link Habit
          </button>
        </div>

        <div class="goal-actions">
          <button
            v-if="goal.status !== 'completed'"
            class="success-btn"
            type="button"
            @click="completeGoal(goal)"
          >
            Mark Completed
          </button>

          <button
            v-if="goal.status === 'completed'"
            class="secondary-btn"
            type="button"
            @click="reopenGoal(goal)"
          >
            Reopen
          </button>

          <button class="secondary-btn" type="button" @click="openEditForm(goal)">
            Edit
          </button>

          <button class="danger-btn" type="button" @click="deleteGoal(goal)">
            Delete
          </button>
        </div>
      </article>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import productivityService from "@/services/productivityService";

const goals = ref([]);
const loading = ref(false);
const saving = ref(false);
const showForm = ref(false);
const editingGoal = ref(null);
const errorMessage = ref("");
const successMessage = ref("");
const validationErrors = ref({});
const progressDrafts = reactive({});
const linkForms = reactive({});

const filters = reactive({
  status: "",
  priority: "",
  search: "",
});

const form = reactive({
  title: "",
  description: "",
  status: "active",
  category: "",
  priority: "medium",
  progress_percentage: 0,
  target_date: "",
});

const summary = computed(() => {
  const total = goals.value.length;
  const completed = goals.value.filter((goal) => goal.status === "completed").length;
  const active = goals.value.filter((goal) => goal.status === "active").length;
  const overdue = goals.value.filter((goal) => goal.is_overdue).length;

  const averageProgress =
    total === 0
      ? 0
      : Math.round(
          goals.value.reduce((sum, goal) => sum + Number(goal.progress_percentage || 0), 0) / total
        );

  return {
    total,
    active,
    completed,
    overdue,
    averageProgress,
  };
});

function resetMessages() {
  errorMessage.value = "";
  successMessage.value = "";
  validationErrors.value = {};
}

function normalizeError(error, fallback = "Something went wrong.") {
  validationErrors.value = error?.response?.data?.errors || {};
  errorMessage.value = error?.response?.data?.message || error?.message || fallback;
}

function resetForm() {
  Object.assign(form, {
    title: "",
    description: "",
    status: "active",
    category: "",
    priority: "medium",
    progress_percentage: 0,
    target_date: "",
  });

  editingGoal.value = null;
  validationErrors.value = {};
}

function openCreateForm() {
  resetMessages();
  resetForm();
  showForm.value = true;
}

function openEditForm(goal) {
  resetMessages();
  editingGoal.value = goal;

  Object.assign(form, {
    title: goal.title || "",
    description: goal.description || "",
    status: goal.status || "active",
    category: goal.category || "",
    priority: goal.priority || "medium",
    progress_percentage: Number(goal.progress_percentage || 0),
    target_date: goal.target_date || "",
  });

  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  resetForm();
}

function prepareGoalState(goal) {
  if (!Object.prototype.hasOwnProperty.call(progressDrafts, goal.id)) {
    progressDrafts[goal.id] = Number(goal.progress_percentage || 0);
  } else {
    progressDrafts[goal.id] = Number(goal.progress_percentage || 0);
  }

  if (!linkForms[goal.id]) {
    linkForms[goal.id] = {
      task_id: "",
      habit_id: "",
    };
  }
}

async function loadGoals() {
  loading.value = true;
  resetMessages();

  try {
    const params = {};

    if (filters.status) params.status = filters.status;
    if (filters.priority) params.priority = filters.priority;
    if (filters.search) params.search = filters.search;

    const response = await productivityService.getGoals(params);
    goals.value = Array.isArray(response.data) ? response.data : [];

    goals.value.forEach(prepareGoalState);
  } catch (error) {
    normalizeError(error, "Failed to load goals.");
  } finally {
    loading.value = false;
  }
}

async function submitGoal() {
  saving.value = true;
  resetMessages();

  const payload = {
    title: form.title,
    description: form.description || null,
    status: form.status,
    category: form.category || null,
    priority: form.priority,
    progress_percentage: Number(form.progress_percentage || 0),
    target_date: form.target_date || null,
  };

  try {
    if (editingGoal.value) {
      await productivityService.updateGoal(editingGoal.value.id, payload);
      successMessage.value = "Goal updated successfully.";
    } else {
      await productivityService.createGoal(payload);
      successMessage.value = "Goal created successfully.";
    }

    closeForm();
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to save goal.");
  } finally {
    saving.value = false;
  }
}

async function updateProgress(goal) {
  resetMessages();

  try {
    await productivityService.updateGoalProgress(goal.id, {
      progress_percentage: Number(progressDrafts[goal.id] || 0),
    });

    successMessage.value = "Goal progress updated successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to update goal progress.");
  }
}

async function completeGoal(goal) {
  resetMessages();

  try {
    await productivityService.completeGoal(goal.id);
    successMessage.value = "Goal marked as completed.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to complete goal.");
  }
}

async function reopenGoal(goal) {
  resetMessages();

  try {
    await productivityService.reopenGoal(goal.id);
    successMessage.value = "Goal reopened successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to reopen goal.");
  }
}

async function recalculateProgress(goal) {
  resetMessages();

  try {
    await productivityService.recalculateGoalProgress(goal.id);
    successMessage.value = "Goal progress recalculated successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to recalculate progress.");
  }
}

async function linkTask(goal) {
  resetMessages();

  const taskId = linkForms[goal.id]?.task_id;

  if (!taskId) {
    errorMessage.value = "Please enter a task ID.";
    return;
  }

  try {
    await productivityService.linkGoalTask(goal.id, taskId);
    linkForms[goal.id].task_id = "";
    successMessage.value = "Task linked successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to link task.");
  }
}

async function linkHabit(goal) {
  resetMessages();

  const habitId = linkForms[goal.id]?.habit_id;

  if (!habitId) {
    errorMessage.value = "Please enter a habit ID.";
    return;
  }

  try {
    await productivityService.linkGoalHabit(goal.id, habitId);
    linkForms[goal.id].habit_id = "";
    successMessage.value = "Habit linked successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to link habit.");
  }
}

async function deleteGoal(goal) {
  const confirmed = window.confirm(`Delete goal "${goal.title}"?`);

  if (!confirmed) {
    return;
  }

  resetMessages();

  try {
    await productivityService.deleteGoal(goal.id);
    successMessage.value = "Goal deleted successfully.";
    await loadGoals();
  } catch (error) {
    normalizeError(error, "Failed to delete goal.");
  }
}

function linkedTaskCount(goal) {
  return goal.metadata?.linked_task_ids?.length || 0;
}

function linkedHabitCount(goal) {
  return goal.metadata?.linked_habit_ids?.length || 0;
}

function formatStatus(status) {
  const labels = {
    active: "Active",
    completed: "Completed",
    on_hold: "On Hold",
    cancelled: "Cancelled",
  };

  return labels[status] || status;
}

function formatPriority(priority) {
  const labels = {
    low: "Low",
    medium: "Medium",
    high: "High",
    critical: "Critical",
  };

  return labels[priority] || priority;
}

function formatDate(value) {
  if (!value) return "-";

  return new Intl.DateTimeFormat("en", {
    year: "numeric",
    month: "short",
    day: "2-digit",
  }).format(new Date(value));
}

onMounted(loadGoals);
</script>

<style scoped>
.goals-page {
  display: grid;
  gap: 1.5rem;
  padding: 1.5rem;
}

.page-header,
.form-header,
.form-actions,
.goal-card-header,
.goal-actions,
.quick-progress,
.link-grid {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.eyebrow {
  margin: 0 0 0.25rem;
  color: #64748b;
  font-size: 0.8rem;
  font-weight: 800;
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
.muted,
.goal-card p {
  color: #64748b;
}

.primary-btn,
.secondary-btn,
.success-btn,
.danger-btn,
.icon-btn {
  border: 0;
  border-radius: 0.75rem;
  cursor: pointer;
  font-weight: 800;
  padding: 0.7rem 1rem;
}

.primary-btn {
  background: #0f172a;
  color: #ffffff;
}

.secondary-btn {
  background: #e2e8f0;
  color: #0f172a;
}

.success-btn {
  background: #16a34a;
  color: #ffffff;
}

.danger-btn {
  background: #dc2626;
  color: #ffffff;
}

.icon-btn {
  background: #f1f5f9;
  color: #0f172a;
  font-size: 1.25rem;
  line-height: 1;
}

.summary-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(5, minmax(0, 1fr));
}

.summary-card,
.filters-card,
.form-card,
.loading-card,
.empty-state,
.goal-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 1.1rem;
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.06);
}

.summary-card {
  padding: 1rem;
}

.summary-card span {
  color: #64748b;
  display: block;
}

.summary-card strong {
  color: #0f172a;
  display: block;
  font-size: 2rem;
  margin-top: 0.5rem;
}

.summary-card.danger strong,
.dangerText {
  color: #dc2626;
}

.filters-card {
  align-items: end;
  display: grid;
  gap: 1rem;
  grid-template-columns: 180px 180px 1fr auto;
  padding: 1rem;
}

.form-card {
  padding: 1.25rem;
}

.form-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.full {
  grid-column: 1 / -1;
}

label {
  color: #334155;
  display: grid;
  gap: 0.4rem;
  font-size: 0.9rem;
  font-weight: 800;
}

input,
select,
textarea {
  border: 1px solid #cbd5e1;
  border-radius: 0.75rem;
  font-size: 0.95rem;
  outline: none;
  padding: 0.7rem;
  width: 100%;
}

input:focus,
select:focus,
textarea:focus {
  border-color: #2563eb;
}

small {
  color: #dc2626;
}

.alert {
  border-radius: 0.85rem;
  font-weight: 800;
  padding: 0.85rem 1rem;
}

.alert.error {
  background: #fee2e2;
  border: 1px solid #fecaca;
  color: #991b1b;
}

.alert.success {
  background: #dcfce7;
  border: 1px solid #bbf7d0;
  color: #166534;
}

.loading-card,
.empty-state {
  padding: 2rem;
  text-align: center;
}

.empty-state {
  display: grid;
  gap: 0.75rem;
  justify-items: center;
}

.goals-list {
  display: grid;
  gap: 1rem;
}

.goal-card {
  display: grid;
  gap: 1rem;
  padding: 1.25rem;
}

.goal-card.completed {
  opacity: 0.75;
}

.goal-card.overdue {
  border-color: #fecaca;
}

.status-badge,
.priority-badge,
.goal-meta span {
  border-radius: 999px;
  display: inline-flex;
  font-size: 0.8rem;
  font-weight: 800;
  padding: 0.4rem 0.7rem;
}

.status-badge {
  text-transform: capitalize;
}

.status-badge.active {
  background: #dbeafe;
  color: #1d4ed8;
}

.status-badge.completed {
  background: #dcfce7;
  color: #166534;
}

.status-badge.on_hold {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.cancelled {
  background: #e2e8f0;
  color: #334155;
}

.priority-badge.low {
  background: #dcfce7;
  color: #166534;
}

.priority-badge.medium {
  background: #fef3c7;
  color: #92400e;
}

.priority-badge.high,
.priority-badge.critical {
  background: #fee2e2;
  color: #991b1b;
}

.progress-block {
  display: grid;
  gap: 0.5rem;
}

.progress-top {
  align-items: center;
  display: flex;
  justify-content: space-between;
}

.progress-track {
  background: #e2e8f0;
  border-radius: 999px;
  height: 12px;
  overflow: hidden;
}

.progress-fill {
  background: #0f172a;
  border-radius: 999px;
  height: 100%;
}

.goal-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.goal-meta span {
  background: #f8fafc;
  color: #334155;
}

.quick-progress {
  align-items: end;
  flex-wrap: wrap;
  justify-content: flex-start;
}

.quick-progress label {
  max-width: 180px;
}

.link-grid {
  align-items: end;
  display: grid;
  grid-template-columns: 1fr auto 1fr auto;
}

.goal-actions {
  flex-wrap: wrap;
  justify-content: flex-end;
}

@media (max-width: 1100px) {
  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filters-card,
  .link-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 760px) {
  .page-header,
  .goal-card-header,
  .goal-actions {
    align-items: flex-start;
    flex-direction: column;
  }

  .summary-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .full {
    grid-column: auto;
  }
}
</style>
