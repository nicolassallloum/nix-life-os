<template>
  <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="mb-4">
      <h2 class="text-lg font-semibold text-slate-900">Quick Transaction</h2>
      <p class="text-sm text-slate-500">Add income, expense, or transfer quickly.</p>
    </div>

    <div v-if="errorMessage" class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
      {{ errorMessage }}
    </div>

    <form class="space-y-3" @submit.prevent="save">
      <select v-model="form.transaction_type" class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm">
        <option value="income">Income</option>
        <option value="expense">Expense</option>
        <option value="transfer">Transfer</option>
      </select>

      <select v-model="form.account_id" class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm">
        <option value="">From account</option>
        <option v-for="account in accounts" :key="account.id || account.account_id" :value="account.id || account.account_id">
          {{ account.account_name || account.name }} — {{ account.currency_code || account.currency || 'USD' }}
        </option>
      </select>

      <select
        v-if="form.transaction_type === 'transfer'"
        v-model="form.transfer_account_id"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
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

      <input
        v-model="form.category"
        type="text"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
        placeholder="Category"
      />

      <input
        v-model="form.amount"
        type="number"
        min="0.01"
        step="0.01"
        class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
        placeholder="Amount"
      />

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
const saving = ref(false)
const errorMessage = ref('')

const form = reactive({
  transaction_type: 'expense',
  account_id: '',
  transfer_account_id: '',
  category: '',
  amount: '',
})

const destinationAccounts = computed(() => {
  return accounts.value.filter((account) => String(account.id || account.account_id) !== String(form.account_id))
})

async function loadAccounts() {
  try {
    const response = await api.get('/finance/accounts')
    accounts.value = Array.isArray(response.data?.data) ? response.data.data : []

    if (!form.account_id && accounts.value.length > 0) {
      form.account_id = accounts.value[0].id || accounts.value[0].account_id
    }
  } catch {
    accounts.value = []
  }
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

  if (!form.amount || Number(form.amount) <= 0) {
    errorMessage.value = 'Amount must be greater than zero.'
    return
  }

  saving.value = true

  try {
    await api.post('/finance/transactions', {
      transaction_type: form.transaction_type,
      account_id: form.account_id,
      transfer_account_id: form.transaction_type === 'transfer' ? form.transfer_account_id : null,
      category: form.category || (form.transaction_type === 'transfer' ? 'Account Transfer' : 'General'),
      amount: Number(form.amount),
      transaction_date: new Date().toISOString().slice(0, 10),
    })

    form.amount = ''
    form.category = ''
    form.transfer_account_id = ''

    emit('saved')
    await loadAccounts()
  } catch (error) {
    errorMessage.value = error?.message || 'Failed to save transaction.'
  } finally {
    saving.value = false
  }
}

onMounted(loadAccounts)
</script>
