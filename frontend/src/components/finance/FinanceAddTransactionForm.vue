<template>
  <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="mb-4">
      <h2 class="text-lg font-semibold text-slate-900">Quick Transaction</h2>
      <p class="text-sm text-slate-500">Add income, expense, or transfer quickly.</p>
    </div>

    <div
      v-if="errorMessage"
      class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ errorMessage }}
    </div>

    <form class="space-y-3" @submit.prevent="save">
      <select
        v-model="form.transaction_type"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900"
        @change="handleTypeChange"
      >
        <option value="income">Income</option>
        <option value="expense">Expense</option>
        <option value="transfer">Transfer</option>
      </select>

      <select
        v-model="form.account_id"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900"
      >
        <option value="">From account</option>
        <option
          v-for="account in accounts"
          :key="account.id || account.account_id"
          :value="account.id || account.account_id"
        >
          {{ account.account_name || account.name }} — {{ account.currency_code || account.currency || 'USD' }}
        </option>
      </select>

      <select
        v-if="form.transaction_type === 'transfer'"
        v-model="form.transfer_account_id"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900"
      >
        <option value="">To account</option>
        <option
          v-for="account in destinationAccounts"
          :key="account.id || account.account_id"
          :value="account.id || account.account_id"
        >
          {{ account.account_name || account.name }} — {{ account.currency_code || account.currency || 'USD' }}
        </option>
      </select>

      <select
        v-if="form.transaction_type !== 'transfer'"
        v-model="form.category"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900"
      >
        <option value="">Select category</option>
        <option
          v-for="category in filteredCategories"
          :key="category.id || category.category_id || category.name || category.category_name"
          :value="category.name || category.category_name"
        >
          {{ category.icon ? category.icon + ' ' : '' }}{{ category.name || category.category_name }}
        </option>
      </select>

      <input
        v-if="form.transaction_type === 'transfer'"
        v-model="form.category"
        type="text"
        disabled
        class="w-full rounded-xl border border-slate-200 bg-slate-100 px-3 py-2 text-sm text-slate-600"
        placeholder="Account Transfer"
      />

      <input
        v-model="form.amount"
        type="number"
        min="0.01"
        step="0.01"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
        placeholder="Amount"
      />

      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Transaction Date
        </label>
        <input
          v-model="form.transaction_date"
          type="date"
          class="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
        />
      </div>

      <textarea
        v-model="form.description"
        rows="3"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400"
        placeholder="Description / notes for this transaction"
      ></textarea>

      <button
        type="submit"
        :disabled="saving"
        class="w-full rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
      >
        {{ saving ? 'Saving...' : 'Save Transaction' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import api from '@/services/api'

const emit = defineEmits(['saved'])

const accounts = ref([])
const categories = ref([])
const saving = ref(false)
const errorMessage = ref('')

const form = reactive({
  transaction_type: 'expense',
  account_id: '',
  transfer_account_id: '',
  category: '',
  amount: '',
  transaction_date: new Date().toISOString().slice(0, 10),
  description: '',
})

const destinationAccounts = computed(() => {
  return accounts.value.filter((account) => {
    return String(account.id || account.account_id) !== String(form.account_id)
  })
})

const filteredCategories = computed(() => {
  const unique = new Map()

  categories.value.forEach((category) => {
    const categoryName = String(
      category.name ||
      category.category_name ||
      ''
    ).trim()

    const categoryType = String(
      category.type ||
      category.category_type ||
      category.categoryType ||
      category.transaction_type ||
      ''
    ).toLowerCase()

    const isActive =
      category.is_active !== false &&
      String(category.status || 'active').toLowerCase() !== 'inactive'

    if (!categoryName || !isActive || categoryType !== form.transaction_type) {
      return
    }

    const key = `${categoryType}:${categoryName.toLowerCase()}`

    if (!unique.has(key)) {
      unique.set(key, category)
    }
  })

  return Array.from(unique.values())
})

async function loadAccounts() {
  try {
    const response = await api.get('/finance/accounts')
    accounts.value = Array.isArray(response.data?.data) ? response.data.data : []

    if (!form.account_id && accounts.value.length > 0) {
      form.account_id = accounts.value[0].id || accounts.value[0].account_id
    }
  } catch (error) {
    console.error('Load accounts error:', error)
    accounts.value = []
  }
}

async function loadCategories() {
  try {
    const response = await api.get('/finance/categories')
    categories.value = Array.isArray(response.data?.data) ? response.data.data : []
  } catch (error) {
    console.error('Load categories error:', error)
    categories.value = []
  }
}

function handleTypeChange() {
  if (form.transaction_type === 'transfer') {
    form.category = 'Account Transfer'
    return
  }

  form.transfer_account_id = ''
  form.category = ''
}

async function save() {
  errorMessage.value = ''

  if (!form.account_id) {
    errorMessage.value = 'Please select an account.'
    return
  }

  if (form.transaction_type === 'transfer' && !form.transfer_account_id) {
    errorMessage.value = 'Please select the destination account.'
    return
  }

  if (form.transaction_type !== 'transfer' && !form.category) {
    errorMessage.value = 'Please select a category.'
    return
  }

  if (!form.amount || Number(form.amount) <= 0) {
    errorMessage.value = 'Amount must be greater than zero.'
    return
  }

  if (!form.transaction_date) {
    errorMessage.value = 'Please select a transaction date.'
    return
  }

  saving.value = true

  try {
    await api.post('/finance/transactions', {
      transaction_type: form.transaction_type,
      account_id: form.account_id,
      transfer_account_id: form.transaction_type === 'transfer' ? form.transfer_account_id : null,
      category: form.transaction_type === 'transfer' ? 'Account Transfer' : form.category,
      amount: Number(form.amount),
      description: form.description,
      transaction_date: form.transaction_date,
    })

    form.amount = ''
    form.description = ''
    form.transaction_date = new Date().toISOString().slice(0, 10)
    form.transfer_account_id = ''
    form.category = form.transaction_type === 'transfer' ? 'Account Transfer' : ''

    emit('saved')

    await Promise.all([
      loadAccounts(),
      loadCategories(),
    ])
  } catch (error) {
    console.error('Save transaction error:', error)
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to save transaction.'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await Promise.all([
    loadAccounts(),
    loadCategories(),
  ])
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
