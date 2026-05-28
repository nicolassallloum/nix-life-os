<template>
  <main class="min-h-screen bg-slate-950 text-white px-6 py-8">
    <!-- Header -->
    <section class="mb-8">
      <p class="text-xs tracking-[0.35em] uppercase text-slate-400 font-semibold">
        Management Module
      </p>

      <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mt-3">
        <div>
          <h1 class="text-3xl font-bold tracking-tight">Accounts Management</h1>
          <p class="text-slate-400 mt-2">
            Manage system accounts, account types, statuses, access levels, and financial records.
          </p>
        </div>

        <button
          type="button"
          class="bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-3 rounded-xl font-semibold shadow-lg shadow-indigo-900/40 transition"
          @click="openCreateModal"
        >
          + Add Account
        </button>
      </div>
    </section>

    <!-- Summary Cards -->
    <section class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-2xl bg-indigo-600/25 flex items-center justify-center text-2xl">
            🏦
          </div>
          <div>
            <p class="text-slate-400 text-sm">Total Accounts</p>
            <h2 class="text-3xl font-bold mt-1">{{ stats.totalAccounts }}</h2>
            <p class="text-green-400 text-sm mt-1">+{{ stats.newThisMonth }} this month</p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-2xl bg-green-600/25 flex items-center justify-center text-2xl">
            ✅
          </div>
          <div>
            <p class="text-slate-400 text-sm">Active Accounts</p>
            <h2 class="text-3xl font-bold mt-1">{{ stats.activeAccounts }}</h2>
            <p class="text-green-400 text-sm mt-1">{{ activePercentage }}% of total</p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-2xl bg-blue-600/25 flex items-center justify-center text-2xl">
            💰
          </div>
          <div>
            <p class="text-slate-400 text-sm">Total Balance</p>
            <h2 class="text-3xl font-bold mt-1">{{ formatCurrency(stats.totalBalance) }}</h2>
            <p class="text-green-400 text-sm mt-1">All active accounts</p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-2xl bg-amber-600/25 flex items-center justify-center text-2xl">
            📦
          </div>
          <div>
            <p class="text-slate-400 text-sm">Inactive / Archived</p>
            <h2 class="text-3xl font-bold mt-1">{{ stats.inactiveAccounts }}</h2>
            <p class="text-amber-400 text-sm mt-1">Requires review</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Accounts Directory -->
    <section class="rounded-2xl border border-slate-800 bg-slate-900/80 shadow-xl overflow-hidden">
      <div class="p-6 border-b border-slate-800">
        <div class="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
          <div>
            <h2 class="text-xl font-bold">Accounts Directory</h2>
            <p class="text-slate-400 mt-1">
              View, search, filter, create, edit, and archive accounts.
            </p>
          </div>

          <div class="flex flex-col md:flex-row gap-3">
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search accounts..."
              class="w-full md:w-72 rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />

            <select
              v-model="filters.type"
              class="rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">All Types</option>
              <option value="Cash">Cash</option>
              <option value="Savings">Savings</option>
              <option value="Business">Business</option>
              <option value="Expense">Expense</option>
              <option value="Revenue">Revenue</option>
              <option value="Liability">Liability</option>
              <option value="Investment">Investment</option>
            </select>

            <select
              v-model="filters.status"
              class="rounded-xl bg-slate-950 border border-slate-700 px-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">All Statuses</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
              <option value="Archived">Archived</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Table -->
      <div class="overflow-x-auto">
        <table class="min-w-full text-left">
          <thead class="bg-slate-950/70 text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th class="px-6 py-4">Account</th>
              <th class="px-6 py-4">Account Number</th>
              <th class="px-6 py-4">Type</th>
              <th class="px-6 py-4">Currency</th>
              <th class="px-6 py-4">Balance</th>
              <th class="px-6 py-4">Status</th>
              <th class="px-6 py-4">Last Updated</th>
              <th class="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="account in filteredAccounts"
              :key="account.id"
              class="border-t border-slate-800 hover:bg-slate-800/40 transition"
            >
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div
                    class="w-11 h-11 rounded-full flex items-center justify-center text-lg"
                    :class="accountIconClass(account.type)"
                  >
                    {{ accountIcon(account.type) }}
                  </div>
                  <div>
                    <p class="font-semibold">{{ account.name }}</p>
                    <p class="text-sm text-slate-400">{{ account.description }}</p>
                  </div>
                </div>
              </td>

              <td class="px-6 py-4 text-slate-300">
                {{ account.accountNumber }}
              </td>

              <td class="px-6 py-4">
                <span
                  class="px-3 py-1 rounded-lg text-xs font-semibold"
                  :class="typeClass(account.type)"
                >
                  {{ account.type }}
                </span>
              </td>

              <td class="px-6 py-4 text-slate-300">
                {{ account.currency }}
              </td>

              <td class="px-6 py-4 font-semibold" :class="account.balance < 0 ? 'text-red-400' : 'text-white'">
                {{ formatCurrency(account.balance) }}
              </td>

              <td class="px-6 py-4">
                <span
                  class="px-3 py-1 rounded-lg text-xs font-semibold"
                  :class="statusClass(account.status)"
                >
                  ● {{ account.status }}
                </span>
              </td>

              <td class="px-6 py-4 text-slate-300">
                <p>{{ account.updatedDate }}</p>
                <p class="text-xs text-slate-500">{{ account.updatedTime }}</p>
              </td>

              <td class="px-6 py-4">
                <div class="flex justify-end gap-2">
                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-slate-700 hover:bg-slate-800"
                    title="View"
                    @click="viewAccount(account)"
                  >
                    👁
                  </button>

                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-slate-700 hover:bg-slate-800"
                    title="Edit"
                    @click="editAccount(account)"
                  >
                    ✏️
                  </button>

                  <button
                    type="button"
                    class="w-10 h-10 rounded-lg border border-red-900/60 text-red-400 hover:bg-red-950/50"
                    title="Delete"
                    @click="deleteAccount(account)"
                  >
                    🗑
                  </button>
                </div>
              </td>
            </tr>

            <tr v-if="filteredAccounts.length === 0">
              <td colspan="8" class="px-6 py-10 text-center text-slate-400">
                No accounts found for the selected filters.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Footer -->
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 p-6 border-t border-slate-800">
        <p class="text-slate-400 text-sm">
          Showing {{ filteredAccounts.length }} of {{ accounts.length }} accounts
        </p>

        <div class="flex gap-2">
          <button class="px-4 py-2 rounded-lg border border-slate-700 text-slate-400">
            ‹
          </button>
          <button class="px-4 py-2 rounded-lg bg-indigo-600 text-white">
            1
          </button>
          <button class="px-4 py-2 rounded-lg border border-slate-700 text-slate-400">
            2
          </button>
          <button class="px-4 py-2 rounded-lg border border-slate-700 text-slate-400">
            3
          </button>
          <button class="px-4 py-2 rounded-lg border border-slate-700 text-slate-400">
            ›
          </button>
        </div>
      </div>
    </section>
  </main>
</template>

<script setup>
import { computed, reactive } from 'vue'

const filters = reactive({
  search: '',
  type: '',
  status: '',
})

const accounts = reactive([
  {
    id: 1,
    name: 'Cash Wallet',
    description: 'Personal cash account',
    accountNumber: 'CW-1001-0001',
    type: 'Cash',
    currency: 'USD',
    balance: 2450.75,
    status: 'Active',
    updatedDate: 'May 28, 2026',
    updatedTime: '10:15 AM',
  },
  {
    id: 2,
    name: 'Main Savings',
    description: 'Personal savings account',
    accountNumber: 'SV-2001-0001',
    type: 'Savings',
    currency: 'USD',
    balance: 78320,
    status: 'Active',
    updatedDate: 'May 28, 2026',
    updatedTime: '9:42 AM',
  },
  {
    id: 3,
    name: 'Business Account',
    description: 'Business operations',
    accountNumber: 'BA-3001-0001',
    type: 'Business',
    currency: 'USD',
    balance: 120500.9,
    status: 'Active',
    updatedDate: 'May 28, 2026',
    updatedTime: '8:30 AM',
  },
  {
    id: 4,
    name: 'Expense Account',
    description: 'Operating expenses',
    accountNumber: 'EX-4001-0001',
    type: 'Expense',
    currency: 'USD',
    balance: -12345.25,
    status: 'Active',
    updatedDate: 'May 28, 2026',
    updatedTime: '7:55 AM',
  },
  {
    id: 5,
    name: 'Revenue Account',
    description: 'Income and revenue',
    accountNumber: 'RV-5001-0001',
    type: 'Revenue',
    currency: 'USD',
    balance: 56754.1,
    status: 'Active',
    updatedDate: 'May 27, 2026',
    updatedTime: '4:20 PM',
  },
  {
    id: 6,
    name: 'Credit Card',
    description: 'Corporate card',
    accountNumber: 'CC-6001-0001',
    type: 'Liability',
    currency: 'USD',
    balance: -450,
    status: 'Inactive',
    updatedDate: 'May 24, 2026',
    updatedTime: '3:12 PM',
  },
  {
    id: 7,
    name: 'Old Investment',
    description: 'Archived account',
    accountNumber: 'INV-7001-0001',
    type: 'Investment',
    currency: 'USD',
    balance: 0,
    status: 'Archived',
    updatedDate: 'May 10, 2026',
    updatedTime: '11:05 AM',
  },
])

const filteredAccounts = computed(() => {
  return accounts.filter((account) => {
    const search = filters.search.toLowerCase()

    const matchesSearch =
      !search ||
      account.name.toLowerCase().includes(search) ||
      account.description.toLowerCase().includes(search) ||
      account.accountNumber.toLowerCase().includes(search)

    const matchesType = !filters.type || account.type === filters.type
    const matchesStatus = !filters.status || account.status === filters.status

    return matchesSearch && matchesType && matchesStatus
  })
})

const stats = computed(() => {
  const totalAccounts = accounts.length
  const activeAccounts = accounts.filter((account) => account.status === 'Active').length
  const inactiveAccounts = accounts.filter((account) => account.status !== 'Active').length
  const totalBalance = accounts.reduce((sum, account) => sum + Number(account.balance || 0), 0)

  return {
    totalAccounts,
    activeAccounts,
    inactiveAccounts,
    totalBalance,
    newThisMonth: 2,
  }
})

const activePercentage = computed(() => {
  if (!stats.value.totalAccounts) return 0

  return Math.round((stats.value.activeAccounts / stats.value.totalAccounts) * 100)
})

function formatCurrency(value) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(value)
}

function accountIcon(type) {
  const icons = {
    Cash: '💵',
    Savings: '🏦',
    Business: '💼',
    Expense: '🧾',
    Revenue: '📊',
    Liability: '💳',
    Investment: '🏛',
  }

  return icons[type] || '🏦'
}

function accountIconClass(type) {
  const classes = {
    Cash: 'bg-green-600/25 text-green-300',
    Savings: 'bg-blue-600/25 text-blue-300',
    Business: 'bg-indigo-600/25 text-indigo-300',
    Expense: 'bg-amber-600/25 text-amber-300',
    Revenue: 'bg-cyan-600/25 text-cyan-300',
    Liability: 'bg-yellow-600/25 text-yellow-300',
    Investment: 'bg-slate-600/25 text-slate-300',
  }

  return classes[type] || 'bg-slate-600/25 text-slate-300'
}

function typeClass(type) {
  const classes = {
    Cash: 'bg-green-950 text-green-300',
    Savings: 'bg-blue-950 text-blue-300',
    Business: 'bg-indigo-950 text-indigo-300',
    Expense: 'bg-amber-950 text-amber-300',
    Revenue: 'bg-cyan-950 text-cyan-300',
    Liability: 'bg-yellow-950 text-yellow-300',
    Investment: 'bg-slate-800 text-slate-300',
  }

  return classes[type] || 'bg-slate-800 text-slate-300'
}

function statusClass(status) {
  const classes = {
    Active: 'bg-green-950 text-green-300',
    Inactive: 'bg-red-950 text-red-300',
    Archived: 'bg-amber-950 text-amber-300',
  }

  return classes[status] || 'bg-slate-800 text-slate-300'
}

function openCreateModal() {
  alert('Add Account modal will be connected to backend API.')
}

function viewAccount(account) {
  alert(`View account: ${account.name}`)
}

function editAccount(account) {
  alert(`Edit account: ${account.name}`)
}

function deleteAccount(account) {
  const confirmed = confirm(`Are you sure you want to delete ${account.name}?`)

  if (!confirmed) return

  alert(`Delete API will be connected for account: ${account.name}`)
}
</script>
