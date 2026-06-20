<template>
  <div class="min-h-screen bg-slate-950 text-white p-6">
    <div class="max-w-7xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold">Finance Accounts</h1>
          <p class="text-slate-400 mt-1">
            Manage your cash, bank, savings, credit card, and investment accounts.
          </p>
        </div>

        <button
          @click="openCreateModal"
          class="px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-semibold transition"
        >
          + Add Account
        </button>
      </div>

      <!-- Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5">
          <p class="text-slate-400 text-sm">Total Accounts</p>
          <h2 class="text-2xl font-bold mt-2">{{ accounts.length }}</h2>
        </div>

        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5">
          <p class="text-slate-400 text-sm">Total Balance</p>
          <h2 class="text-2xl font-bold mt-2">
            {{ formatMoney(totalBalance, defaultCurrency) }}
          </h2>
        </div>

        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5">
          <p class="text-slate-400 text-sm">Active Accounts</p>
          <h2 class="text-2xl font-bold mt-2">{{ activeAccountsCount }}</h2>
        </div>
      </div>

      <!-- Error Message -->
      <div
        v-if="errorMessage"
        class="bg-red-950 border border-red-800 text-red-200 rounded-xl p-4"
      >
        {{ errorMessage }}
      </div>

      <!-- Success Message -->
      <div
        v-if="successMessage"
        class="bg-green-950 border border-green-800 text-green-200 rounded-xl p-4"
      >
        {{ successMessage }}
      </div>

      <!-- Loading -->
      <div
        v-if="loading"
        class="bg-slate-900 border border-slate-800 rounded-2xl p-8 text-center text-slate-400"
      >
        Loading finance accounts...
      </div>

      <!-- Empty State -->
      <div
        v-else-if="accounts.length === 0"
        class="bg-slate-900 border border-slate-800 rounded-2xl p-10 text-center"
      >
        <h3 class="text-xl font-semibold">No accounts found</h3>
        <p class="text-slate-400 mt-2">
          Create your first finance account to start tracking your money.
        </p>

        <button
          @click="openCreateModal"
          class="mt-5 px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-semibold transition"
        >
          Add First Account
        </button>
      </div>

      <!-- Accounts Table -->
      <div
        v-else
        class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden"
      >
        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead class="bg-slate-800 text-slate-300 text-sm">
              <tr>
                <th class="px-5 py-4">Name</th>
                <th class="px-5 py-4">Type</th>
                <th class="px-5 py-4">Balance</th>
                <th class="px-5 py-4">Currency</th>
                <th class="px-5 py-4">Status</th>
                <th class="px-5 py-4 text-right">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="account in accounts"
                :key="account.id"
                class="border-t border-slate-800 hover:bg-slate-800/50"
              >
                <td class="px-5 py-4">
                  <div>
                    <p class="font-semibold">{{ account.account_name || account.name }}</p>
                    <p class="text-sm text-slate-400">
                      {{ account.description || "No description" }}
                    </p>
                  </div>
                </td>

                <td class="px-5 py-4">
                  <span class="px-3 py-1 rounded-full bg-slate-800 text-slate-200 text-sm">
                    {{ formatAccountType(account.account_type || account.type) }}
                  </span>
                </td>

                <td class="px-5 py-4 font-semibold">
                  {{ formatMoney(getAccountBalance(account), getAccountCurrency(account)) }}
                </td>

                <td class="px-5 py-4">
                  {{ getAccountCurrency(account) }}
                </td>

                <td class="px-5 py-4">
                  <span
                    v-if="account.is_active === true || account.is_active === 1"
                    class="px-3 py-1 rounded-full bg-green-950 text-green-300 text-sm"
                  >
                    Active
                  </span>

                  <span
                    v-else
                    class="px-3 py-1 rounded-full bg-red-950 text-red-300 text-sm"
                  >
                    Inactive
                  </span>
                </td>

                <td class="px-5 py-4">
                  <div class="flex justify-end gap-2">
                    <button
                      @click="openViewModal(account)"
                      class="px-3 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-sm"
                    >
                      View
                    </button>

                    <button
                      @click="openEditModal(account)"
                      class="px-3 py-2 rounded-lg bg-yellow-600 hover:bg-yellow-700 text-sm"
                    >
                      Edit
                    </button>

                    <button
                      @click="deleteAccount(account)"
                      class="px-3 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-sm"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div
        v-if="showFormModal"
        class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4"
      >
        <div class="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl p-6">
          <div class="flex justify-between items-center mb-5">
            <h2 class="text-2xl font-bold">
              {{ isEditing ? "Edit Account" : "Add Account" }}
            </h2>

            <button
              @click="closeFormModal"
              class="text-slate-400 hover:text-white text-2xl"
            >
              ×
            </button>
          </div>

          <div
            v-if="Object.keys(validationErrors).length > 0"
            class="bg-red-950 border border-red-800 text-red-200 rounded-xl p-4 mb-5"
          >
            <p class="font-semibold mb-2">Please fix the following errors:</p>

            <ul class="list-disc list-inside space-y-1">
              <li
                v-for="(messages, field) in validationErrors"
                :key="field"
              >
                {{ Array.isArray(messages) ? messages[0] : messages }}
              </li>
            </ul>
          </div>

          <form @submit.prevent="submitAccount" class="space-y-4">
            <div>
              <label class="block text-sm text-slate-300 mb-2">Account Name</label>
              <input
                v-model="form.name"
                type="text"
                class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                placeholder="Example: Main Cash"
              />
            </div>

            <div>
              <label class="block text-sm text-slate-300 mb-2">Account Type</label>
              <select
                v-model="form.type"
                class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
              >
                <option value="cash">Cash</option>
                <option value="bank">Bank</option>
                <option value="savings">Savings</option>
                <option value="credit_card">Credit Card</option>
                <option value="investment">Investment</option>
                <option value="other">Other</option>
              </select>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-slate-300 mb-2">Balance</label>
                <input
                  v-model.number="form.balance"
                  type="number"
                  step="0.01"
                  min="0"
                  class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                  placeholder="0.00"
                />
              </div>

              <div>
                <label class="block text-sm text-slate-300 mb-2">Currency</label>
                <select
                  v-model="form.currency"
                  class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                >
                  <option value="USD">USD</option>
                  <option value="LBP">LBP</option>
                  <option value="EUR">EUR</option>
                </select>
              </div>
            </div>

            <div>
              <label class="block text-sm text-slate-300 mb-2">Description</label>
              <textarea
                v-model="form.description"
                rows="3"
                class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                placeholder="Optional account description"
              ></textarea>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <button
                type="button"
                @click="closeFormModal"
                class="px-5 py-3 rounded-xl bg-slate-700 hover:bg-slate-600 text-white"
              >
                Cancel
              </button>

              <button
                type="submit"
                :disabled="saving"
                class="px-5 py-3 rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold"
              >
                {{ saving ? "Saving..." : isEditing ? "Update Account" : "Create Account" }}
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- View Modal -->
      <div
        v-if="showViewModal && selectedAccount"
        class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4"
      >
        <div class="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-xl p-6">
          <div class="flex justify-between items-center mb-5">
            <h2 class="text-2xl font-bold">Account Details</h2>

            <button
              @click="closeViewModal"
              class="text-slate-400 hover:text-white text-2xl"
            >
              ×
            </button>
          </div>

          <div class="space-y-4">
            <div class="bg-slate-950 rounded-xl p-4">
              <p class="text-slate-400 text-sm">Name</p>
              <p class="text-lg font-semibold">{{ selectedAccount.account_name || selectedAccount.name }}</p>
            </div>

            <div class="bg-slate-950 rounded-xl p-4">
              <p class="text-slate-400 text-sm">Type</p>
              <p class="text-lg font-semibold">
                {{ formatAccountType(selectedAccount.account_type || selectedAccount.type) }}
              </p>
            </div>

            <div class="bg-slate-950 rounded-xl p-4">
              <p class="text-slate-400 text-sm">Balance</p>
              <p class="text-lg font-semibold">
                {{ formatMoney(getAccountBalance(selectedAccount), getAccountCurrency(selectedAccount)) }}
              </p>
            </div>

            <div class="bg-slate-950 rounded-xl p-4">
              <p class="text-slate-400 text-sm">Currency</p>
              <p class="text-lg font-semibold">
                {{ getAccountCurrency(selectedAccount) }}
              </p>
            </div>

            <div class="bg-slate-950 rounded-xl p-4">
              <p class="text-slate-400 text-sm">Description</p>
              <p class="text-lg font-semibold">
                {{ selectedAccount.description || "No description" }}
              </p>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-5">
            <button
              @click="closeViewModal"
              class="px-5 py-3 rounded-xl bg-slate-700 hover:bg-slate-600 text-white"
            >
              Close
            </button>

            <button
              @click="openEditModal(selectedAccount)"
              class="px-5 py-3 rounded-xl bg-yellow-600 hover:bg-yellow-700 text-white"
            >
              Edit
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue"

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "/api/v1"

const accounts = ref([])
const loading = ref(false)
const saving = ref(false)

const errorMessage = ref("")
const successMessage = ref("")
const validationErrors = ref({})

const showFormModal = ref(false)
const showViewModal = ref(false)
const isEditing = ref(false)
const selectedAccount = ref(null)

const defaultCurrency = ref("USD")

const form = ref({
  name: "",
  type: "cash",
  balance: 0,
  currency: "USD",
  description: "",
})

const getToken = () => {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token") ||
    ""
  )
}

const authHeaders = () => {
  const token = getToken()

  return {
    Accept: "application/json",
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  }
}

const clearMessages = () => {
  errorMessage.value = ""
  successMessage.value = ""
  validationErrors.value = {}
}

const fetchAccounts = async () => {
  loading.value = true
  clearMessages()

  try {
    const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
      method: "GET",
      headers: authHeaders(),
    })

    const result = await response.json()

    if (!response.ok) {
      throw result
    }

    accounts.value = Array.isArray(result.data) ? result.data : []
  } catch (error) {
    console.error("Fetch accounts error:", error)

    errorMessage.value =
      error?.message ||
      "Unable to load finance accounts. Please check API, token, and backend logs."
  } finally {
    loading.value = false
  }
}

const submitAccount = async () => {
  saving.value = true
  clearMessages()

  try {
    const url = isEditing.value
      ? `${API_BASE_URL}/finance/accounts/${selectedAccount.value.id}`
      : `${API_BASE_URL}/finance/accounts`

    const method = isEditing.value ? "PUT" : "POST"

    const balance = Number(form.value.balance || 0)

    const payload = {
      account_name: form.value.name,
      name: form.value.name,
      account_type: form.value.type,
      type: form.value.type,
      opening_balance: balance,
      current_balance: balance,
      balance,
      currency_code: form.value.currency,
      currency: form.value.currency,
      description: form.value.description,
    }

    const response = await fetch(url, {
      method,
      headers: authHeaders(),
      body: JSON.stringify(payload),
    })

    const result = await response.json()

    if (!response.ok) {
      if (result.errors) {
        validationErrors.value = result.errors
      }

      throw result
    }

    successMessage.value = isEditing.value
      ? "Account updated successfully."
      : "Account created successfully."

    closeFormModal()
    await fetchAccounts()
  } catch (error) {
    console.error("Save account error:", error)

    if (!error?.errors) {
      errorMessage.value =
        error?.message ||
        "Unable to save account. Please check validation, API route, and backend logs."
    }
  } finally {
    saving.value = false
  }
}

const deleteAccount = async (account) => {
  const confirmed = window.confirm(
    `Are you sure you want to delete "${account.account_name || account.name}"?`
  )

  if (!confirmed) return

  clearMessages()

  try {
    const response = await fetch(
      `${API_BASE_URL}/finance/accounts/${account.id}`,
      {
        method: "DELETE",
        headers: authHeaders(),
      }
    )

    const result = await response.json()

    if (!response.ok) {
      throw result
    }

    successMessage.value = "Account deleted successfully."
    await fetchAccounts()
  } catch (error) {
    console.error("Delete account error:", error)

    errorMessage.value =
      error?.message ||
      "Unable to delete account. Please check backend logs."
  }
}

const openCreateModal = () => {
  clearMessages()
  isEditing.value = false
  selectedAccount.value = null

  form.value = {
    name: "",
    type: "cash",
    balance: 0,
    currency: "USD",
    description: "",
  }

  showFormModal.value = true
}

const openEditModal = (account) => {
  clearMessages()
  isEditing.value = true
  selectedAccount.value = account
  showViewModal.value = false

  form.value = {
    name: account.name || "",
    type: account.type || "cash",
    balance: Number(getAccountBalance(account) || 0),
    currency: getAccountCurrency(account),
    description: account.description || "",
  }

  showFormModal.value = true
}

const openViewModal = (account) => {
  clearMessages()
  selectedAccount.value = account
  showViewModal.value = true
}

const closeFormModal = () => {
  showFormModal.value = false
  isEditing.value = false
  selectedAccount.value = null
  validationErrors.value = {}
}

const closeViewModal = () => {
  showViewModal.value = false
  selectedAccount.value = null
}

const totalBalance = computed(() => {
  return accounts.value.reduce((sum, account) => {
    return sum + Number(getAccountBalance(account) || 0)
  }, 0)
})

const activeAccountsCount = computed(() => {
  return accounts.value.filter((account) => {
    return account.is_active === true || account.is_active === 1
  }).length
})

const getAccountBalance = (account) => {
  return (
    account?.current_balance ??
    account?.balance ??
    account?.opening_balance ??
    0
  )
}

const getAccountCurrency = (account) => {
  return (
    account?.currency_code ||
    account?.currency ||
    "USD"
  )
}

const formatMoney = (value, currency = "USD") => {
  const amount = Number(value || 0)

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: currency || "USD",
  }).format(amount)
}

const formatAccountType = (type) => {
  const map = {
    cash: "Cash",
    bank: "Bank",
    savings: "Savings",
    credit_card: "Credit Card",
    investment: "Investment",
    other: "Other",
  }

  return map[type] || type || "Other"
}

onMounted(() => {
  fetchAccounts()
})
</script>


<style scoped>
:deep(input),
:deep(select),
:deep(textarea) {
  color: #0f172a !important;
  background-color: #ffffff !important;
}

:deep(input::placeholder),
:deep(textarea::placeholder) {
  color: #64748b !important;
  opacity: 1 !important;
}

:deep(option) {
  color: #0f172a !important;
  background-color: #ffffff !important;
}
</style>
