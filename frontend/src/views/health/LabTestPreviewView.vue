<template>
  <section class="preview-page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Health / Lab Tests</p>
        <h1>Review Lab Test Results</h1>
        <p class="subtitle">
          Edit the extracted/manual values. Final rows are saved only after clicking Approve & Save.
        </p>
      </div>

      <RouterLink to="/health/lab-tests">Back to Lab Tests</RouterLink>
    </div>

    <div v-if="loading" class="state-card">Loading preview...</div>
    <div v-else-if="error" class="state-card error">{{ error }}</div>

    <div v-else class="preview-grid">
      <div class="file-card">
        <h2>Uploaded File</h2>

        <div v-if="previewError" class="preview-fallback">
          {{ previewError }}
        </div>

        <iframe
          v-if="isPdf && previewUrl"
          class="file-frame"
          :src="previewUrl"
          title="Lab test PDF preview"
        ></iframe>

        <img
          v-else-if="previewUrl"
          class="image-preview"
          :src="previewUrl"
          alt="Lab test image preview"
        />

        <div v-else class="preview-fallback">
          Loading uploaded file preview...
        </div>
      </div>

      <div class="review-card lab-preview-card">
        <div class="review-header">
          <div>
            <h2>Review Values</h2>
            <p>Status: {{ labTest?.ai_status }}</p>
          </div>

          <button type="button" @click="addRow">Add Row</button>
        </div>

        <div v-for="(row, index) in results" :key="index" class="result-row">
          <label>
            Test Name
            <input v-model="row.test_name" type="text" placeholder="Creatinine" />
          </label>

          <label>
            Result Value
            <input v-model="row.result_value" type="number" step="0.0001" />
          </label>

          <label>
            Unit
            <input v-model="row.unit" type="text" placeholder="mg/dL" />
          </label>

          <label>
            Ref Min
            <input v-model="row.reference_min" type="number" step="0.0001" />
          </label>

          <label>
            Ref Max
            <input v-model="row.reference_max" type="number" step="0.0001" />
          </label>

          <label>
            Ref Text
            <input v-model="row.reference_text" type="text" placeholder="0.7 - 1.3" />
          </label>

          <label>
            Status
            <select v-model="row.status">
              <option value="normal">Normal</option>
              <option value="low">Low</option>
              <option value="high">High</option>
              <option value="critical">Critical</option>
              <option value="pending_review">Pending Review</option>
            </select>
          </label>

          <label>
            Result Date
            <input v-model="row.result_date" type="date" />
          </label>

          <button class="remove-btn" type="button" @click="removeRow(index)">
            Remove
          </button>
        </div>

        <div v-if="saveMessage" class="message success">{{ saveMessage }}</div>
        <div v-if="saveError" class="message error">{{ saveError }}</div>

        <button class="approve-btn" type="button" :disabled="saving" @click="approve">
          {{ saving ? 'Saving...' : 'Approve & Save Final Results' }}
        </button>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const loading = ref(false)
const saving = ref(false)
const error = ref('')
const saveError = ref('')
const saveMessage = ref('')
const labTest = ref<any>(null)
const results = ref<any[]>([])

const labTestId = computed(() => route.params.id)
const previewApiUrl = computed(() => `${API_BASE_URL}/health/lab-tests/${labTestId.value}/preview`)
const previewUrl = ref('')
const previewError = ref('')
const isPdf = computed(() => String(labTest.value?.file_type || '').includes('pdf'))

function authHeaders(json = false) {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token') || ''
  const headers: Record<string, string> = {
    Accept: 'application/json',
    Authorization: `Bearer ${token}`,
  }

  if (json) headers['Content-Type'] = 'application/json'

  return headers
}

function emptyRow() {
  return {
    test_name: '',
    result_value: null,
    unit: '',
    reference_min: null,
    reference_max: null,
    reference_text: '',
    status: 'pending_review',
    result_date: new Date().toISOString().slice(0, 10),
    doctor_name: labTest.value?.doctor_name || '',
    ai_confidence: 0,
  }
}


function authPreviewHeaders() {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token') || ''
  return {
    Accept: 'application/pdf,image/*,*/*',
    Authorization: `Bearer ${token}`,
  }
}

function isBadPlaceholderRow(row: any) {
  const name = String(row?.test_name || '').trim()

  if (!name) return false

  const compactName = name.replace(/\s+/g, '')
  const hasLongNumberPrefix = /^\d{5,}/.test(compactName)
  const containsPatientNameShape = /[A-Z][a-z]+[_\s-][A-Z][a-z]+/.test(name)
  const hasNoUsefulResult =
    String(row?.result_value ?? '') === '0' &&
    !String(row?.unit || '').trim() &&
    !String(row?.reference_text || '').trim()

  return hasNoUsefulResult && (hasLongNumberPrefix || containsPatientNameShape || compactName.length > 28)
}

function normalizeResultRows(rows: any[]) {
  const source = String(labTest.value?.extracted_payload?.source || '')

  if (source === 'manual_placeholder') {
    return [emptyRow()]
  }

  const cleanedRows = (Array.isArray(rows) ? rows : [])
    .filter((row: any) => !isBadPlaceholderRow(row))
    .map((row: any) => ({
      ...emptyRow(),
      ...row,
      test_name: String(row?.test_name || '').trim(),
      unit: String(row?.unit || '').trim(),
      reference_text: String(row?.reference_text || '').trim(),
      status: row?.status || 'pending_review',
      result_date: row?.result_date || new Date().toISOString().slice(0, 10),
      doctor_name: row?.doctor_name || labTest.value?.doctor_name || '',
      ai_confidence: row?.ai_confidence || 0,
    }))

  return cleanedRows.length ? cleanedRows : [emptyRow()]
}

async function loadPreviewFile() {
  previewError.value = ''

  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
    previewUrl.value = ''
  }

  try {
    const response = await fetch(previewApiUrl.value, {
      headers: authPreviewHeaders(),
    })

    if (!response.ok) {
      throw new Error('Unable to load uploaded file preview.')
    }

    const blob = await response.blob()
    previewUrl.value = URL.createObjectURL(blob)
  } catch (err: any) {
    previewError.value = err.message || 'Unable to load uploaded file preview.'
  }
}

function addRow() {
  results.value.push(emptyRow())
}

function removeRow(index: number) {
  results.value.splice(index, 1)
}

async function loadLabTest() {
  loading.value = true
  error.value = ''

  try {
    const response = await fetch(`${API_BASE_URL}/health/lab-tests`, {
      headers: authHeaders(),
    })

    const payload = await response.json()

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Failed to load lab tests.')
    }

    const list = payload.data?.data || payload.data || []
    labTest.value = list.find((item: any) => String(item.id) === String(labTestId.value))

    if (!labTest.value) {
      throw new Error('Lab test not found.')
    }

    const draftRows = labTest.value.extracted_payload?.results || []
    const approvedRows = labTest.value.results || []

    results.value = normalizeResultRows(draftRows.length ? draftRows : approvedRows)
  } catch (err: any) {
    error.value = err.message || 'Failed to load preview.'
  } finally {
    loading.value = false
  }
}

async function approve() {
  saveError.value = ''
  saveMessage.value = ''

  const cleaned = results.value.filter(row => String(row.test_name || '').trim() !== '')

  if (cleaned.length === 0) {
    saveError.value = 'Please add at least one result row with a test name.'
    return
  }

  saving.value = true

  try {
    const response = await fetch(`${API_BASE_URL}/health/lab-tests/${labTestId.value}/approve`, {
      method: 'POST',
      headers: authHeaders(true),
      body: JSON.stringify({ results: cleaned }),
    })

    const payload = await response.json()

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Failed to approve results.')
    }

    saveMessage.value = 'Final results saved successfully.'
    setTimeout(() => router.push('/health/lab-tests'), 700)
  } catch (err: any) {
    saveError.value = err.message || 'Failed to approve results.'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await loadLabTest()
  await loadPreviewFile()
})

onUnmounted(() => {
  if (previewUrl.value) {
    URL.revokeObjectURL(previewUrl.value)
  }
})
</script>

<style scoped>
.preview-page {
  padding: 24px;
}

.page-header,
.file-card,
.review-card,
.state-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 16px;
}

.eyebrow {
  color: #64748b;
  font-weight: 800;
  text-transform: uppercase;
  margin: 0 0 6px;
}

.subtitle {
  color: #64748b;
}

.preview-grid {
  display: grid;
  grid-template-columns: minmax(320px, 1fr) minmax(420px, 1.3fr);
  gap: 16px;
}

.file-frame {
  width: 100%;
  min-height: 720px;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
}

.image-preview {
  width: 100%;
  border-radius: 14px;
  border: 1px solid #e5e7eb;
}

.preview-fallback {
  border: 1px dashed #cbd5e1;
  background: #f8fafc;
  color: #334155;
  border-radius: 14px;
  padding: 18px;
  font-weight: 800;
}

.review-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.result-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 14px;
  margin-top: 14px;
}

label {
  display: grid;
  gap: 6px;
  color: #334155;
  font-weight: 700;
}

input,
select {
  color: #0f172a;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px;
}

button {
  border: 0;
  background: #0f172a;
  color: #ffffff;
  padding: 10px 14px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

.remove-btn {
  background: #991b1b;
}

.approve-btn {
  margin-top: 16px;
  width: 100%;
}

.message {
  padding: 12px;
  border-radius: 12px;
  margin-top: 12px;
}

.error {
  background: #fee2e2;
  color: #991b1b;
}

.success {
  background: #dcfce7;
  color: #166534;
}

@media (max-width: 980px) {
  .preview-grid {
    grid-template-columns: 1fr;
  }
}

/* Phase 13E: component-level lab preview input readability */
.lab-preview-card input,
.lab-preview-card textarea,
.lab-preview-card select,
.lab-preview-card input:disabled,
.lab-preview-card textarea:disabled,
.lab-preview-card select:disabled,
.lab-preview-card input[readonly],
.lab-preview-card textarea[readonly],
.lab-preview-card select[readonly] {
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  opacity: 1 !important;
  background-color: #ffffff !important;
}

.lab-preview-card input::placeholder,
.lab-preview-card textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

.lab-preview-card input::selection,
.lab-preview-card textarea::selection,
.lab-preview-card select::selection {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
  background-color: #2563eb !important;
}

.lab-preview-card input::-moz-selection,
.lab-preview-card textarea::-moz-selection,
.lab-preview-card select::-moz-selection {
  color: #ffffff !important;
  background-color: #2563eb !important;
}

</style>
