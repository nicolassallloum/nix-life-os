<template>
  <main class="happy-wins-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Productivity</p>
        <h1>Happy Wins</h1>
        <p class="subtitle">
          Log small wins, positive moments, and productivity victories to keep motivation visible.
        </p>
      </div>

      <button class="primary-btn" type="button" @click="openCreateForm">
        + Add Happy Win
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
        <span>Total Wins</span>
        <strong>{{ summary.total }}</strong>
      </article>

      <article class="summary-card">
        <span>This Week</span>
        <strong>{{ summary.thisWeek }}</strong>
      </article>

      <article class="summary-card">
        <span>Total Score</span>
        <strong>{{ summary.totalScore }}</strong>
      </article>

      <article class="summary-card">
        <span>Average Score</span>
        <strong>{{ summary.averageScore }}</strong>
      </article>
    </section>

    <section class="filters-card">
      <label>
        Mood
        <input v-model.trim="filters.mood" type="text" placeholder="productive, happy, grateful..." />
      </label>

      <label>
        Search
        <input
          v-model.trim="filters.search"
          type="text"
          placeholder="Search wins..."
          @keyup.enter="loadHappyWins"
        />
      </label>

      <button class="secondary-btn" type="button" @click="loadHappyWins">
        Apply
      </button>

      <button class="ghost-btn" type="button" @click="resetFilters">
        Reset
      </button>
    </section>

    <section v-if="showForm" class="form-card">
      <div class="form-header">
        <h2>{{ editingWin ? "Edit Happy Win" : "Create Happy Win" }}</h2>
        <button class="icon-btn" type="button" @click="closeForm">×</button>
      </div>

      <form @submit.prevent="submitHappyWin">
        <div class="form-grid">
          <label class="full">
            Title
            <input v-model.trim="form.title" type="text" placeholder="What went well?" />
            <small v-if="validationErrors.title">{{ validationErrors.title[0] }}</small>
          </label>

          <label class="full">
            Description
            <textarea
              v-model.trim="form.description"
              rows="3"
              placeholder="Add details about this win..."
            ></textarea>
          </label>

          <label>
            Win Date
            <input v-model="form.win_date" type="date" />
          </label>

          <label>
            Mood
            <input v-model.trim="form.mood" type="text" placeholder="productive" />
          </label>

          <label>
            Score
            <input v-model.number="form.score" type="number" min="1" max="10" step="1" />
            <small v-if="validationErrors.score">{{ validationErrors.score[0] }}</small>
          </label>
        </div>

        <div class="form-actions">
          <button class="secondary-btn" type="button" @click="closeForm">
            Cancel
          </button>

          <button class="primary-btn" type="submit" :disabled="saving">
            {{ saving ? "Saving..." : editingWin ? "Update Win" : "Create Win" }}
          </button>
        </div>
      </form>
    </section>

    <section v-if="loading" class="loading-card">
      Loading happy wins...
    </section>

    <section v-else-if="happyWins.length === 0" class="empty-state">
      <h2>No happy wins yet</h2>
      <p>Create your first Happy Win to start building a positive productivity history.</p>
      <button class="primary-btn" type="button" @click="openCreateForm">
        Create Happy Win
      </button>
    </section>

    <section v-else class="wins-list">
      <article v-for="win in happyWins" :key="win.id" class="win-card">
        <div class="win-header">
          <div>
            <h3>{{ win.title }}</h3>
            <p v-if="win.description">{{ win.description }}</p>
            <p v-else class="muted">No description</p>
          </div>

          <span class="score-badge">{{ win.score }}/10</span>
        </div>

        <div class="win-meta">
          <span>Date: {{ formatDate(win.win_date) }}</span>
          <span v-if="win.mood">Mood: {{ win.mood }}</span>
        </div>

        <div class="win-actions">
          <button class="secondary-btn" type="button" @click="openEditForm(win)">
            Edit
          </button>

          <button class="danger-btn" type="button" @click="deleteHappyWin(win)">
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

const happyWins = ref([]);
const loading = ref(false);
const saving = ref(false);
const showForm = ref(false);
const editingWin = ref(null);
const errorMessage = ref("");
const successMessage = ref("");
const validationErrors = ref({});

const filters = reactive({
  mood: "",
  search: "",
});

const form = reactive({
  title: "",
  description: "",
  win_date: new Date().toISOString().slice(0, 10),
  mood: "productive",
  score: 5,
});

const summary = computed(() => {
  const wins = happyWins.value;
  const now = new Date();
  const day = now.getDay() || 7;
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - day + 1);
  weekStart.setHours(0, 0, 0, 0);

  const totalScore = wins.reduce((sum, win) => sum + Number(win.score || 0), 0);
  const thisWeek = wins.filter((win) => {
    if (!win.win_date) return false;
    return new Date(win.win_date) >= weekStart;
  }).length;

  return {
    total: wins.length,
    thisWeek,
    totalScore,
    averageScore: wins.length ? (totalScore / wins.length).toFixed(1) : "0.0",
  };
});

async function loadHappyWins() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const params = {};
    if (filters.mood) params.mood = filters.mood;
    if (filters.search) params.search = filters.search;

    const response = await productivityService.getHappyWins(params);
    happyWins.value = Array.isArray(response?.data) ? response.data : [];
  } catch (error) {
    errorMessage.value = error.response?.data?.message || error.message || "Unable to load Happy Wins.";
  } finally {
    loading.value = false;
  }
}

function resetForm() {
  editingWin.value = null;
  validationErrors.value = {};
  form.title = "";
  form.description = "";
  form.win_date = new Date().toISOString().slice(0, 10);
  form.mood = "productive";
  form.score = 5;
}

function openCreateForm() {
  resetForm();
  showForm.value = true;
}

function openEditForm(win) {
  editingWin.value = win;
  validationErrors.value = {};
  form.title = win.title || "";
  form.description = win.description || "";
  form.win_date = normalizeDate(win.win_date);
  form.mood = win.mood || "";
  form.score = Number(win.score || 1);
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  resetForm();
}

async function submitHappyWin() {
  saving.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  validationErrors.value = {};

  const payload = {
    title: form.title,
    description: form.description || null,
    win_date: form.win_date,
    mood: form.mood || null,
    score: Number(form.score || 1),
  };

  try {
    if (editingWin.value) {
      await productivityService.updateHappyWin(editingWin.value.id, payload);
      successMessage.value = "Happy Win updated successfully.";
    } else {
      await productivityService.createHappyWin(payload);
      successMessage.value = "Happy Win created successfully.";
    }

    closeForm();
    await loadHappyWins();
  } catch (error) {
    validationErrors.value = error.response?.data?.errors || {};
    errorMessage.value = error.response?.data?.message || error.message || "Unable to save Happy Win.";
  } finally {
    saving.value = false;
  }
}

async function deleteHappyWin(win) {
  if (!window.confirm(`Delete happy win "${win.title}"?`)) {
    return;
  }

  errorMessage.value = "";
  successMessage.value = "";

  try {
    await productivityService.deleteHappyWin(win.id);
    successMessage.value = "Happy Win deleted successfully.";
    await loadHappyWins();
  } catch (error) {
    errorMessage.value = error.response?.data?.message || error.message || "Unable to delete Happy Win.";
  }
}

function resetFilters() {
  filters.mood = "";
  filters.search = "";
  loadHappyWins();
}

function normalizeDate(value) {
  if (!value) return new Date().toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function formatDate(value) {
  if (!value) return "-";
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
  }).format(new Date(value));
}

onMounted(loadHappyWins);
</script>

<style scoped>
.happy-wins-page {
  display: grid;
  gap: 22px;
  padding: 24px;
}

.page-header,
.form-header,
.win-header,
.win-actions,
.form-actions {
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
.form-header h2,
.empty-state h2 {
  margin: 0;
  color: #111827;
}

.subtitle,
.muted,
.win-card p,
.empty-state p {
  color: #6b7280;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(150px, 1fr));
  gap: 14px;
}

.summary-card,
.filters-card,
.form-card,
.loading-card,
.empty-state,
.win-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 18px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.summary-card span {
  color: #6b7280;
  font-size: 13px;
  font-weight: 700;
}

.summary-card strong {
  display: block;
  margin-top: 8px;
  font-size: 30px;
  color: #111827;
}

.filters-card,
.form-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(160px, 1fr));
  gap: 14px;
  align-items: end;
}

.form-grid .full {
  grid-column: 1 / -1;
}

label {
  display: grid;
  gap: 6px;
  color: #374151;
  font-weight: 700;
  font-size: 13px;
}

input,
textarea {
  width: 100%;
  border: 1px solid #d1d5db;
  border-radius: 12px;
  padding: 10px 12px;
  font: inherit;
}

textarea {
  resize: vertical;
}

small {
  color: #dc2626;
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

.alert.success {
  background: #ecfdf5;
  color: #047857;
}

.primary-btn,
.secondary-btn,
.ghost-btn,
.danger-btn,
.icon-btn {
  border: none;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 800;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: white;
}

.secondary-btn {
  background: #eef2ff;
  color: #3730a3;
}

.ghost-btn {
  background: #f8fafc;
  color: #334155;
}

.danger-btn {
  background: #fee2e2;
  color: #991b1b;
}

.icon-btn {
  background: #f3f4f6;
  color: #111827;
}

.wins-list {
  display: grid;
  gap: 14px;
}

.score-badge {
  white-space: nowrap;
  border-radius: 999px;
  background: #fef3c7;
  color: #92400e;
  padding: 8px 12px;
  font-weight: 900;
}

.win-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin: 12px 0;
  color: #475569;
  font-size: 13px;
  font-weight: 700;
}

@media (max-width: 900px) {
  .summary-grid,
  .filters-card,
  .form-grid {
    grid-template-columns: 1fr 1fr;
  }

  .page-header,
  .win-header,
  .win-actions,
  .form-actions {
    flex-direction: column;
  }
}

@media (max-width: 560px) {
  .summary-grid,
  .filters-card,
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
