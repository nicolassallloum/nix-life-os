<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1>Projects</h1>
        <p>Manage your personal, business, and technical projects from one place.</p>
      </div>
      <button class="primary-btn" @click="showCreateForm = !showCreateForm" :disabled="saving">
        {{ showCreateForm ? 'Close' : 'Create Project' }}
      </button>
    </div>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <form v-if="showCreateForm" class="content-card create-form" @submit.prevent="createProjectFromForm">
      <div class="section-header">
        <div>
          <h2>Create New Project</h2>
          <p>Enter project name and how many starter tasks you want to create.</p>
        </div>
      </div>

      <div class="form-grid">
        <label>
          Project Name
          <input v-model="form.project_name" type="text" placeholder="Example: Website Redesign" required />
        </label>

        <label>
          Number of Tasks
          <input v-model.number="form.number_of_tasks" type="number" min="0" max="100" placeholder="Example: 5" />
        </label>

        <label class="full">
          Description
          <textarea v-model="form.description" rows="3" placeholder="Optional project description"></textarea>
        </label>
      </div>

      <div class="actions form-actions">
        <button class="primary-btn" type="submit" :disabled="saving">
          {{ saving ? 'Creating...' : 'Save Project' }}
        </button>
        <button class="secondary-btn" type="button" @click="resetForm" :disabled="saving">Clear</button>
      </div>
    </form>

    <div class="cards-grid">
      <div class="summary-card">
        <h3>Total Projects</h3>
        <strong>{{ summary.total }}</strong>
        <span>Projects created</span>
      </div>

      <div class="summary-card">
        <h3>Active Projects</h3>
        <strong>{{ summary.active }}</strong>
        <span>Currently in progress</span>
      </div>

      <div class="summary-card">
        <h3>Completed</h3>
        <strong>{{ summary.completed }}</strong>
        <span>Finished projects</span>
      </div>

      <div class="summary-card">
        <h3>Average Progress</h3>
        <strong>{{ summary.averageProgress }}%</strong>
        <span>Across all projects</span>
      </div>
    </div>

    <div class="content-card">
      <div class="section-header">
        <div>
          <h2>Project Workspace</h2>
          <p>Track statuses, priorities, due dates, tasks, goals, and progress.</p>
        </div>
        <button class="secondary-btn" @click="loadProjects" :disabled="loading">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="empty-state">
        <h3>Loading projects...</h3>
      </div>

      <div v-else-if="projects.length === 0" class="empty-state">
        <h3>No projects yet</h3>
        <p>Create your first project to start tracking goals, tasks, and steps.</p>
      </div>

      <div v-else class="project-list">
        <article v-for="project in projects" :key="project.id" class="project-card">
          <div>
            <h3>{{ project.project_name || project.title || 'Untitled Project' }}</h3>
            <p>{{ project.description || 'No description provided.' }}</p>
          </div>

          <div class="meta-row">
            <span class="badge">{{ formatStatus(project.status) }}</span>
            <span class="badge priority">{{ formatStatus(project.priority) }}</span>
            <span class="muted">Due: {{ project.target_end_date || project.due_date || '—' }}</span>
          </div>

          <div class="progress-wrap">
            <div class="progress-label">
              <span>Progress</span>
              <strong>{{ Number(project.progress_percentage || project.progress_percent || 0).toFixed(0) }}%</strong>
            </div>
            <div class="progress-bar">
              <div :style="{ width: `${Math.min(100, Number(project.progress_percentage || 0))}%` }"></div>
            </div>
          </div>

          <div class="actions">
            <RouterLink class="small-btn" :to="`/projects/${project.id}`">Details</RouterLink>
            <RouterLink class="small-btn" :to="`/projects/${project.id}/tasks`">Tasks</RouterLink>
            <RouterLink class="small-btn" :to="`/projects/${project.id}/goals`">Goals</RouterLink>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { computed, onMounted, ref } from 'vue'
import { createProject, getProjects, normalizeList } from '@/services/projectService'

const projects = ref<any[]>([])
const loading = ref(false)
const saving = ref(false)
const showCreateForm = ref(false)
const errorMessage = ref('')

const form = ref({
  project_name: '',
  number_of_tasks: 0,
  description: '',
})

const summary = computed(() => {
  const total = projects.value.length
  const active = projects.value.filter((p) => ['not_started', 'in_progress', 'on_hold'].includes(p.status)).length
  const completed = projects.value.filter((p) => p.status === 'completed').length
  const averageProgress = total
    ? Math.round(projects.value.reduce((sum, p) => sum + Number(p.progress_percentage || 0), 0) / total)
    : 0

  return { total, active, completed, averageProgress }
})

function makeTimestamp() {
  return new Date()
    .toISOString()
    .slice(0, 19)
    .replaceAll('-', '')
    .replaceAll(':', '')
    .replaceAll('T', '')
}

function formatStatus(value: string) {
  return String(value || 'unknown').replaceAll('_', ' ')
}

async function loadProjects() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await getProjects({ per_page: 100 })
    projects.value = normalizeList(response)
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to load projects.'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.value = {
    project_name: '',
    number_of_tasks: 0,
    description: '',
  }
}

async function createProjectFromForm() {
  saving.value = true
  errorMessage.value = ''

  try {
    const stamp = makeTimestamp()
    await createProject({
      project_name: form.value.project_name,
      project_code: `NIX-${stamp}`,
      description: form.value.description || null,
      number_of_tasks: Number(form.value.number_of_tasks || 0),
      status: 'not_started',
      priority: 'medium',
      start_date: new Date().toISOString().slice(0, 10),
    })
    resetForm()
    showCreateForm.value = false
    await loadProjects()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to create project.'
  } finally {
    saving.value = false
  }
}

onMounted(loadProjects)
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 24px;
  color: #e5e7eb;
}

.page-header,
.section-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1,
.section-header h2,
.project-card h3 {
  margin: 0;
  color: #f8fafc;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 900;
}

.page-header p,
.section-header p,
.project-card p,
.summary-card span,
.muted {
  color: #94a3b8;
}

.primary-btn,
.secondary-btn,
.small-btn {
  border: none;
  text-decoration: none;
  padding: 11px 18px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: #ffffff;
}

.secondary-btn,
.small-btn {
  background: #1e293b;
  color: #e5e7eb;
  border: 1px solid #334155;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card,
.content-card,
.project-card {
  background: #0f172a;
  border: 1px solid #334155;
  border-radius: 18px;
  padding: 20px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.24);
}

.summary-card h3 {
  margin: 0 0 10px;
  color: #94a3b8;
  font-size: 14px;
}

.summary-card strong {
  display: block;
  font-size: 30px;
  color: #f8fafc;
}

.empty-state {
  margin-top: 20px;
  padding: 24px;
  border: 1px dashed #334155;
  border-radius: 16px;
  background: #111827;
  color: #94a3b8;
}

.project-list {
  display: grid;
  gap: 16px;
}

.meta-row,
.actions,
.progress-label {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
}

.badge {
  background: #312e81;
  color: #c7d2fe;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
  text-transform: capitalize;
}

.priority {
  background: #164e63;
  color: #a5f3fc;
}

.progress-wrap {
  margin: 16px 0;
}

.progress-label {
  justify-content: space-between;
  margin-bottom: 8px;
  color: #cbd5e1;
}

.progress-bar {
  height: 10px;
  background: #1e293b;
  border-radius: 999px;
  overflow: hidden;
}

.progress-bar div {
  height: 100%;
  background: #2563eb;
}

.alert.error {
  margin-bottom: 16px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #7f1d1d;
  color: #fee2e2;
  border: 1px solid #b91c1c;
}

.create-form {
  margin-bottom: 24px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(220px, 1fr));
  gap: 16px;
}

.form-grid label {
  display: grid;
  gap: 8px;
  color: #cbd5e1;
  font-weight: 800;
}

.form-grid input,
.form-grid textarea {
  width: 100%;
  border: 1px solid #334155;
  border-radius: 12px;
  padding: 11px 12px;
  color: #f8fafc;
  background: #111827;
}

.form-grid input::placeholder,
.form-grid textarea::placeholder {
  color: #64748b;
}

.form-grid .full {
  grid-column: 1 / -1;
}

.form-actions {
  justify-content: flex-start;
  margin-top: 16px;
}

@media (max-width: 900px) {
  .cards-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .page-header,
  .section-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 520px) {
  .cards-grid {
    grid-template-columns: 1fr;
  }
}
</style>
