<template>
  <div class="admin-point-page">
    <div class="page-header">
      <div>
        <h1>Admin Point Ideas</h1>
        <p>Create admin-only point tasks, targets, and level ideas.</p>
      </div>

      <button class="primary-btn" type="button" @click="resetForm">New Idea</button>
    </div>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <div class="cards-grid">
      <div v-for="level in levels" :key="level.level" class="level-card">
        <span>{{ level.label }}</span>
        <strong>{{ formatNumber(level.required_points) }}</strong>
      </div>
    </div>

    <section class="content-card">
      <div class="section-header">
        <div>
          <h2>{{ editingId ? 'Edit Point Idea' : 'Create Point Idea' }}</h2>
          <p>Write the task name, points used, target points, and level.</p>
        </div>
      </div>

      <form class="form-grid" @submit.prevent="saveIdea">
        <label>
          Task / Idea Name
          <input v-model.trim="form.name" type="text" placeholder="Example: Complete 10 project tasks" required />
        </label>

        <label>
          Points Used
          <input v-model.number="form.points" type="number" min="0" placeholder="Example: 250" />
        </label>

        <label>
          Target Points
          <input v-model.number="form.target_points" type="number" min="0" placeholder="Example: 50000" />
        </label>

        <label>
          Level
          <select v-model.number="form.level">
            <option :value="null">No Level</option>
            <option v-for="level in levels" :key="level.level" :value="level.level">
              {{ level.label }} — {{ formatNumber(level.required_points) }}
            </option>
          </select>
        </label>

        <label>
          Status
          <select v-model="form.status">
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </label>

        <label class="full">
          Description
          <textarea v-model.trim="form.description" rows="3" placeholder="Optional description"></textarea>
        </label>

        <div class="actions full">
          <button class="primary-btn" type="submit" :disabled="saving">
            {{ saving ? 'Saving...' : editingId ? 'Update Idea' : 'Create Idea' }}
          </button>

          <button class="secondary-btn" type="button" @click="resetForm" :disabled="saving">
            Clear
          </button>
        </div>
      </form>
    </section>

    <section class="content-card">
      <div class="section-header">
        <div>
          <h2>Ideas List</h2>
          <p>Only admin users can manage these ideas.</p>
        </div>

        <button class="secondary-btn" type="button" @click="loadData" :disabled="loading">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="empty-state">Loading point ideas...</div>
      <div v-else-if="ideas.length === 0" class="empty-state">No admin point ideas yet.</div>

      <div v-else class="ideas-list">
        <article v-for="idea in ideas" :key="idea.id" class="idea-card">
          <div>
            <h3>{{ idea.name }}</h3>
            <p>{{ idea.description || 'No description.' }}</p>
          </div>

          <div class="idea-meta">
            <span class="badge">Points: {{ formatNumber(idea.points) }}</span>
            <span class="badge">Target: {{ formatNumber(idea.target_points) }}</span>
            <span class="badge priority">Level {{ idea.level || '—' }}</span>
            <span class="badge status">{{ idea.status }}</span>
          </div>

          <div class="actions">
            <button class="small-btn" type="button" @click="editIdea(idea)">Edit</button>
            <button class="danger-btn" type="button" @click="removeIdea(idea.id)">Delete</button>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import adminManagementService from '@/services/adminManagementService'
import { normalizeList } from '@/services/projectService'

const levels = ref<any[]>([])
const ideas = ref<any[]>([])
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const editingId = ref('')

const form = ref({
  name: '',
  description: '',
  points: 0,
  target_points: null as number | null,
  level: null as number | null,
  status: 'active',
})

function formatNumber(value: any) {
  const numberValue = Number(value || 0)
  return numberValue.toLocaleString()
}

function resetForm() {
  editingId.value = ''
  form.value = {
    name: '',
    description: '',
    points: 0,
    target_points: null,
    level: null,
    status: 'active',
  }
}

function editIdea(idea: any) {
  editingId.value = idea.id
  form.value = {
    name: idea.name || '',
    description: idea.description || '',
    points: Number(idea.points || 0),
    target_points: idea.target_points === null || idea.target_points === undefined ? null : Number(idea.target_points),
    level: idea.level === null || idea.level === undefined ? null : Number(idea.level),
    status: idea.status || 'active',
  }
}

async function loadData() {
  loading.value = true
  errorMessage.value = ''

  try {
    const [levelsResponse, ideasResponse] = await Promise.all([
      adminManagementService.getPointLevels(),
      adminManagementService.getPointIdeas(),
    ])

    levels.value = normalizeList(levelsResponse)
    ideas.value = normalizeList(ideasResponse)
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to load admin point ideas.'
  } finally {
    loading.value = false
  }
}

async function saveIdea() {
  saving.value = true
  errorMessage.value = ''

  try {
    const payload = {
      name: form.value.name,
      description: form.value.description || null,
      points: Number(form.value.points || 0),
      target_points: form.value.target_points,
      level: form.value.level,
      status: form.value.status,
    }

    if (editingId.value) {
      await adminManagementService.updatePointIdea(editingId.value, payload)
    } else {
      await adminManagementService.createPointIdea(payload)
    }

    resetForm()
    await loadData()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to save admin point idea.'
  } finally {
    saving.value = false
  }
}

async function removeIdea(id: string) {
  if (!id) return
  if (!window.confirm('Delete this point idea?')) return

  errorMessage.value = ''

  try {
    await adminManagementService.deletePointIdea(id)
    await loadData()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to delete admin point idea.'
  }
}

onMounted(loadData)
</script>

<style scoped>
.admin-point-page {
  min-height: 100vh;
  padding: 24px;
  color: #e5e7eb;
}

.page-header,
.section-header,
.actions {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h1,
.section-header h2,
.idea-card h3 {
  margin: 0;
  color: #f8fafc;
}

.page-header p,
.section-header p,
.idea-card p {
  color: #94a3b8;
}

.primary-btn,
.secondary-btn,
.small-btn,
.danger-btn {
  border: none;
  padding: 10px 16px;
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

.danger-btn {
  background: #7f1d1d;
  color: #fee2e2;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(130px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}

.level-card,
.content-card,
.idea-card {
  background: #0f172a;
  border: 1px solid #334155;
  border-radius: 18px;
  padding: 18px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.24);
}

.level-card span {
  display: block;
  color: #94a3b8;
  font-weight: 800;
  margin-bottom: 6px;
}

.level-card strong {
  color: #f8fafc;
  font-size: 20px;
}

.content-card {
  margin-bottom: 20px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(220px, 1fr));
  gap: 16px;
  margin-top: 18px;
}

.form-grid label {
  display: grid;
  gap: 8px;
  color: #cbd5e1;
  font-weight: 800;
}

.form-grid .full {
  grid-column: 1 / -1;
}

.form-grid input,
.form-grid select,
.form-grid textarea {
  width: 100%;
  border: 1px solid #334155;
  border-radius: 12px;
  padding: 11px 12px;
  color: #f8fafc !important;
  background: #111827 !important;
}

.form-grid select option {
  color: #f8fafc !important;
  background: #111827 !important;
}

.ideas-list {
  display: grid;
  gap: 14px;
}

.idea-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 14px 0;
}

.badge {
  background: #312e81;
  color: #c7d2fe;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
}

.priority {
  background: #164e63;
  color: #a5f3fc;
}

.status {
  background: #14532d;
  color: #bbf7d0;
}

.empty-state {
  padding: 18px;
  border-radius: 14px;
  background: #111827;
  color: #94a3b8;
  border: 1px dashed #334155;
}

.alert.error {
  margin-bottom: 16px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #7f1d1d;
  color: #fee2e2;
  border: 1px solid #b91c1c;
}

@media (max-width: 900px) {
  .cards-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .page-header,
  .section-header,
  .actions {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
