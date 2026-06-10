<template>
  <main class="min-h-screen bg-slate-950 px-6 py-8 text-white">
    <section class="mx-auto max-w-3xl">
      <div class="mb-8">
        <RouterLink to="/admin/users-management" class="text-sm font-semibold text-indigo-300 hover:text-indigo-200">
          ← Back to User Management
        </RouterLink>
        <h1 class="mt-4 text-3xl font-bold">Create User</h1>
        <p class="mt-2 text-slate-400">
          Create an admin, normal user, demo user, or QA user.
        </p>
      </div>

      <form class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl" @submit.prevent="submitForm">
        <div v-if="errorMessage" class="mb-5 rounded-xl border border-red-900 bg-red-950/40 p-4 text-red-300">
          {{ errorMessage }}
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
            <label class="mb-2 block text-sm text-slate-400">Password</label>
            <input v-model="form.password" required type="password" minlength="8" class="field" />
          </div>
        </div>

        <div class="mt-8 flex justify-end gap-3">
          <RouterLink to="/admin/users-management" class="rounded-xl border border-slate-700 px-5 py-3 text-slate-300 hover:bg-slate-800">
            Cancel
          </RouterLink>

          <button
            type="submit"
            class="rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white hover:bg-indigo-500 disabled:opacity-60"
            :disabled="saving"
          >
            {{ saving ? 'Creating...' : 'Create User' }}
          </button>
        </div>
      </form>
    </section>
  </main>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import api, { getApiErrorMessage } from '@/services/api'

const router = useRouter()
const saving = ref(false)
const errorMessage = ref('')

const form = reactive({
  name: '',
  email: '',
  password: '',
  role: 'user',
  status: 'active',
})

async function submitForm() {
  saving.value = true
  errorMessage.value = ''

  try {
    const response = await api.post('/admin/users', form)
    const userId = response.data?.data?.user?.id

    if (userId) {
      router.push(`/admin/users/${userId}`)
    } else {
      router.push('/admin/users-management')
    }
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to create user.')
  } finally {
    saving.value = false
  }
}
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
