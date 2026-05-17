<template>
  <main class="tasks-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Productivity</p>
        <h1>Tasks</h1>
        <p class="subtitle">
          Create, track, complete, reopen, and organize your personal tasks.
        </p>
      </div>

      <button class="primary-btn" @click="openCreateForm">
        + Add Task
      </button>
    </section>

    <section class="summary-grid">
      <div class="summary-card">
        <span>Total</span>
        <strong>{{ summary.total }}</strong>
      </div>
      <div class="summary-card">
        <span>Pending</span>
        <strong>{{ summary.pending }}</strong>
      </div>
      <div class="summary-card">
        <span>In Progress</span>
        <strong>{{ summary.in_progress }}</strong>
      </div>
      <div class="summary-card">
        <span>Completed</span>
        <strong>{{ summary.completed }}</strong>
      </div>
      <div class="summary-card danger">
        <span>Overdue</span>
        <strong>{{ summary.overdue }}</strong>
      </div>
    </section>

    <section class="filters-card">
      <div class="filter-group">
        <label>Status</label>
        <select v-model="filters.status" @change="fetchTasks">
          <option value="all">All</option>
          <option value="pending">Pending</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Priority</label>
        <select v-model="filters.priority" @change="fetchTasks">
          <option value="all">All</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>
      </div>

      <div class="filter-group search">
        <label>Search</label>
        <input
          v-model="filters.search"
          type="text"
          placeholder="Search tasks..."
          @keyup.enter="fetchTasks"
        />
      </div>

      <button class="secondary-btn" @click="fetchTasks">
        Apply
      </button>
    </section>

    <section v-if="errorMessage" class="alert error">
      {{ errorMessage }}
    </section>

    <section v-if="successMessage" class="alert success">
      {{ successMessage }}
    </section>

    <section v-if="showForm" class="form-card">
      <div class="form-header">
        <h2>{{ editingTask ? "Edit Task" : "Create Task" }}</h2>
        <button class="icon-btn" @click="closeForm">×</button>
      </div>

      <form @submit.prevent="submitTask">
        <div class="form-grid">
          <div class="form-group full">
            <label>Title</label>
            <input v-model="form.title" type="text" placeholder="Task title" />
            <small v-if="validationErrors.title">{{ validationErrors.title[0] }}</small>
          </div>

          <div class="form-group full">
            <label>Description</label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Task description"
            ></textarea>
            <small v-if="validationErrors.description">{{ validationErrors.description[0] }}</small>
          </div>

          <div class="form-group">
            <label>Status</label>
            <select v-model="form.status">
              <option value="pending">Pending</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
            </select>
            <small v-if="validationErrors.status">{{ validationErrors.status[0] }}</small>
          </div>

          <div class="form-group">
            <label>Priority</label>
            <select v-model="form.priority">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
            </select>
            <small v-if="validationErrors.priority">{{ validationErrors.priority[0] }}</small>
          </div>

          <div class="form-group">
            <label>Due Date</label>
            <input v-model="form.due_date" type="date" />
            <small v-if="validationErrors.due_date">{{ validationErrors.due_date[0] }}</small>
          </div>
        </div>

        <div class="form-actions">
          <button type="button" class="secondary-btn" @click="closeForm">
            Cancel
          </button>
          <button type="submit" class="primary-btn" :disabled="saving">
            {{ saving ? "Saving..." : editingTask ? "Update Task" : "Create Task" }}
          </button>
        </div>
      </form>
    </section>

    <section v-if="loading" class="loading-card">
      Loading tasks...
    </section>

    <section v-else-if="tasks.length === 0" class="empty-state">
      <h2>No tasks found</h2>
      <p>Create your first task or change the selected filters.</p>
      <button class="primary-btn" @click="openCreateForm">
        Create Task
      </button>
    </section>

    <section v-else class="tasks-list">
      <article
        v-for="task in tasks"
        :key="task.id"
        class="task-card"
        :class="{ completed: task.status === 'completed', overdue: task.is_overdue }"
      >
        <div class="task-main">
          <div class="task-title-row">
            <h3>{{ task.title }}</h3>
            <span v-if="task.is_overdue" class="badge overdue-badge">Overdue</span>
          </div>

          <p v-if="task.description" class="task-description">
            {{ task.description }}
          </p>

          <div class="badges">
            <span class="badge" :class="`status-${task.status}`">
              {{ formatStatus(task.status) }}
            </span>
            <span class="badge" :class="`priority-${task.priority}`">
              {{ formatPriority(task.priority) }}
            </span>
            <span v-if="task.due_date" class="badge date-badge">
              Due: {{ task.due_date }}
            </span>
          </div>
        </div>

        <div class="task-actions">
          <button
            v-if="task.status !== 'completed'"
            class="success-btn"
            @click="completeTask(task)"
          >
            Complete
          </button>

          <button
            v-if="task.status === 'completed'"
            class="secondary-btn"
            @click="reopenTask(task)"
          >
            Reopen
          </button>

          <button class="secondary-btn" @click="openEditForm(task)">
            Edit
          </button>

          <button class="danger-btn" @click="deleteTask(task)">
            Delete
          </button>
        </div>
      </article>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import { taskService } from "@/services/taskService";

const loading = ref(false);
const saving = ref(false);
const showForm = ref(false);
const editingTask = ref(null);
const tasks = ref([]);
const errorMessage = ref("");
const successMessage = ref("");
const validationErrors = ref({});

const filters = reactive({
  status: "all",
  priority: "all",
  search: "",
});

const form = reactive({
  title: "",
  description: "",
  status: "pending",
  priority: "medium",
  due_date: "",
});

const summary = computed(() => {
  return {
    total: tasks.value.length,
    pending: tasks.value.filter((task) => task.status === "pending").length,
    in_progress: tasks.value.filter((task) => task.status === "in_progress").length,
    completed: tasks.value.filter((task) => task.status === "completed").length,
    overdue: tasks.value.filter((task) => task.is_overdue).length,
  };
});

function resetMessages() {
  errorMessage.value = "";
  successMessage.value = "";
  validationErrors.value = {};
}

function resetForm() {
  form.title = "";
  form.description = "";
  form.status = "pending";
  form.priority = "medium";
  form.due_date = "";
  editingTask.value = null;
  validationErrors.value = {};
}

function openCreateForm() {
  resetMessages();
  resetForm();
  showForm.value = true;
}

function openEditForm(task) {
  resetMessages();
  editingTask.value = task;
  form.title = task.title || "";
  form.description = task.description || "";
  form.status = task.status || "pending";
  form.priority = task.priority || "medium";
  form.due_date = task.due_date || "";
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  resetForm();
}

async function fetchTasks() {
  loading.value = true;
  resetMessages();

  try {
    const response = await taskService.list(filters);
    tasks.value = Array.isArray(response.data) ? response.data : [];
  } catch (error) {
    errorMessage.value = error.message || "Failed to load tasks.";
  } finally {
    loading.value = false;
  }
}

async function submitTask() {
  saving.value = true;
  resetMessages();

  const payload = {
    title: form.title,
    description: form.description || null,
    status: form.status,
    priority: form.priority,
    due_date: form.due_date || null,
  };

  try {
    if (editingTask.value) {
      await taskService.update(editingTask.value.id, payload);
      successMessage.value = "Task updated successfully.";
    } else {
      await taskService.create(payload);
      successMessage.value = "Task created successfully.";
    }

    closeForm();
    await fetchTasks();
  } catch (error) {
    validationErrors.value = error.errors || {};
    errorMessage.value = error.message || "Failed to save task.";
  } finally {
    saving.value = false;
  }
}

async function completeTask(task) {
  resetMessages();

  try {
    await taskService.complete(task.id);
    successMessage.value = "Task completed successfully.";
    await fetchTasks();
  } catch (error) {
    errorMessage.value = error.message || "Failed to complete task.";
  }
}

async function reopenTask(task) {
  resetMessages();

  try {
    await taskService.reopen(task.id);
    successMessage.value = "Task reopened successfully.";
    await fetchTasks();
  } catch (error) {
    errorMessage.value = error.message || "Failed to reopen task.";
  }
}

async function deleteTask(task) {
  const confirmed = window.confirm(`Delete task "${task.title}"?`);

  if (!confirmed) {
    return;
  }

  resetMessages();

  try {
    await taskService.remove(task.id);
    successMessage.value = "Task deleted successfully.";
    await fetchTasks();
  } catch (error) {
    errorMessage.value = error.message || "Failed to delete task.";
  }
}

function formatStatus(status) {
  const labels = {
    pending: "Pending",
    in_progress: "In Progress",
    completed: "Completed",
  };

  return labels[status] || status;
}

function formatPriority(priority) {
  const labels = {
    low: "Low",
    medium: "Medium",
    high: "High",
  };

  return labels[priority] || priority;
}

onMounted(fetchTasks);
</script>

<style scoped>
.tasks-page {
  padding: 24px;
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.eyebrow {
  text-transform: uppercase;
  font-size: 12px;
  letter-spacing: 0.12em;
  color: #64748b;
  margin: 0 0 6px;
}

h1 {
  margin: 0;
  font-size: 32px;
  color: #0f172a;
}

.subtitle {
  margin: 8px 0 0;
  color: #64748b;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.summary-card,
.filters-card,
.form-card,
.loading-card,
.empty-state,
.task-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.06);
}

.summary-card {
  padding: 18px;
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 14px;
}

.summary-card strong {
  display: block;
  margin-top: 8px;
  font-size: 28px;
  color: #0f172a;
}

.summary-card.danger strong {
  color: #dc2626;
}

.filters-card {
  padding: 18px;
  display: grid;
  grid-template-columns: 180px 180px 1fr auto;
  gap: 14px;
  align-items: end;
  margin-bottom: 20px;
}

.filter-group,
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 10px 12px;
  font-size: 14px;
  outline: none;
}

input:focus,
select:focus,
textarea:focus {
  border-color: #2563eb;
}

.form-card {
  padding: 20px;
  margin-bottom: 20px;
}

.form-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.form-header h2 {
  margin: 0;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.form-group.full {
  grid-column: 1 / -1;
}

small {
  color: #dc2626;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 18px;
}

.primary-btn,
.secondary-btn,
.success-btn,
.danger-btn,
.icon-btn {
  border: 0;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 700;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: white;
}

.secondary-btn {
  background: #e2e8f0;
  color: #0f172a;
}

.success-btn {
  background: #16a34a;
  color: white;
}

.danger-btn {
  background: #dc2626;
  color: white;
}

.icon-btn {
  background: #f1f5f9;
  color: #0f172a;
  font-size: 20px;
  line-height: 1;
}

.alert {
  padding: 14px 16px;
  border-radius: 14px;
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

.loading-card,
.empty-state {
  padding: 32px;
  text-align: center;
}

.empty-state h2 {
  margin: 0 0 8px;
}

.tasks-list {
  display: grid;
  gap: 14px;
}

.task-card {
  padding: 18px;
  display: flex;
  justify-content: space-between;
  gap: 18px;
}

.task-card.completed {
  opacity: 0.75;
}

.task-card.overdue {
  border-color: #fecaca;
}

.task-main {
  flex: 1;
}

.task-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.task-title-row h3 {
  margin: 0;
  color: #0f172a;
}

.task-description {
  margin: 8px 0 12px;
  color: #64748b;
}

.badges {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.badge {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
  background: #f1f5f9;
  color: #334155;
}

.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-in_progress {
  background: #dbeafe;
  color: #1d4ed8;
}

.status-completed {
  background: #dcfce7;
  color: #166534;
}

.priority-high,
.overdue-badge {
  background: #fee2e2;
  color: #991b1b;
}

.priority-medium {
  background: #fef3c7;
  color: #92400e;
}

.priority-low {
  background: #dcfce7;
  color: #166534;
}

.date-badge {
  background: #eef2ff;
  color: #3730a3;
}

.task-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-content: flex-start;
  justify-content: flex-end;
}

@media (max-width: 900px) {
  .page-header,
  .task-card {
    flex-direction: column;
  }

  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filters-card {
    grid-template-columns: 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
