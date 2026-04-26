<script setup>
import { reactive } from "vue";

const form = reactive({
  transaction_type: "expense",
  account_id: "",
  category_id: "",
  amount: "",
  transaction_date: "",
  description: "",
});

const submitTransaction = () => {
  console.log("Transaction submitted:", form);

  /*
    Later connect to:
    POST /api/v1/finance/transactions
  */
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-900">
        Add Transaction
      </h2>
      <p class="text-sm text-slate-500 mt-1">
        Record income, expense, or transfer.
      </p>
    </div>

    <form @submit.prevent="submitTransaction" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">
          Transaction Type
        </label>

        <select
          v-model="form.transaction_type"
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
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
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
        >
          <option value="">Select account</option>
          <option value="main">Main Account</option>
          <option value="savings">Savings Account</option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">
          Category
        </label>

        <select
          v-model="form.category_id"
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
        >
          <option value="">Select category</option>
          <option value="salary">Salary</option>
          <option value="groceries">Groceries</option>
          <option value="transport">Transport</option>
          <option value="health">Health</option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">
          Amount
        </label>

        <input
          v-model="form.amount"
          type="number"
          min="0"
          step="0.01"
          placeholder="0.00"
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">
          Transaction Date
        </label>

        <input
          v-model="form.transaction_date"
          type="date"
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
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
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
        ></textarea>
      </div>

      <button
        type="submit"
        class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 rounded-xl transition"
      >
        Save Transaction
      </button>
    </form>
  </div>
</template>