<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">
          System Management
        </h1>
        <p class="text-sm text-gray-500">
          Manage users, application data, website usage, audit logs, and system settings.
        </p>
      </div>

      <button
        class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        @click="openCreateUserModal"
      >
        Create User
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
      <div class="bg-white rounded-xl shadow p-4">
        <p class="text-sm text-gray-500">Total Users</p>
        <h2 class="text-2xl font-bold">{{ dashboard.users.total }}</h2>
      </div>

      <div class="bg-white rounded-xl shadow p-4">
        <p class="text-sm text-gray-500">Active Users</p>
        <h2 class="text-2xl font-bold text-green-600">{{ dashboard.users.active }}</h2>
      </div>

      <div class="bg-white rounded-xl shadow p-4">
        <p class="text-sm text-gray-500">Today Logins</p>
        <h2 class="text-2xl font-bold">{{ dashboard.users.today_logins }}</h2>
      </div>

      <div class="bg-white rounded-xl shadow p-4">
        <p class="text-sm text-gray-500">API Requests Today</p>
        <h2 class="text-2xl font-bold">{{ dashboard.website_usage.api_requests_today }}</h2>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow">
      <div class="border-b px-4 py-3 flex gap-4 overflow-x-auto">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="px-3 py-2 text-sm rounded-lg"
          :class="activeTab === tab.key ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="p-4">
        <div v-if="activeTab === 'users'">
          <div class="flex items-center gap-3 mb-4">
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search users..."
              class="border rounded-lg px-3 py-2 w-full md:w-80"
              @input="loadUsers"
            />

            <select
              v-model="filters.status"
              class="border rounded-lg px-3 py-2"
              @change="loadUsers"
            >
              <option value="">All Status</option>
              <option value="ACTIVE">Active</option>
              <option value="INACTIVE">Inactive</option>
              <option value="SUSPENDED">Suspended</option>
              <option value="LOCKED">Locked</option>
            </select>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full text-sm">
              <thead>
                <tr class="bg-gray-50 text-left">
                  <th class="p-3">Name</th>
                  <th class="p-3">Email</th>
                  <th class="p-3">Phone</th>
                  <th class="p-3">Status</th>
                  <th class="p-3">Last Login</th>
                  <th class="p-3">Actions</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="user in users"
                  :key="user.id"
                  class="border-b"
                >
                  <td class="p-3 font-medium">{{ user.name }}</td>
                  <td class="p-3">{{ user.email }}</td>
                  <td class="p-3">{{ user.phone || '-' }}</td>
                  <td class="p-3">
                    <span
                      class="px-2 py-1 rounded-full text-xs"
                      :class="statusClass(user.status)"
                    >
                      {{ user.status }}
                    </span>
                  </td>
                  <td class="p-3">{{ user.last_login_at || '-' }}</td>
                  <td class="p-3">
                    <div class="flex gap-2">
                      <button
                        class="text-blue-600"
                        @click="editUser(user)"
                      >
                        Edit
                      </button>

                      <button
                        class="text-purple-600"
                        @click="openChangePasswordModal(user)"
                      >
                        Password
                      </button>

                      <button
                        v-if="user.status === 'ACTIVE'"
                        class="text-red-600"
                        @click="deactivateUser(user)"
                      >
                        Deactivate
                      </button>

                      <button
                        v-else
                        class="text-green-600"
                        @click="activateUser(user)"
                      >
                        Activate
                      </button>
                    </div>
                  </td>
                </tr>

                <tr v-if="users.length === 0">
                  <td colspan="6" class="p-6 text-center text-gray-500">
                    No users found.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div v-if="activeTab === 'usage'">
          <h2 class="text-lg font-semibold mb-3">Website Usage</h2>
          <p class="text-gray-500">Website usage charts and API request statistics will appear here.</p>
        </div>

        <div v-if="activeTab === 'applicationData'">
          <h2 class="text-lg font-semibold mb-3">Application Data</h2>
          <p class="text-gray-500">Finance, health, projects, productivity, and notifications data summary will appear here.</p>
        </div>

        <div v-if="activeTab === 'auditLogs'">
          <h2 class="text-lg font-semibold mb-3">Audit Logs</h2>
          <p class="text-gray-500">Admin actions and security logs will appear here.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import adminManagementService from '@/services/adminManagementService'

export default {
  name: 'SystemManagementView',

  data() {
    return {
      activeTab: 'users',

      tabs: [
        { key: 'users', label: 'Users Management' },
        { key: 'usage', label: 'Website Usage' },
        { key: 'applicationData', label: 'Application Data' },
        { key: 'auditLogs', label: 'Audit Logs' },
      ],

      dashboard: {
        users: {
          total: 0,
          active: 0,
          inactive: 0,
          today_logins: 0,
        },
        website_usage: {
          api_requests_today: 0,
        },
      },

      users: [],

      filters: {
        search: '',
        status: '',
      },
    }
  },

  async mounted() {
    await this.loadDashboard()
    await this.loadUsers()
  },

  methods: {
    async loadDashboard() {
      try {
        const response = await adminManagementService.getDashboardSummary()
        this.dashboard = response.data
      } catch (error) {
        console.error('Failed to load admin dashboard:', error)
      }
    },

    async loadUsers() {
      try {
        const response = await adminManagementService.getUsers(this.filters)
        this.users = response.data.data || []
      } catch (error) {
        console.error('Failed to load users:', error)
      }
    },

    statusClass(status) {
      if (status === 'ACTIVE') return 'bg-green-100 text-green-700'
      if (status === 'INACTIVE') return 'bg-gray-100 text-gray-700'
      if (status === 'SUSPENDED') return 'bg-yellow-100 text-yellow-700'
      if (status === 'LOCKED') return 'bg-red-100 text-red-700'
      return 'bg-gray-100 text-gray-700'
    },

    openCreateUserModal() {
      alert('Open Create User modal')
    },

    editUser(user) {
      alert(`Edit user: ${user.name}`)
    },

    openChangePasswordModal(user) {
      alert(`Change password for: ${user.name}`)
    },

    async activateUser(user) {
      if (!confirm(`Activate ${user.name}?`)) return

      await adminManagementService.activateUser(user.id)
      await this.loadUsers()
      await this.loadDashboard()
    },

    async deactivateUser(user) {
      if (!confirm(`Deactivate ${user.name}?`)) return

      await adminManagementService.deactivateUser(user.id)
      await this.loadUsers()
      await this.loadDashboard()
    },
  },
}
</script>