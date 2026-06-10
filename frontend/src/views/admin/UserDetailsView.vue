<template>
  <main class="min-h-screen bg-slate-950 px-6 py-8 text-white">
    <section class="mx-auto max-w-4xl">
      <div class="mb-8">
        <RouterLink to="/admin/users-management" class="text-sm font-semibold text-indigo-300 hover:text-indigo-200">
          ← Back to User Management
        </RouterLink>
        <h1 class="mt-4 text-3xl font-bold">User Details</h1>
        <p class="mt-2 text-slate-400">View and update user role, status, and profile data.</p>
      </div>

      <div v-if="loading" class="rounded-2xl border border-slate-800 bg-slate-900/80 p-8 text-center text-slate-400">
        Loading user...
      </div>

      <form
        v-else-if="user"
        class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl"
        @submit.prevent="submitForm"
      >
        <div v-if="errorMessage" class="mb-5 rounded-xl border border-red-900 bg-red-950/40 p-4 text-red-300">
          {{ errorMessage }}
        </div>

        <div v-if="successMessage" class="mb-5 rounded-xl border border-green-900 bg-green-950/40 p-4 text-green-300">
          {{ successMessage }}
        </div>

        <div class="mb-6 rounded-xl bg-slate-950 p-4 text-sm text-slate-400">
          <p><strong class="text-slate-200">ID:</strong> {{ user.id }}</p>
          <p><strong class="text-slate-200">Created:</strong> {{ user.created_at || '-' }}</p>
          <p><strong class="text-slate-200">Last login:</strong> {{ user.last_login_at || 'Never' }}</p>
        </div>

        <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
          <div>
            <label class="mb-2 block text-sm text-slate-400">Name</label>
            <input v-model="form.name" required type="text" class="field" />
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Email</label>
            <input v-model="form.email" required type="email" class="field" />
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Role</label>
            <select v-model="form.role" required class="field">
              <option value="admin">admin</option>
              <option value="user">user</option>
              <option value="demo">demo</option>
              <option value="qa">qa</option>
            </select>
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Status</label>
            <select v-model="form.status" required class="field">
              <option value="active">active</option>
              <option value="hold">hold</option>
              <option value="inactive">inactive</option>
            </select>
          </div>

          <div class="md:col-span-2">
            <label class="mb-2 block text-sm text-slate-400">New Password</label>
            <input v-model="form.password" type="password" minlength="8" placeholder="Leave empty to keep current password" class="field" />
          </div>
        </div>

        <div class="mt-8 flex flex-col justify-end gap-3 sm:flex-row">
          <button
            type="button"
            class="rounded-xl border border-amber-800 px-5 py-3 font-semibold text-amber-300 hover:bg-amber-950/50"
            @click="holdUser"
          >
            Hold
          </button>

          <button
            type="button"
            class="rounded-xl border border-green-800 px-5 py-3 font-semibold text-green-300 hover:bg-green-950/50"
            @click="activateUser"
          >
            Activate
          </button>

          <button
            type="submit"
            class="rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white hover:bg-indigo-500 disabled:opacity-60"
            :disabled="saving"
          >
            {{ saving ? 'Saving...' : 'Save Changes' }}
          </button>
        </div>
      </form>

      <div v-else class="rounded-2xl border border-red-900 bg-red-950/40 p-6 text-red-300">
        User not found.
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import api, { getApiErrorMessage } from '@/services/api'

const route = useRoute()
const userId = String(route.params.id)

const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const user = ref<any>(null)

const form = reactive({
  name: '',
  email: '',
  password: '',
  role: 'user',
  status: 'active',
})

function fillForm(data: any) {
  user.value = data
  form.name = data?.name || ''
  form.email = data?.email || ''
  form.role = data?.role || 'user'
  form.status = data?.status || 'active'
  form.password = ''
}

async function loadUser() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get(`/admin/users/${userId}`)
    fillForm(response.data?.data?.user)
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to load user.')
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: Record<string, string> = {
    name: form.name,
    email: form.email,
    role: form.role,
    status: form.status,
  }

  if (form.password) {
    payload.password = form.password
  }

  try {
    const response = await api.put(`/admin/users/${userId}`, payload)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User updated successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to update user.')
  } finally {
    saving.value = false
  }
}

async function holdUser() {
  if (!confirm(`Place ${form.email} on hold?`)) return

  try {
    const response = await api.put(`/admin/users/${userId}/hold`)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User placed on hold successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to place user on hold.')
  }
}

async function activateUser() {
  try {
    const response = await api.put(`/admin/users/${userId}/activate`)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User activated successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to activate user.')
  }
}

onMounted(loadUser)
</script>

<style scoped>
.field {
  width: 100%;
  border-radius: 0.75rem;
  border: 1px solid rgb(51 65 85);
  background: rgb(2 6 23);
  padding: 0.75rem 1rem;
  color: white;
  outline: none;
}
.field:focus {
  border-color: rgb(99 102 241);
}
</style>
