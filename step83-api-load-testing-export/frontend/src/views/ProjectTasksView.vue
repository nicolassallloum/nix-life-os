<script setup>
import { computed, onMounted, reactive, ref } from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const projects = ref([]);
const tasks = ref([]);
const selectedProjectId = ref("");

const filters = reactive({
  search: "",
  status: "",
  priority: "",
  overdue: false,
});

const form = reactive({
  id: null,
  task_title: "",
  task_description: "",
  status: "todo",
  priority: "medium",
  task_order: 1,
  start_date: "",
  due_date: "",
  progress_percentage: 0,
});

const statusOptions = [
  { value: "todo", label: "Todo" },
  { value: "in_progress", label: "In Progress" },
  { value: "blocked", label: "Blocked" },
  { value: "completed", label: "Completed" },
  { value: "cancelled", label: "Cancelled" },
];

const priorityOptions = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const selectedProject = computed(() => {
  return projects.value.find((project) => project.id === selectedProjectId.value) || null;
});

const taskStats = computed(() => {
  const total = tasks.value.length;
  const completed = tasks.value.filter((task) => task.status === "completed").length;
  const overdue = tasks.value.filter((task) => task.is_overdue).length;
  const highPriority = tasks.value.filter((task) =>
    ["high", "critical"].includes(task.priority)
  ).length;

  return {
    total,
    completed,
    overdue,
    highPriority,
  };
});

function getToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

async function apiRequest(path, options = {}) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message =
      data.message ||
      Object.values(data.errors || {})
        .flat()
        .join(" ") ||
      "Request failed.";

    throw new Error(message);
  }

  return data;
}

function resetMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function resetForm() {
  form.id = null;
  form.task_title = "";
  form.task_description = "";
  form.status = "todo";
  form.priority = "medium";
  form.task_order = tasks.value.length + 1;
  form.start_date = "";
  form.due_date = "";
  form.progress_percentage = 0;
}

function formatDate(date) {
  if (!date) return "Not set";

  return new Date(date).toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "2-digit",
  });
}

function cleanLabel(value) {
  if (!value) return "-";

  return String(value)
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function statusClass(status) {
  return {
    todo: "badge-gray",
    in_progress: "badge-blue",
    blocked: "badge-yellow",
    completed: "badge-green",
    cancelled: "badge-red",
  }[status] || "badge-gray";
}

function priorityClass(priority) {
  return {
    low: "badge-gray",
    medium: "badge-blue",
    high: "badge-orange",
    critical: "badge-red",
  }[priority] || "badge-gray";
}

async function loadProjects() {
  loading.value = true;
  resetMessages();

  try {
    const response = await apiRequest("/projects?per_page=100");
    projects.value = response.data || [];

    if (!selectedProjectId.value && projects.value.length > 0) {
      selectedProjectId.value = projects.value[0].id;
      await loadTasks();
    }
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function loadTasks() {
  if (!selectedProjectId.value) {
    tasks.value = [];
    return;
  }

  loading.value = true;
  resetMessages();

  try {
    const params = new URLSearchParams();

    if (filters.search) params.append("search", filters.search);
    if (filters.status) params.append("status", filters.status);
    if (filters.priority) params.append("priority", filters.priority);
    if (filters.overdue) params.append("overdue", "1");

    params.append("per_page", "100");

    const response = await apiRequest(
      `/projects/${selectedProjectId.value}/tasks?${params.toString()}`
    );

    tasks.value = response.data || [];
    resetForm();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
}

async function saveTask() {
  if (!selectedProjectId.value) {
    errorMessage.value = "Please select a project first.";
    return;
  }

  saving.value = true;
  resetMessages();

  const payload = {
    task_title: form.task_title,
    task_description: form.task_description || null,
    status: form.status,
    priority: form.priority,
    task_order: Number(form.task_order || 1),
    start_date: form.start_date || null,
    due_date: form.due_date || null,
    progress_percentage: Number(form.progress_percentage || 0),
  };

  try {
    if (form.id) {
      await apiRequest(`/projects/${selectedProjectId.value}/tasks/${form.id}`, {
        method: "PUT",
        body: JSON.stringify(payload),
      });

      successMessage.value = "Task updated successfully.";
    } else {
      await apiRequest(`/projects/${selectedProjectId.value}/tasks`, {
        method: "POST",
        body: JSON.stringify(payload),
      });

      successMessage.value = "Task created successfully.";
    }

    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  } finally {
    saving.value = false;
  }
}

function editTask(task) {
  form.id = task.id;
  form.task_title = task.task_title || "";
  form.task_description = task.task_description || "";
  form.status = task.status || "todo";
  form.priority = task.priority || "medium";
  form.task_order = task.task_order || 1;
  form.start_date = task.start_date || "";
  form.due_date = task.due_date || "";
  form.progress_percentage = Number(task.progress_percentage || 0);

  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
}

async function changeTaskStatus(task, status) {
  resetMessages();

  try {
    await apiRequest(`/projects/${selectedProjectId.value}/tasks/${task.id}`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    });

    successMessage.value = "Task status updated successfully.";
    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  }
}

async function deleteTask(task) {
  const confirmed = window.confirm(`Delete task: ${task.task_title}?`);

  if (!confirmed) return;

  resetMessages();

  try {
    await apiRequest(`/projects/${selectedProjectId.value}/tasks/${task.id}`, {
      method: "DELETE",
    });

    successMessage.value = "Task deleted successfully.";
    await loadTasks();
  } catch (error) {
    errorMessage.value = error.message;
  }
}

onMounted(loadProjects);
</script>

<template>
  <section class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Projects Module</p>
        <h1>Project Tasks</h1>
        <p class="subtitle">
          Create, edit, delete, assign, prioritize, and track project tasks.
        </p>
      </div>

      <button class="btn-secondary" type="button" @click="loadProjects">
        Refresh
      </button>
    </div>

    <div v-if="errorMessage" class="alert alert-error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <div class="grid two-cols">
      <div class="card">
        <h2>{{ form.id ? "Edit Task" : "Create Task" }}</h2>

        <div class="form-grid">
          <label>
            Project
            <select v-model="selectedProjectId" @change="loadTasks">
              <option disabled value="">Select project</option>
              <option v-for="project in projects" :key="project.id" :value="project.id">
                {{ project.project_name }}
              </option>
            </select>
          </label>

          <label>
            Task Title
            <input v-model="form.task_title" type="text" placeholder="Enter task title" />
          </label>

          <label class="full">
            Description
            <textarea
              v-model="form.task_description"
              rows="3"
              placeholder="Enter task description"
            ></textarea>
          </label>

          <label>
            Status
            <select v-model="form.status">
              <option
                v-for="status in statusOptions"
                :key="status.value"
                :value="status.value"
              >
                {{ status.label }}
              </option>
            </select>
          </label>

          <label>
            Priority
            <select v-model="form.priority">
              <option
                v-for="priority in priorityOptions"
                :key="priority.value"
                :value="priority.value"
              >
                {{ priority.label }}
              </option>
            </select>
          </label>

          <label>
            Start Date
            <input v-model="form.start_date" type="date" />
          </label>

          <label>
            Due Date
            <input v-model="form.due_date" type="date" />
          </label>

          <label>
            Order
            <input v-model="form.task_order" type="number" min="1" />
          </label>

          <label>
            Progress %
            <input v-model="form.progress_percentage" type="number" min="0" max="100" />
          </label>
        </div>

        <div class="actions">
          <button class="btn-primary" type="button" :disabled="saving" @click="saveTask">
            {{ saving ? "Saving..." : form.id ? "Update Task" : "Create Task" }}
          </button>

          <button class="btn-secondary" type="button" @click="resetForm">
            Clear
          </button>
        </div>
      </div>

      <div class="card">
        <h2>Task Summary</h2>

        <div class="stats-grid">
          <div class="stat">
            <span>Total Tasks</span>
            <strong>{{ taskStats.total }}</strong>
          </div>

          <div class="stat">
            <span>Completed</span>
            <strong>{{ taskStats.completed }}</strong>
          </div>

          <div class="stat">
            <span>Overdue</span>
            <strong>{{ taskStats.overdue }}</strong>
          </div>

          <div class="stat">
            <span>High Priority</span>
            <strong>{{ taskStats.highPriority }}</strong>
          </div>
        </div>

        <div v-if="selectedProject" class="selected-project">
          <strong>Selected Project:</strong>
          <span>{{ selectedProject.project_name }}</span>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="list-header">
        <div>
          <h2>Task List</h2>
          <p>Filter by search, status, priority, and overdue tasks.</p>
        </div>
      </div>

      <div class="filters">
        <input
          v-model="filters.search"
          type="text"
          placeholder="Search task title or description"
          @keyup.enter="loadTasks"
        />

        <select v-model="filters.status" @change="loadTasks">
          <option value="">All Statuses</option>
          <option v-for="status in statusOptions" :key="status.value" :value="status.value">
            {{ status.label }}
          </option>
        </select>

        <select v-model="filters.priority" @change="loadTasks">
          <option value="">All Priorities</option>
          <option
            v-for="priority in priorityOptions"
            :key="priority.value"
            :value="priority.value"
          >
            {{ priority.label }}
          </option>
        </select>

        <label class="checkbox">
          <input v-model="filters.overdue" type="checkbox" @change="loadTasks" />
          Overdue only
        </label>

        <button class="btn-secondary" type="button" @click="loadTasks">
          Apply
        </button>
      </div>

      <div v-if="loading" class="empty">
        Loading project tasks...
      </div>

      <div v-else-if="!selectedProjectId" class="empty">
        No project selected. Please select or create a project first.
      </div>

      <div v-else-if="tasks.length === 0" class="empty">
        No tasks found for this project.
      </div>

      <div v-else class="task-list">
        <article
          v-for="task in tasks"
          :key="task.id"
          class="task-card"
          :class="{ overdue: task.is_overdue }"
        >
          <div class="task-main">
            <div>
              <h3>{{ task.task_title }}</h3>
              <p>{{ task.task_description || "No description available." }}</p>
            </div>

            <div class="badges">
              <span class="badge" :class="statusClass(task.status)">
                {{ cleanLabel(task.status) }}
              </span>

              <span class="badge" :class="priorityClass(task.priority)">
                {{ cleanLabel(task.priority) }}
              </span>

              <span v-if="task.is_overdue" class="badge badge-red">
                Overdue
              </span>
            </div>
          </div>

          <div class="task-meta">
            <span>Start: {{ formatDate(task.start_date) }}</span>
            <span>Due: {{ formatDate(task.due_date) }}</span>
            <span>Progress: {{ task.progress_percentage }}%</span>
            <span>Order: {{ task.task_order }}</span>
          </div>

          <div class="progress-track">
            <div
              class="progress-bar"
              :style="{ width: `${Number(task.progress_percentage || 0)}%` }"
            ></div>
          </div>

          <div class="task-actions">
            <button type="button" @click="editTask(task)">Edit</button>
            <button type="button" @click="changeTaskStatus(task, 'todo')">Todo</button>
            <button type="button" @click="changeTaskStatus(task, 'in_progress')">
              In Progress
            </button>
            <button type="button" @click="changeTaskStatus(task, 'completed')">
              Complete
            </button>
            <button class="danger" type="button" @click="deleteTask(task)">
              Delete
            </button>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.eyebrow {
  margin: 0 0 6px;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
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

h2 {
  color: #0f172a;
  font-size: 20px;
  font-weight: 800;
  margin-bottom: 16px;
}

h3 {
  color: #0f172a;
  font-size: 17px;
  font-weight: 800;
}

.subtitle {
  margin-top: 8px;
  color: #64748b;
}

.grid.two-cols {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 20px;
}

.card {
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  background: #ffffff;
  padding: 22px;
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.06);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.form-grid .full {
  grid-column: 1 / -1;
}

label {
  display: flex;
  flex-direction: column;
  gap: 7px;
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 10px 12px;
  color: #0f172a;
  font-size: 14px;
  outline: none;
}

input:focus,
select:focus,
textarea:focus {
  border-color: #0f172a;
}

.actions,
.task-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 18px;
}

button {
  cursor: pointer;
  border: 0;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 800;
}

.btn-primary {
  background: #0f172a;
  color: white;
}

.btn-secondary,
.task-actions button {
  background: #f1f5f9;
  color: #0f172a;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.task-actions .danger {
  background: #fee2e2;
  color: #b91c1c;
}

.alert {
  border-radius: 14px;
  padding: 14px 16px;
  font-weight: 700;
}

.alert-error {
  background: #fee2e2;
  color: #991b1b;
}

.alert-success {
  background: #dcfce7;
  color: #166534;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.stat {
  border-radius: 16px;
  background: #f8fafc;
  padding: 16px;
}

.stat span {
  display: block;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.stat strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 28px;
  font-weight: 900;
}

.selected-project {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 18px;
  border-radius: 16px;
  background: #f8fafc;
  padding: 16px;
}

.selected-project span {
  color: #475569;
}

.list-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.list-header p {
  color: #64748b;
}

.filters {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto auto;
  gap: 12px;
  margin: 18px 0;
}

.checkbox {
  flex-direction: row;
  align-items: center;
  white-space: nowrap;
}

.checkbox input {
  width: auto;
}

.empty {
  border: 1px dashed #cbd5e1;
  border-radius: 16px;
  color: #64748b;
  padding: 28px;
  text-align: center;
}

.task-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.task-card {
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  padding: 18px;
  background: #ffffff;
}

.task-card.overdue {
  border-color: #fecaca;
  background: #fff7f7;
}

.task-main {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}

.task-main p {
  margin-top: 6px;
  color: #64748b;
}

.badges {
  display: flex;
  flex-wrap: wrap;
  align-content: flex-start;
  justify-content: flex-end;
  gap: 8px;
}

.badge {
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 900;
}

.badge-gray {
  background: #f1f5f9;
  color: #475569;
}

.badge-blue {
  background: #dbeafe;
  color: #1d4ed8;
}

.badge-yellow {
  background: #fef3c7;
  color: #92400e;
}

.badge-green {
  background: #dcfce7;
  color: #166534;
}

.badge-orange {
  background: #ffedd5;
  color: #c2410c;
}

.badge-red {
  background: #fee2e2;
  color: #b91c1c;
}

.task-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  margin-top: 14px;
  color: #475569;
  font-size: 13px;
  font-weight: 700;
}

.progress-track {
  height: 10px;
  overflow: hidden;
  border-radius: 999px;
  background: #e2e8f0;
  margin-top: 14px;
}

.progress-bar {
  height: 100%;
  border-radius: 999px;
  background: #0f172a;
  transition: width 0.2s ease;
}

@media (max-width: 1100px) {
  .grid.two-cols,
  .filters {
    grid-template-columns: 1fr;
  }

  .task-main {
    flex-direction: column;
  }

  .badges {
    justify-content: flex-start;
  }
}
</style>
