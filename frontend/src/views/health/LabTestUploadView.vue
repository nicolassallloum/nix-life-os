<template>
  <section class="upload-page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Health / Lab Tests</p>
        <h1>Upload Lab Test or Image</h1>
        <p class="subtitle">
          Upload PDF, JPG, PNG, or WEBP files. Results will stay pending until you approve them.
        </p>
      </div>

      <RouterLink to="/health/lab-tests">Back to Lab Tests</RouterLink>
    </div>

    <form class="upload-card" @submit.prevent="submitUpload">
      <label>
        Category
        <select v-model="form.category_id">
          <option value="">Select Category</option>
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
        Test Date
        <input v-model="form.test_date" type="date" />
      </label>

      <label>
        Lab Name
        <input v-model="form.lab_name" type="text" placeholder="Example: ABC Lab" />
      </label>

      <label>
        Doctor Name
        <input v-model="form.doctor_name" type="text" placeholder="Optional" />
      </label>

      <label>
        Notes
        <textarea v-model="form.notes" rows="4" placeholder="Optional notes"></textarea>
      </label>

      <label>
        File
        <input type="file" accept=".pdf,image/jpeg,image/png,image/webp" @change="handleFile" />
      </label>

      <div v-if="error" class="message error">{{ error }}</div>
      <div v-if="success" class="message success">{{ success }}</div>

      <button type="submit" :disabled="saving">
        {{ saving ? 'Uploading...' : 'Upload & Continue to Review' }}
      </button>
    </form>
  </section>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const categories = ref<any[]>([])
const selectedFile = ref<File | null>(null)
const saving = ref(false)
const error = ref('')
const success = ref('')

const form = reactive({
  category_id: '',
  test_date: new Date().toISOString().slice(0, 10),
  lab_name: '',
  doctor_name: '',
  notes: '',
})

function authHeaders() {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token') || ''
  return {
    Accept: 'application/json',
    Authorization: `Bearer ${token}`,
  }
}

function handleFile(event: Event) {
  const input = event.target as HTMLInputElement
  selectedFile.value = input.files?.[0] || null
}

async function loadCategories() {
  try {
    const response = await fetch(`${API_BASE_URL}/health/lab-tests/categories`, {
      headers: authHeaders(),
    })

    const payload = await response.json()
    categories.value = Array.isArray(payload.data) ? payload.data : []
  } catch {
    categories.value = []
  }
}

async function submitUpload() {
  error.value = ''
  success.value = ''

  if (!selectedFile.value) {
    error.value = 'Please select a PDF or image file.'
    return
  }

  saving.value = true

  try {
    const body = new FormData()
    if (form.category_id) body.append('category_id', form.category_id)
    if (form.test_date) body.append('test_date', form.test_date)
    if (form.lab_name) body.append('lab_name', form.lab_name)
    if (form.doctor_name) body.append('doctor_name', form.doctor_name)
    if (form.notes) body.append('notes', form.notes)
    body.append('file', selectedFile.value)

    const response = await fetch(`${API_BASE_URL}/health/lab-tests/upload`, {
      method: 'POST',
      headers: authHeaders(),
      body,
    })

    const payload = await response.json()

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Upload failed.')
    }

    const id = payload.data.id

    await fetch(`${API_BASE_URL}/health/lab-tests/${id}/extract`, {
      method: 'POST',
      headers: authHeaders(),
    })

    success.value = 'Uploaded successfully. Redirecting to review...'
    router.push(`/health/lab-tests/${id}/preview`)
  } catch (err: any) {
    error.value = err.message || 'Upload failed.'
  } finally {
    saving.value = false
  }
}

onMounted(loadCategories)
</script>

<style scoped>
.upload-page {
  padding: 24px;
}

.page-header,
.upload-card {
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

.upload-card {
  display: grid;
  gap: 14px;
  max-width: 720px;
}

label {
  display: grid;
  gap: 6px;
  font-weight: 700;
  color: #334155;
}

input,
select,
textarea {
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px;
}

button {
  border: 0;
  background: #0f172a;
  color: #ffffff;
  padding: 12px 16px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

button:disabled {
  opacity: 0.6;
}

.message {
  padding: 12px;
  border-radius: 12px;
}

.error {
  background: #fee2e2;
  color: #991b1b;
}

.success {
  background: #dcfce7;
  color: #166534;
}
</style>
