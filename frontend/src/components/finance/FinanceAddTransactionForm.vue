<template>
  <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <h2 class="text-lg font-semibold text-slate-900">Add Transaction</h2>
    <p class="mb-5 text-sm text-slate-500">
      Record income, expense, or transfer.
    </p>

    <div
      v-if="error"
      class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ error }}
    </div>

    <div
      v-if="successMessage"
      class="mb-4 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700"
    >
      {{ successMessage }}
    </div>

    <form class="space-y-4" @submit.prevent="saveTransaction">
      <!-- Transaction Type -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Transaction Type
        </label>

        <select
          v-model="form.transaction_type"
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          required
        >
          <option value="expense">Expense</option>
          <option value="income">Income</option>
        </select>
      </div>

      <!-- Account -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Account
        </label>

        <select
          v-model="form.account_id"
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          required
        >
          <option disabled value="">Select account</option>

          <option
            v-for="account in accounts"
            :key="account.id"
            :value="account.id"
          >
            {{ account.account_name || account.name }} —
            {{ account.currency_code || "USD" }}
          </option>
        </select>

        <p v-if="accounts.length === 0" class="mt-1 text-xs text-red-500">
          No accounts found. Create a finance account first.
        </p>
      </div>

      <!-- Category -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Category
        </label>

        <select
          v-model="form.category"
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
        >
          <option value="">Select category</option>
          <option value="Groceries">Groceries</option>
          <option value="Salary">Salary</option>
          <option value="Transport">Transport</option>
          <option value="Restaurants">Restaurants</option>
          <option value="Health">Health</option>
          <option value="Shopping">Shopping</option>
          <option value="Other">Other</option>
        </select>
      </div>

      <!-- Amount -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Amount
        </label>

        <input
          v-model.number="form.amount"
          type="number"
          min="0.01"
          step="0.01"
          placeholder="0.00"
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          required
        />
      </div>

      <!-- Transaction Date -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Transaction Date
        </label>

        <input
          v-model="form.transaction_date"
          type="date"
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          required
        />
      </div>

      <!-- Description -->
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700">
          Description
        </label>

        <textarea
          v-model="form.description"
          rows="3"
          placeholder="Optional notes..."
          class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
        ></textarea>
      </div>

      <button
        type="submit"
        :disabled="loading || accounts.length === 0"
        class="w-full rounded-xl bg-indigo-600 px-5 py-3 text-sm font-semibold text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {{ loading ? "Saving..." : "Save Transaction" }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";

const emit = defineEmits(["saved"]);

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000";

const loading = ref(false);
const error = ref("");
const successMessage = ref("");
const accounts = ref([]);

const form = ref({
  transaction_type: "expense",
  account_id: "",
  category: "",
  amount: "",
  currency_code: "USD",
  transaction_date: new Date().toISOString().slice(0, 10),
  description: "",
});

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const loadAccounts = async () => {
  try {
    error.value = "";

    const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
      method: "GET",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    console.log("Finance accounts loaded:", result);

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load accounts.");
    }

    accounts.value = Array.isArray(result.data) ? result.data : [];

    if (accounts.value.length > 0) {
      form.value.account_id = accounts.value[0].id;
      form.value.currency_code = accounts.value[0].currency_code || "USD";
    }
  } catch (err) {
    console.error("Load finance accounts error:", err);
    error.value = err.message || "Failed to load finance accounts.";
  }
};

const saveTransaction = async () => {
  try {
    loading.value = true;
    error.value = "";
    successMessage.value = "";

    if (!form.value.account_id) {
      throw new Error("Please select an account.");
    }

    if (!form.value.amount || Number(form.value.amount) <= 0) {
      throw new Error("Please enter a valid amount.");
    }

    if (!form.value.transaction_date) {
      throw new Error("Please select a transaction date.");
    }

    const selectedAccount = accounts.value.find(
      (account) => account.id === form.value.account_id
    );

    const payload = {
      transaction_type: form.value.transaction_type,
      account_id: form.value.account_id,
      category: form.value.category || null,
      amount: Number(form.value.amount),
      currency_code: selectedAccount?.currency_code || form.value.currency_code || "USD",
      transaction_date: form.value.transaction_date,
      description: form.value.description || null,
    };

    console.log("Sending transaction payload:", payload);

    const response = await fetch(`${API_BASE_URL}/finance/transactions`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token()}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      console.error("Save transaction API error:", result);

      const backendError =
        result.error ||
        result.message ||
        result.errors?.account_id?.[0] ||
        result.errors?.transaction_type?.[0] ||
        result.errors?.amount?.[0] ||
        "Failed to save transaction.";

      throw new Error(backendError);
    }

    successMessage.value = "Transaction saved successfully.";

    form.value = {
      transaction_type: "expense",
      account_id: accounts.value[0]?.id || "",
      category: "",
      amount: "",
      currency_code: accounts.value[0]?.currency_code || "USD",
      transaction_date: new Date().toISOString().slice(0, 10),
      description: "",
    };

    emit("saved", result.data);
  } catch (err) {
    console.error("Save transaction error:", err);
    error.value = err.message || "Failed to save transaction.";
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  loadAccounts();
});
</script>