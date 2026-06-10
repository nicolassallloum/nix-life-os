<template>
  <main class="min-h-screen bg-slate-950 px-6 py-8 text-white">
    <section class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <p class="text-xs font-semibold uppercase tracking-[0.35em] text-slate-400">
          Admin Module
        </p>
        <h1 class="mt-3 text-3xl font-bold tracking-tight">User Management</h1>
        <p class="mt-2 text-slate-400">
          Manage users, roles, statuses, access control, and account activation.
        </p>
      </div>

      <div class="flex flex-col gap-3 sm:flex-row">
        <button
          type="button"
          class="rounded-xl border border-slate-700 px-5 py-3 font-semibold text-slate-200 hover:bg-slate-900"
          @click="loadUsers"
        >
          Refresh
        </button>

        <RouterLink
          to="/admin/users/create"
          class="rounded-xl bg-indigo-600 px-5 py-3 text-center font-semibold text-white shadow-lg shadow-indigo-900/40 hover:bg-indigo-500"
        >
          + Create User
        </RouterLink>
      </div>
    </section>

    <section class="mb-8 grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-4">
      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-sm text-slate-400">Total Users</p>
        <h2 class="mt-2 text-3xl font-bold">{{ stats.total }}</h2>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-sm text-slate-400">Active</p>
        <h2 class="mt-2 text-3xl font-bold text-green-300">{{ stats.active }}</h2>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-sm text-slate-400">On Hold</p>
        <h2 class="mt-2 text-3xl font-bold text-amber-300">{{ stats.hold }}</h2>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <p class="text-sm text-slate-400">Inactive</p>
        <h2 class="mt-2 text-3xl font-bold text-red-300">{{ stats.inactive }}</h2>
      </div>
    </section>

    <section class="overflow-hidden rounded-2xl border border-slate-800 bg-slate-900/80 shadow-xl">
      <div class="border-b border-slate-800 p-6">
        <div class="grid grid-cols-1 gap-3 lg:grid-cols-3">
          <input
            v-model="filters.search"
            type="text"
            placeholder="Search by name or email..."
            class="rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />

          <select
            v-model="filters.role"
            class="rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All roles</option>
            <option v-for="role in roles" :key="role" :value="role">{{ role }}</option>
          </select>

          <select
            v-model="filters.status"
            class="rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All statuses</option>
            <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
          </select>
        </div>
      </div>

      <div v-if="errorMessage" class="m-6 rounded-xl border border-red-900 bg-red-950/40 p-4 text-red-300">
        {{ errorMessage }}
      </div>

      <div v-if="loading" class="p-8 text-center text-slate-400">
        Loading users...
      </div>

      <div v-else class="overflow-x-auto">
        <table class="min-w-full text-left">
          <thead class="bg-slate-950/70 text-xs uppercase tracking-widest text-slate-400">
            <tr>
              <th class="px-6 py-4">User</th>
              <th class="px-6 py-4">Role</th>
              <th class="px-6 py-4">Status</th>
              <th class="px-6 py-4">Last Login</th>
              <th class="px-6 py-4">Created</th>
              <th class="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="user in filteredUsers"
              :key="user.id"
              class="border-t border-slate-800 hover:bg-slate-800/40"
            >
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="flex h-11 w-11 items-center justify-center rounded-full bg-indigo-600/25 font-bold">
                    {{ initials(user.name) }}
                  </div>
                  <div>
                    <p class="font-semibold">{{ user.name }}</p>
                    <p class="text-sm text-slate-400">{{ user.email }}</p>
                  </div>
                </div>
              </td>

              <td class="px-6 py-4">
                <span class="rounded-lg bg-indigo-950 px-3 py-1 text-xs font-semibold text-indigo-300">
                  {{ user.role || 'user' }}
                </span>
              </td>

              <td class="px-6 py-4">
                <span class="rounded-lg px-3 py-1 text-xs font-semibold" :class="statusClass(user.status)">
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
                  <RouterLink
                    :to="`/admin/users/${user.id}`"
                    class="rounded-lg border border-slate-700 px-3 py-2 text-sm hover:bg-slate-800"
                  >
                    View
                  </RouterLink>

                  <button
                    v-if="user.status === 'active'"
                    type="button"
                    class="rounded-lg border border-amber-800 px-3 py-2 text-sm text-amber-300 hover:bg-amber-950/50"
                    @click="holdUser(user)"
                  >
                    Hold
                  </button>

                  <button
                    v-else
                    type="button"
                    class="rounded-lg border border-green-800 px-3 py-2 text-sm text-green-300 hover:bg-green-950/50"
                    @click="activateUser(user)"
                  >
                    Activate
                  </button>
                </div>
              </td>
            </tr>

            <tr v-if="filteredUsers.length === 0">
              <td colspan="6" class="px-6 py-10 text-center text-slate-400">
                No users found.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import api, { getApiErrorMessage } from '@/services/api'

type AdminUser = {
  id: string
  name: string
  email: string
  role: 'admin' | 'user' | 'demo' | 'qa'
  status: 'active' | 'hold' | 'inactive'
  is_active?: boolean
  last_login_at?: string | null
  created_at?: string | null
}

const roles = ['admin', 'user', 'demo', 'qa']
const statuses = ['active', 'hold', 'inactive']

const loading = ref(false)
const errorMessage = ref('')
const users = ref<AdminUser[]>([])

const filters = reactive({
  search: '',
  role: '',
  status: '',
})

const filteredUsers = computed(() => {
  const search = filters.search.trim().toLowerCase()

  return users.value.filter((user) => {
    const matchesSearch =
      !search ||
      user.name?.toLowerCase().includes(search) ||
      user.email?.toLowerCase().includes(search)

    const matchesRole = !filters.role || user.role === filters.role
    const matchesStatus = !filters.status || user.status === filters.status

    return matchesSearch && matchesRole && matchesStatus
  })
})

const stats = computed(() => ({
  total: users.value.length,
  active: users.value.filter((user) => user.status === 'active').length,
  hold: users.value.filter((user) => user.status === 'hold').length,
  inactive: users.value.filter((user) => user.status === 'inactive').length,
}))

function initials(name = '') {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('') || 'U'
}

function statusClass(status: string) {
  if (status === 'active') return 'bg-green-950 text-green-300'
  if (status === 'hold') return 'bg-amber-950 text-amber-300'
  return 'bg-red-950 text-red-300'
}

async function loadUsers() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/admin/users')
    users.value = response.data?.data?.users || []
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to load users.')
  } finally {
    loading.value = false
  }
}

async function holdUser(user: AdminUser) {
  if (!confirm(`Place ${user.email} on hold?`)) return

  try {
    await api.put(`/admin/users/${user.id}/hold`)
    await loadUsers()
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to place user on hold.')
  }
}

async function activateUser(user: AdminUser) {
  try {
    await api.put(`/admin/users/${user.id}/activate`)
    await loadUsers()
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to activate user.')
  }
}

onMounted(loadUsers)
</script>
