<template>
  <section class="lab-tests-page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Health / Lab Tests</p>
        <h1>Lab Tests & Images</h1>
        <p class="subtitle">
          Upload blood tests, urine tests, and medical images. Results are saved only after your review and approval.
        </p>
      </div>

      <RouterLink class="primary-btn" to="/health/lab-tests/upload">
        Upload New Test
      </RouterLink>
    </div>

    <div class="filters-card">
      <label>
        Category
        <select v-model="filters.category_id" @change="loadLabTests">
          <option value="">All Categories</option>
          <option
            v-for="category in categories"
            :key="category.id || category.key || category.name"
            :value="category.id || category.key || category.name"
          >
            {{ category.name || category.key }}
          </option>
        </select>
      </label>

      <label>
        Status
        <select v-model="filters.ai_status" @change="loadLabTests">
          <option value="">All Statuses</option>
          <option value="uploaded">Uploaded</option>
          <option value="pending_review">Pending Review</option>
          <option value="approved">Approved</option>
        </select>
      </label>
    </div>

    <div v-if="loading" class="state-card">Loading lab tests...</div>
    <div v-else-if="error" class="state-card error">{{ error }}</div>

    <div v-else class="tests-grid">
      <article v-for="test in labTests" :key="test.id" class="test-card">
        <div class="card-top">
          <span class="badge">{{ getLabCategoryName(test) }}</span>
          <span class="status" :class="test.ai_status">{{ formatStatus(test.ai_status) }}</span>
        </div>

        <h2>{{ test.lab_name || 'Lab Test' }}</h2>

        <p class="meta">
          Date: {{ formatDate(test.test_date) }}
        </p>
        <p class="meta">
          Doctor: {{ test.doctor_name || 'Not specified' }}
        </p>

        <p v-if="test.notes" class="notes">{{ test.notes }}</p>

        <div class="result-summary">
          <strong>{{ test.results?.length || 0 }}</strong>
          approved result rows
        </div>

        <div class="actions">
          <RouterLink :to="`/health/lab-tests/${test.id}/preview`">
            Preview / Review
          </RouterLink>

          <button v-if="test.ai_status === 'uploaded'" type="button" @click="extract(test.id)">
            Start Review
          </button>
        </div>
      </article>

      <div v-if="labTests.length === 0" class="state-card">
        No lab tests uploaded yet.
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const loading = ref(false)
const error = ref('')
const labTests = ref<any[]>([])
const categories = ref<any[]>([])

const filters = reactive({
  category_id: '',
  ai_status: '',
})

function authHeaders() {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token') || ''
  return {
    Accept: 'application/json',
    Authorization: `Bearer ${token}`,
  }
}

function formatDate(value: string | null) {
  if (!value) return 'Not specified'
  return new Date(value).toLocaleDateString()
}

function formatStatus(value: string) {
  return String(value || 'uploaded').replaceAll('_', ' ')
}

function getLabCategoryName(test: any) {
  if (test?.category?.name) return test.category.name
  if (typeof test?.category === 'string' && test.category) return test.category
  if (test?.category_id) {
    const matched = categories.value.find((category: any) => {
      return String(category.id || category.key || category.name) === String(test.category_id)
    })
    return matched?.name || matched?.key || 'General'
  }
  return 'General'
}

async function loadCategories() {
  try {
    const response = await fetch(`${API_BASE_URL}/health/lab-tests/categories`, {
      headers: authHeaders(),
    })

    const payload = await response.json()

    if (response.ok && payload.success !== false) {
      categories.value = Array.isArray(payload.data) ? payload.data : []
    }
  } catch {
    categories.value = categories.value || []
  }
}

async function loadLabTests() {
  loading.value = true
  error.value = ''

  try {
    const params = new URLSearchParams()

    if (filters.category_id) params.set('category_id', filters.category_id)
    if (filters.ai_status) params.set('ai_status', filters.ai_status)

    const response = await fetch(`${API_BASE_URL}/health/lab-tests?${params.toString()}`, {
      headers: authHeaders(),
    })

    const payload = await response.json()

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Failed to load lab tests.')
    }

    labTests.value = payload.data?.data || payload.data || []
  } catch (err: any) {
    error.value = err.message || 'Failed to load lab tests.'
  } finally {
    loading.value = false
  }
}

async function extract(id: number) {
  error.value = ''

  try {
    const response = await fetch(`${API_BASE_URL}/health/lab-tests/${id}/extract`, {
      method: 'POST',
      headers: authHeaders(),
    })

    const payload = await response.json()

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Failed to start review.')
    }

    await loadLabTests()
  } catch (err: any) {
    error.value = err.message || 'Failed to start review.'
  }
}

onMounted(async () => {
  await loadCategories()
  await loadLabTests()
})
</script>

<style scoped>
.lab-tests-page {
  padding: 24px;
}

.page-header,
.filters-card,
.test-card,
.state-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 16px;
}

.eyebrow {
  color: #64748b;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin: 0 0 6px;
}

h1,
h2 {
  margin: 0;
  color: #0f172a;
}

.subtitle,
.meta,
.notes {
  color: #64748b;
}

.primary-btn,
.actions a,
.actions button {
  border: 0;
  background: #0f172a;
  color: #ffffff;
  padding: 10px 14px;
  border-radius: 12px;
  text-decoration: none;
  cursor: pointer;
  font-weight: 700;
}

.filters-card {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.filters-card label {
  display: grid;
  gap: 6px;
  font-weight: 700;
  color: #334155;
}

select {
  min-width: 180px;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px;
}

.tests-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
  gap: 16px;
}

.card-top,
.actions {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  align-items: center;
}

.badge,
.status {
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 800;
}

.badge {
  background: #e0f2fe;
  color: #075985;
}

.status {
  background: #f1f5f9;
  color: #334155;
  text-transform: capitalize;
}

.status.approved {
  background: #dcfce7;
  color: #166534;
}

.status.pending_review {
  background: #fef9c3;
  color: #854d0e;
}

.result-summary {
  margin: 16px 0;
  color: #475569;
}

.error {
  color: #b91c1c;
}
</style>
