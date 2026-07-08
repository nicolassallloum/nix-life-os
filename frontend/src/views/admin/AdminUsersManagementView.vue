<template>
  <main class="min-h-screen bg-slate-950 text-white px-6 py-8">
    <!-- Header -->
    <section class="mb-8">
      <p class="text-xs tracking-[0.35em] uppercase text-slate-400 font-semibold">
        Management Module
      </p>

      <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mt-3">
        <div>
          <h1 class="text-3xl font-bold tracking-tight">Users Management</h1>
          <p class="text-slate-400 mt-2">
            Manage application users, roles, status, access levels, and account activation.
          </p>
        </div>

        <button
          type="button"
          class="bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-3 rounded-xl font-semibold shadow-lg shadow-indigo-900/40 transition"
          @click="openCreateForm"
        >
          + Create User
        </button>
      </div>
    </section>

    <!-- Summary Cards -->
    <section class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-slate-400 text-sm">Total Users</p>
        <h2 class="text-3xl font-bold mt-2">{{ stats.total }}</h2>
        <p class="text-green-400 text-sm mt-2">Application users</p>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-slate-400 text-sm">Active Users</p>
        <h2 class="text-3xl font-bold mt-2">{{ stats.active }}</h2>
        <p class="text-green-400 text-sm mt-2">{{ activePercentage }}% of total</p>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-slate-400 text-sm">Held / Inactive</p>
        <h2 class="text-3xl font-bold mt-2">{{ stats.inactive }}</h2>
        <p class="text-amber-400 text-sm mt-2">Blocked from login</p>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-slate-400 text-sm">Roles</p>
        <h2 class="text-3xl font-bold mt-2">{{ roleCount }}</h2>
        <p class="text-blue-400 text-sm mt-2">Available access groups</p>
      </div>
    </section>

    <!-- Users Directory -->
    <section class="rounded-2xl border border-slate-800 bg-slate-900/80 shadow-xl overflow-hidden">
      <div class="p-6 border-b border-slate-800">
        <div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
          <div>
            <h2 class="text-xl font-bold">Application Users Directory</h2>
            <p class="text-slate-400 mt-1">
              View, search, create, update, hold, activate, and delete users.
            </p>
          </div>

          <div class="flex flex-col md:flex-row gap-3">
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search users..."
              class="w-full md:w-72 rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />

            <select
              v-model="filters.role"
              class="rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">All Roles</option>
              <option v-for="role in roles" :key="role" :value="role">{{ role }}</option>
            </select>

            <select
              v-model="filters.status"
              class="rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">All Status</option>
              <option value="ACTIVE">ACTIVE</option>
              <option value="INACTIVE">INACTIVE</option>
              <option value="HOLD">HOLD</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="p-8 text-center text-slate-400">
        Loading users...
      </div>

      <!-- Error -->
      <div v-if="errorMessage" class="m-6 rounded-xl border border-red-900 bg-red-950/40 p-4 text-red-300">
        {{ errorMessage }}
      </div>

      <!-- Table -->
      <div v-if="!loading" class="overflow-x-auto">
        <table class="min-w-full text-left">
          <thead class="bg-slate-950/70 text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th class="px-6 py-4">User</th>
              <th class="px-6 py-4">Email</th>
              <th class="px-6 py-4">Role</th>
              <th class="px-6 py-4">Status</th>
              <th class="px-6 py-4">Last Login</th>
              <th class="px-6 py-4">Created At</th>
              <th class="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="user in filteredUsers"
              :key="user.id"
              class="border-t border-slate-800 hover:bg-slate-800/40 transition"
            >
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="w-11 h-11 rounded-full bg-indigo-600/25 flex items-center justify-center font-bold">
                    {{ initials(user.name) }}
                  </div>
                  <div>
                    <p class="font-semibold">{{ user.name }}</p>
                    <p class="text-sm text-slate-400">ID: {{ user.id }}</p>
                  </div>
                </div>
              </td>

              <td class="px-6 py-4 text-slate-300">
                {{ user.email }}
              </td>

              <td class="px-6 py-4">
                <span class="px-3 py-1 rounded-lg text-xs font-semibold bg-indigo-950 text-indigo-300">
                  {{ user.role || 'user' }}
                </span>
              </td>

              <td class="px-6 py-4">
                <span
                  class="px-3 py-1 rounded-lg text-xs font-semibold"
                  :class="statusClass(user.status)"
                >
                  ● {{ user.status }}
                </span>
              </td>

              <td class="px-6 py-4 text-slate-300">
                {{ user.last_login_at || 'Never' }}
              </td>

              <td class="px-6 py-4 text-slate-300">
                {{ user.created_at || '-' }}
              </td>

              <td class="px-6 py-4">
                <div class="flex justify-end gap-2">
                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-slate-700 hover:bg-slate-800"
                    title="View User"
                    @click="viewUser(user)"
                  >
                    👁
                  </button>

                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-slate-700 hover:bg-slate-800"
                    title="Update User"
                    @click="openEditForm(user)"
                  >
                    ✏️
                  </button>

                  <button
                    v-if="user.status === 'ACTIVE'"
                    type="button"
                    class="w-10 h-10 rounded-lg border border-amber-800 text-amber-300 hover:bg-amber-950/50"
                    title="Hold / Deactivate User"
                    @click="holdUser(user)"
                  >
                    ⏸
                  </button>

                  <button
                    v-else
                    type="button"
                    class="w-10 h-10 rounded-lg border border-green-800 text-green-300 hover:bg-green-950/50"
                    title="Activate User"
                    @click="activateUser(user)"
                  >
                    ▶
                  </button>

                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-red-900/60 text-red-400 hover:bg-red-950/50"
                    title="Delete User"
                    @click="deleteUser(user)"
                  >
                    🗑
                  </button>
                </div>
              </td>
            </tr>

            <tr v-if="filteredUsers.length === 0">
              <td colspan="7" class="px-6 py-10 text-center text-slate-400">
                No users found.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 p-6 border-t border-slate-800">
        <p class="text-slate-400 text-sm">
          Showing {{ filteredUsers.length }} of {{ users.length }} users
        </p>
      </div>
    </section>

    <!-- Create / Edit Modal -->
    <div
      v-if="showForm"
      class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 px-4"
    >
      <div class="w-full max-w-2xl rounded-2xl bg-slate-900 border border-slate-700 shadow-2xl">
        <div class="p-6 border-b border-slate-800 flex items-center justify-between">
          <h3 class="text-xl font-bold">
            {{ formMode === 'create' ? 'Create User' : 'Update User' }}
          </h3>

          <button class="text-slate-400 hover:text-white" @click="closeForm">
            ✕
          </button>
        </div>

        <form class="p-6 space-y-5" @submit.prevent="submitForm">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label class="block text-sm text-slate-400 mb-2">Name</label>
              <input
                v-model="form.name"
                type="text"
                class="w-full rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-white"
                required
              />
            </div>

            <div>
              <label class="block text-sm text-slate-400 mb-2">Email</label>
              <input
                v-model="form.email"
                type="email"
                class="w-full rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-white"
                required
              />
            </div>

            <div>
              <label class="block text-sm text-slate-400 mb-2">Role</label>
              <select
                v-model="form.role"
                class="w-full rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-white"
              >
                <option value="admin">admin</option>
                <option value="manager">manager</option>
                <option value="user">user</option>
              </select>
            </div>

            <div>
              <label class="block text-sm text-slate-400 mb-2">Status</label>
              <select
                v-model="form.status"
                class="w-full rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-white"
              >
                <option value="ACTIVE">ACTIVE</option>
                <option value="INACTIVE">INACTIVE</option>
                <option value="HOLD">HOLD</option>
              </select>
            </div>

            <div class="md:col-span-2">
              <label class="block text-sm text-slate-400 mb-2">
                Password {{ formMode === 'edit' ? '(leave empty to keep current password)' : '' }}
              </label>
              <input
                v-model="form.password"
                type="password"
                class="w-full rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-white"
                :required="formMode === 'create'"
              />
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4">
            <button
              type="button"
              class="px-5 py-3 rounded-xl border border-slate-700 text-slate-300 hover:bg-slate-800"
              @click="closeForm"
            >
              Cancel
            </button>

            <button
              type="submit"
              class="px-5 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold"
            >
              {{ formMode === 'create' ? 'Create User' : 'Update User' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8001/api/v1'

const loading = ref(false)
const errorMessage = ref('')
const showForm = ref(false)
const formMode = ref('create')
const selectedUserId = ref(null)

const users = ref([])

const filters = reactive({
  search: '',
  role: '',
  status: '',
})

const form = reactive({
  name: '',
  email: '',
  role: 'user',
  status: 'ACTIVE',
  password: '',
})

const roles = computed(() => {
  const allRoles = users.value.map((user) => user.role || 'user')
  return [...new Set(allRoles)]
})

const filteredUsers = computed(() => {
  return users.value.filter((user) => {
    const search = filters.search.toLowerCase()

    const matchesSearch =
      !search ||
      String(user.name || '').toLowerCase().includes(search) ||
      String(user.email || '').toLowerCase().includes(search)

    const matchesRole = !filters.role || user.role === filters.role
    const matchesStatus = !filters.status || user.status === filters.status

    return matchesSearch && matchesRole && matchesStatus
  })
})

const stats = computed(() => {
  return {
    total: users.value.length,
    active: users.value.filter((user) => user.status === 'ACTIVE').length,
    inactive: users.value.filter((user) => user.status !== 'ACTIVE').length,
  }
})

const activePercentage = computed(() => {
  if (!stats.value.total) return 0
  return Math.round((stats.value.active / stats.value.total) * 100)
})

const roleCount = computed(() => roles.value.length)

onMounted(() => {
  loadUsers()
})

function getToken() {
  return localStorage.getItem('token') || localStorage.getItem('auth_token')
}

async function apiRequest(path, options = {}) {
  const token = getToken()

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: token ? `Bearer ${token}` : '',
      ...options.headers,
    },
  })

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    throw new Error(data.message || 'Request failed.')
  }

  return data
}

async function loadUsers() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await apiRequest('/admin/users')
    const payload =
      response.data?.users ||
      response.data?.data ||
      response.data ||
      []
    users.value = Array.isArray(payload)
      ? payload.map(normalizeUser)
      : []
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    loading.value = false
  }
}

function normalizeUser(user) {
  const roles = user.roles || []
  const firstRole = Array.isArray(roles) ? roles[0] : roles

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role || firstRole || 'user',
    status: user.status || (user.is_active === false ? 'INACTIVE' : 'ACTIVE'),
    last_login_at: user.last_login_at || null,
    created_at: user.created_at || null,
  }
}

function openCreateForm() {
  formMode.value = 'create'
  selectedUserId.value = null

  form.name = ''
  form.email = ''
  form.role = 'user'
  form.status = 'ACTIVE'
  form.password = ''

  showForm.value = true
}

function openEditForm(user) {
  formMode.value = 'edit'
  selectedUserId.value = user.id

  form.name = user.name
  form.email = user.email
  form.role = user.role || 'user'
  form.status = user.status || 'ACTIVE'
  form.password = ''

  showForm.value = true
}

function closeForm() {
  showForm.value = false
}

async function submitForm() {
  errorMessage.value = ''

  try {
    const payload = {
      name: form.name,
      email: form.email,
      role: form.role,
      status: form.status,
    }

    if (form.password) {
      payload.password = form.password
    }

    if (formMode.value === 'create') {
      await apiRequest('/admin/users', {
        method: 'POST',
        body: JSON.stringify(payload),
      })
    } else {
      await apiRequest(`/admin/users/${selectedUserId.value}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      })
    }

    closeForm()
    await loadUsers()
  } catch (error) {
    errorMessage.value = error.message
  }
}

function viewUser(user) {
  alert(`User: ${user.name}\nEmail: ${user.email}\nRole: ${user.role}\nStatus: ${user.status}`)
}

async function holdUser(user) {
  const confirmed = confirm(`Hold / deactivate user ${user.name}? This will block login.`)
  if (!confirmed) return

  try {
    await apiRequest(`/admin/users/${user.id}/deactivate`, {
      method: 'POST',
    })

    await loadUsers()
  } catch (error) {
    errorMessage.value = error.message
  }
}

async function activateUser(user) {
  const confirmed = confirm(`Activate user ${user.name}?`)
  if (!confirmed) return

  try {
    await apiRequest(`/admin/users/${user.id}/activate`, {
      method: 'POST',
    })

    await loadUsers()
  } catch (error) {
    errorMessage.value = error.message
  }
}

async function deleteUser(user) {
  const confirmed = confirm(`Delete user ${user.name}? This action cannot be undone.`)
  if (!confirmed) return

  try {
    await apiRequest(`/admin/users/${user.id}`, {
      method: 'DELETE',
    })

    await loadUsers()
  } catch (error) {
    errorMessage.value = error.message
  }
}

function initials(name) {
  return String(name || 'U')
    .split(' ')
    .map((part) => part[0])
    .join('')
    .substring(0, 2)
    .toUpperCase()
}

function statusClass(status) {
  const classes = {
    ACTIVE: 'bg-green-950 text-green-300',
    INACTIVE: 'bg-red-950 text-red-300',
    HOLD: 'bg-amber-950 text-amber-300',
  }

  return classes[status] || 'bg-slate-800 text-slate-300'
}
</script>
