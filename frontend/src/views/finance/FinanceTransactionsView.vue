<template>
  <div class="p-6 bg-slate-50 min-h-screen">
    <!-- Page Header -->
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-slate-900">
        Finance Transactions
      </h1>
      <p class="text-sm text-slate-500 mt-1">
        Search, manage, and create income, expense, and transfer transactions.
      </p>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-5 mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Search
          </label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Search transactions..."
            class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Type
          </label>
          <select
            v-model="filters.type"
            class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">All Types</option>
            <option value="income">Income</option>
            <option value="expense">Expense</option>
            <option value="transfer">Transfer</option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            From Date
          </label>
          <input
            v-model="filters.date_from"
            type="date"
            class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            To Date
          </label>
          <input
            v-model="filters.date_to"
            type="date"
            class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Recent Transactions -->
      <div class="xl:col-span-2 bg-white rounded-xl border border-slate-200 shadow-sm p-5">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-slate-900">
              Recent Transactions
            </h2>
            <p class="text-sm text-slate-500">
              Latest income, expenses, and transfers.
            </p>
          </div>

          <button
            type="button"
            @click="fetchTransactions"
            class="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
          >
            Refresh
          </button>
        </div>

        <div
          v-if="loading"
          class="py-10 text-center text-slate-500"
        >
          Loading transactions...
        </div>

        <div
          v-else-if="errorMessage"
          class="py-4 px-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm"
        >
          {{ errorMessage }}
        </div>

        <div
          v-else-if="filteredTransactions.length === 0"
          class="py-10 text-center text-slate-500"
        >
          No transactions found.
        </div>

        <div
          v-else
          class="overflow-x-auto"
        >
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left text-slate-600">
                <th class="py-3 pr-4">Date</th>
                <th class="py-3 pr-4">Category</th>
                <th class="py-3 pr-4">Account</th>
                <th class="py-3 pr-4">Description</th>
                <th class="py-3 pr-4">Type</th>
                <th class="py-3 pr-4 text-right">Amount</th>
                <th class="py-3 pr-4">Status</th>
                <th class="py-3 text-right">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="transaction in filteredTransactions"
                :key="transaction.id"
                class="border-b border-slate-100 hover:bg-slate-50"
              >
                <td class="py-3 pr-4 text-slate-700">
                  {{ formatDate(getTransactionDate(transaction)) }}
                </td>

                <td class="py-3 pr-4 font-medium text-slate-900">
                  {{ getTransactionCategory(transaction) }}
                </td>

                <td class="py-3 pr-4 text-slate-700">
                  {{ getAccountName(transaction) }}
                </td>

                <td class="py-3 pr-4 text-slate-700">
                  {{ transaction.description || transaction.notes || '—' }}
                </td>

                <td class="py-3 pr-4">
                  <span
                    class="px-2 py-1 rounded-full text-xs font-medium"
                    :class="typeClass(getTransactionType(transaction))"
                  >
                    {{ normalizeType(getTransactionType(transaction)) }}
                  </span>
                </td>

                <td
                  class="py-3 pr-4 text-right font-semibold"
                  :class="amountClass(getTransactionType(transaction))"
                >
                  {{ amountPrefix(getTransactionType(transaction)) }}{{ formatMoney(getTransactionAmount(transaction)) }}
                </td>

                <td class="py-3 pr-4">
                  <span class="px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                    {{ getTransactionStatus(transaction) }}
                  </span>
                </td>

                <td class="py-3 text-right whitespace-nowrap">
                  <button
                    type="button"
                    @click="startEdit(transaction)"
                    class="text-indigo-600 hover:text-indigo-800 text-sm font-medium mr-3"
                  >
                    Edit
                  </button>

                  <button
                    type="button"
                    @click="deleteTransaction(transaction.id)"
                    class="text-red-600 hover:text-red-800 text-sm font-medium"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Add / Edit Transaction -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-5">
        <h2 class="text-lg font-semibold text-slate-900">
          {{ editingId ? "Edit Transaction" : "Add Transaction" }}
        </h2>

        <p class="text-sm text-slate-500 mb-4">
          {{ editingId ? "Update selected transaction." : "Record income, expense, or transfer." }}
        </p>

        <div
          v-if="successMessage"
          class="mb-4 px-4 py-3 rounded-lg bg-green-50 border border-green-200 text-green-700 text-sm"
        >
          {{ successMessage }}
        </div>

        <div
          v-if="formError"
          class="mb-4 px-4 py-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm"
        >
          {{ formError }}
        </div>

        <form
          class="space-y-4"
          @submit.prevent="saveTransaction"
        >
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Transaction Type
            </label>
            <select
              v-model="form.type"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="income">Income</option>
              <option value="expense">Expense</option>
              <option value="transfer">Transfer</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Account
            </label>
            <select
              v-model="form.account_id"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select account</option>
              <option
                v-for="account in accounts"
                :key="getAccountId(account)"
                :value="getAccountId(account)"
              >
                {{ getAccountDisplayName(account) }} — {{ getAccountCurrency(account) }}
              </option>
            </select>
          </div>

          <div v-if="form.type === 'transfer'">
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Transfer To Account
            </label>
            <select
              v-model="form.transfer_account_id"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select destination account</option>
              <option
                v-for="account in destinationAccounts"
                :key="getAccountId(account)"
                :value="getAccountId(account)"
              >
                {{ getAccountDisplayName(account) }} — {{ getAccountCurrency(account) }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Category
            </label>
            <select
              v-model="form.category"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select category</option>
              <option
                v-for="category in filteredCategories"
                :key="category.id || category.category_id"
                :value="category.name || category.category_name"
              >
                {{ category.name || category.category_name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Amount
            </label>
            <input
              v-model="form.amount"
              type="number"
              min="0.01"
              step="0.01"
              placeholder="0.00"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Transaction Date
            </label>
            <input
              v-model="form.transaction_date"
              type="date"
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Description
            </label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Optional notes..."
              class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            ></textarea>
          </div>

          <button
            type="submit"
            :disabled="saving"
            class="w-full rounded-lg bg-indigo-600 text-white py-2.5 text-sm font-semibold hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ saving ? "Saving..." : editingId ? "Update Transaction" : "Save Transaction" }}
          </button>

          <button
            v-if="editingId"
            type="button"
            @click="resetForm"
            class="w-full rounded-lg border border-slate-300 text-slate-700 py-2.5 text-sm font-semibold hover:bg-slate-50"
          >
            Cancel Edit
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from "vue";
import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api/v1";

const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const formError = ref("");
const successMessage = ref("");

const accounts = ref([]);
const transactions = ref([]);
const categories = ref([]);
const editingId = ref(null);

const filters = reactive({
  search: "",
  type: "",
  date_from: "",
  date_to: "",
});

const form = reactive({
  type: "expense",
  account_id: "",
  transfer_account_id: "",
  category: "",
  amount: "",
  transaction_date: new Date().toISOString().slice(0, 10),
  description: "",
});

const authHeaders = () => {
  const token =
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token") ||
    sessionStorage.getItem("token") ||
    sessionStorage.getItem("auth_token") ||
    sessionStorage.getItem("access_token");

  return {
    Accept: "application/json",
    Authorization: token ? `Bearer ${token}` : "",
  };
};

const getApiData = (response) => {
  if (Array.isArray(response.data)) {
    return response.data;
  }

  if (Array.isArray(response.data?.data)) {
    return response.data.data;
  }

  if (Array.isArray(response.data?.data?.data)) {
    return response.data.data.data;
  }

  if (Array.isArray(response.data?.transactions)) {
    return response.data.transactions;
  }

  if (Array.isArray(response.data?.data?.transactions)) {
    return response.data.data.transactions;
  }

  if (Array.isArray(response.data?.accounts)) {
    return response.data.accounts;
  }

  if (Array.isArray(response.data?.data?.accounts)) {
    return response.data.data.accounts;
  }

  return [];
};
const getAccountId = (account) => {
  return (
    account.id ||
    account.account_id ||
    account.finance_account_id ||
    account.financeAccountId ||
    account.uuid ||
    ""
  );
};

const getAccountDisplayName = (account) => {
  return (
    account.name ||
    account.account_name ||
    account.accountName ||
    account.title ||
    account.label ||
    "Unnamed Account"
  );
};

const getAccountCurrency = (account) => {
  return (
    account.currency ||
    account.currency_code ||
    account.currencyCode ||
    "USD"
  );
};


const filteredCategories = computed(() => {
  if (form.type === "transfer") {
    return [];
  }

  return categories.value.filter((category) => {
    const status = String(category.status || "active").toLowerCase();
    const type = String(category.type || category.category_type || "").toLowerCase();

    return status === "active" && type === form.type;
  });
});

const destinationAccounts = computed(() => {
  return accounts.value.filter(
    (account) => String(getAccountId(account)) !== String(form.account_id)
  );
});
const fetchAccounts = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/finance/accounts`, {
      headers: authHeaders(),
    });

    accounts.value = getApiData(response);

    if (!form.account_id && accounts.value.length > 0) {
      form.account_id = getAccountId(accounts.value[0]);
    }
  } catch (error) {
    console.error("Failed to load accounts:", error);
  }
};

const fetchTransactions = async () => {
  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await axios.get(`${API_BASE_URL}/finance/transactions`, {
      headers: authHeaders(),
    });

    transactions.value = getApiData(response);
  } catch (error) {
    console.error("Failed to load transactions:", error);

    errorMessage.value =
      error.response?.data?.message ||
      error.response?.data?.error ||
      "Failed to load transactions.";
  } finally {
    loading.value = false;
  }
};

const getTransactionAccountId = (transaction) => {
  return (
    transaction.account_id ||
    transaction.finance_account_id ||
    transaction.financeAccountId ||
    transaction.accountId ||
    transaction.account?.id ||
    transaction.finance_account?.id ||
    transaction.financeAccount?.id ||
    ""
  );
};

const getTransactionTransferAccountId = (transaction) => {
  return (
    transaction.transfer_account_id ||
    transaction.to_account_id ||
    transaction.destination_account_id ||
    transaction.transferAccountId ||
    transaction.toAccountId ||
    ""
  );
};

const getAccountName = (transaction) => {
  if (transaction.account_name) {
    return transaction.account_name;
  }

  if (transaction.accountName) {
    return transaction.accountName;
  }

  if (transaction.account?.name) {
    return transaction.account.name;
  }

  if (transaction.finance_account?.name) {
    return transaction.finance_account.name;
  }

  if (transaction.financeAccount?.name) {
    return transaction.financeAccount.name;
  }

  const accountId = getTransactionAccountId(transaction);

  const account = accounts.value.find(
    (item) => String(getAccountId(item)) === String(accountId)
  );

  return account ? getAccountDisplayName(account) : "Unknown Account";
};

const getTransactionType = (transaction) => {
  return (
    transaction.type ||
    transaction.transaction_type ||
    transaction.transactionType ||
    transaction.kind ||
    transaction.transaction_kind ||
    transaction.transactionKind ||
    ""
  );
};

const getTransactionCategory = (transaction) => {
  return (
    transaction.category ||
    transaction.category_name ||
    transaction.categoryName ||
    transaction.finance_category?.name ||
    transaction.financeCategory?.name ||
    "-"
  );
};

const getTransactionDate = (transaction) => {
  return (
    transaction.transaction_date ||
    transaction.date ||
    transaction.transactionDate ||
    transaction.posted_date ||
    transaction.postedDate ||
    transaction.created_at ||
    ""
  );
};

const getTransactionAmount = (transaction) => {
  return (
    transaction.amount ||
    transaction.transaction_amount ||
    transaction.transactionAmount ||
    transaction.value ||
    0
  );
};

const getTransactionStatus = (transaction) => {
  return (
    transaction.status ||
    transaction.transaction_status ||
    transaction.transactionStatus ||
    "Completed"
  );
};

const filteredTransactions = computed(() => {
  let list = [...transactions.value];

  if (filters.search) {
    const q = filters.search.toLowerCase();

    list = list.filter((transaction) => {
      return (
        String(getTransactionCategory(transaction)).toLowerCase().includes(q) ||
        String(transaction.description || "").toLowerCase().includes(q) ||
        String(transaction.notes || "").toLowerCase().includes(q) ||
        String(getTransactionType(transaction)).toLowerCase().includes(q) ||
        String(getTransactionStatus(transaction)).toLowerCase().includes(q) ||
        String(getAccountName(transaction)).toLowerCase().includes(q)
      );
    });
  }

  if (filters.type) {
    list = list.filter(
      (transaction) =>
        String(getTransactionType(transaction)).toLowerCase() ===
        filters.type.toLowerCase()
    );
  }

  if (filters.date_from) {
    list = list.filter(
      (transaction) =>
        String(getTransactionDate(transaction)).slice(0, 10) >= filters.date_from
    );
  }

  if (filters.date_to) {
    list = list.filter(
      (transaction) =>
        String(getTransactionDate(transaction)).slice(0, 10) <= filters.date_to
    );
  }

  return list;
});

const validateForm = () => {
  formError.value = "";

  if (!form.type) {
    formError.value = "Please select a transaction type.";
    return false;
  }

  if (!form.account_id) {
    formError.value = "Please select an account.";
    return false;
  }

  if (form.type === "transfer" && !form.transfer_account_id) {
    formError.value = "Please select the destination account for the transfer.";
    return false;
  }

  if (form.type === "transfer" && String(form.transfer_account_id) === String(form.account_id)) {
    formError.value = "Source and destination accounts must be different.";
    return false;
  }

  if (!form.category) {
    formError.value = "Please select a category.";
    return false;
  }

  if (!form.amount || Number(form.amount) <= 0) {
    formError.value = "Amount must be greater than zero.";
    return false;
  }

  if (!form.transaction_date) {
    formError.value = "Please select a transaction date.";
    return false;
  }

  return true;
};

const saveTransaction = async () => {
  if (!validateForm()) {
    return;
  }

  saving.value = true;
  formError.value = "";
  successMessage.value = "";

  const payload = {
    type: form.type,
    transaction_type: form.type,

    account_id: form.account_id,
    finance_account_id: form.account_id,
    transfer_account_id: form.type === "transfer" ? form.transfer_account_id : null,

    category: form.category,
    amount: Number(form.amount),
    transaction_date: form.transaction_date,
    date: form.transaction_date,
    description: form.description,
    status: "Completed",
  };

  try {
    if (editingId.value) {
      await axios.put(
        `${API_BASE_URL}/finance/transactions/${editingId.value}`,
        payload,
        {
          headers: {
            ...authHeaders(),
            "Content-Type": "application/json",
          },
        }
      );

      successMessage.value = "Transaction updated successfully.";
    } else {
      await axios.post(`${API_BASE_URL}/finance/transactions`, payload, {
        headers: {
          ...authHeaders(),
          "Content-Type": "application/json",
        },
      });

      successMessage.value = "Transaction saved successfully.";
    }

    await fetchTransactions();
    await fetchAccounts();
    resetForm(false);
  } catch (error) {
    console.error("Failed to save transaction:", error);

    if (error.response?.data?.errors) {
      const firstErrorKey = Object.keys(error.response.data.errors)[0];
      formError.value = error.response.data.errors[firstErrorKey][0];
    } else {
      formError.value =
        error.response?.data?.message ||
        error.response?.data?.error ||
        "Failed to save transaction.";
    }
  } finally {
    saving.value = false;
  }
};

const startEdit = (transaction) => {
  editingId.value = transaction.id;

  form.type = getTransactionType(transaction) || "expense";
  form.account_id = getTransactionAccountId(transaction) || "";
  form.transfer_account_id = getTransactionTransferAccountId(transaction) || "";
  form.category = getTransactionCategory(transaction) === "-"
    ? ""
    : getTransactionCategory(transaction);
  form.amount = getTransactionAmount(transaction) || "";
  form.transaction_date = String(getTransactionDate(transaction) || "").slice(0, 10);
  form.description = transaction.description || transaction.notes || "";

  successMessage.value = "";
  formError.value = "";
};

const deleteTransaction = async (id) => {
  const confirmed = window.confirm(
    "Are you sure you want to delete this transaction?"
  );

  if (!confirmed) {
    return;
  }

  try {
    await axios.delete(`${API_BASE_URL}/finance/transactions/${id}`, {
      headers: authHeaders(),
    });

    successMessage.value = "Transaction deleted successfully.";

    await fetchTransactions();
    await fetchAccounts();
  } catch (error) {
    console.error("Failed to delete transaction:", error);

    errorMessage.value =
      error.response?.data?.message ||
      error.response?.data?.error ||
      "Failed to delete transaction.";
  }
};

const resetForm = (clearMessage = true) => {
  editingId.value = null;

  form.type = "expense";
  form.account_id = accounts.value.length > 0 ? getAccountId(accounts.value[0]) : "";
  form.transfer_account_id = "";
  form.category = "";
  form.amount = "";
  form.transaction_date = new Date().toISOString().slice(0, 10);
  form.description = "";

  formError.value = "";

  if (clearMessage) {
    successMessage.value = "";
  }
};

const formatMoney = (amount) => {
  const value = Number(amount || 0);

  return value.toLocaleString("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
};

const formatDate = (date) => {
  if (!date) {
    return "-";
  }

  return String(date).slice(0, 10);
};

const normalizeType = (type) => {
  if (!type) {
    return "-";
  }

  return String(type).charAt(0).toUpperCase() + String(type).slice(1);
};

const amountPrefix = (type) => {
  if (type === "income") {
    return "+$";
  }

  if (type === "expense") {
    return "-$";
  }

  return "$";
};

const typeClass = (type) => {
  if (type === "income") {
    return "bg-green-100 text-green-700";
  }

  if (type === "expense") {
    return "bg-red-100 text-red-700";
  }

  if (type === "transfer") {
    return "bg-blue-100 text-blue-700";
  }

  return "bg-slate-100 text-slate-700";
};

const amountClass = (type) => {
  if (type === "income") {
    return "text-green-700";
  }

  if (type === "expense") {
    return "text-red-700";
  }

  return "text-slate-900";
};

watch(
  () => form.type,
  () => {
    form.category = "";
    form.transfer_account_id = "";
  }
);

onMounted(async () => {
  await fetchAccounts();
  await fetchTransactions();
});
</script>