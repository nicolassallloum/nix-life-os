STEP 7 — Finance Frontend UI
Vue 3 + Tailwind CSS Finance Module
Goal

Build the Finance Frontend Module for NIX LIFE OS using:

Vue 3
Vite
Tailwind CSS
Axios
Pinia
Chart.js
Laravel Finance APIs

This step creates the professional user interface for:

Finance Dashboard
Accounts
Transactions
Budgets
Financial Intelligence
Savings Forecast
Pay Yourself System
Expense Anomaly Detection
1. Updated Finance UI Folder Structure

Inside your Vue frontend project:

frontend/src
├── api
│   └── financeApi.js
│
├── components
│   └── finance
│       ├── FinanceDashboardCards.vue
│       ├── FinanceIncomeExpenseChart.vue
│       ├── FinanceTransactionsTable.vue
│       ├── FinanceAddTransactionForm.vue
│       ├── FinanceBudgetProgress.vue
│       ├── FinanceAccountSummary.vue
│       ├── FinanceForecastCard.vue
│       ├── FinancePayYourselfCard.vue
│       └── FinanceAnomalyAlerts.vue
│
├── layouts
│   └── AppLayout.vue
│
├── views
│   └── finance
│       ├── FinanceDashboardView.vue
│       ├── FinanceTransactionsView.vue
│       ├── FinanceBudgetsView.vue
│       ├── FinanceAccountsView.vue
│       └── FinanceIntelligenceView.vue
│
├── router
│   └── index.js
│
└── stores
    └── financeStore.js
2. Install Required Packages

Run inside the frontend folder:

cd /u01/nix-life-os/frontend

Install Axios:

npm install axios

Install Pinia:

npm install pinia

Install charts:

npm install chart.js vue-chartjs

Install icons:

npm install lucide-vue-next
3. Register Pinia in Vue

Open:

src/main.js

Update it like this:

import { createApp } from "vue";
import { createPinia } from "pinia";
import App from "./App.vue";
import router from "./router";
import "./assets/main.css";

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.mount("#app");
4. Create Finance API Layer

Create:

src/api/financeApi.js

Code:

import axios from "axios";

const api = axios.create({
  baseURL: "http://127.0.0.1:8000/api/v1",
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("auth_token");

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

export const financeApi = {
  getAccounts() {
    return api.get("/finance/accounts");
  },

  createAccount(payload) {
    return api.post("/finance/accounts", payload);
  },

  updateAccount(id, payload) {
    return api.put(`/finance/accounts/${id}`, payload);
  },

  deleteAccount(id) {
    return api.delete(`/finance/accounts/${id}`);
  },

  getCategories() {
    return api.get("/finance/categories");
  },

  getTransactions(params = {}) {
    return api.get("/finance/transactions", { params });
  },

  createTransaction(payload) {
    return api.post("/finance/transactions", payload);
  },

  updateTransaction(id, payload) {
    return api.put(`/finance/transactions/${id}`, payload);
  },

  deleteTransaction(id) {
    return api.delete(`/finance/transactions/${id}`);
  },

  getBudgets() {
    return api.get("/finance/budgets");
  },

  createBudget(payload) {
    return api.post("/finance/budgets", payload);
  },

  getDashboardSummary() {
    return api.get("/finance/dashboard-summary");
  },

  getForecast() {
    return api.get("/finance/forecast");
  },

  getAnomalies() {
    return api.get("/finance/anomalies");
  },

  getPayYourselfSettings() {
    return api.get("/finance/pay-yourself/settings");
  },
};
5. Create Finance Pinia Store

Create:

src/stores/financeStore.js

Code:

import { defineStore } from "pinia";
import { financeApi } from "@/api/financeApi";

export const useFinanceStore = defineStore("finance", {
  state: () => ({
    accounts: [],
    categories: [],
    transactions: [],
    budgets: [],
    dashboardSummary: null,
    forecast: null,
    anomalies: [],
    payYourselfSettings: null,

    loading: false,
    error: null,
  }),

  actions: {
    async loadFinanceDashboard() {
      this.loading = true;
      this.error = null;

      try {
        const [
          summaryRes,
          transactionsRes,
          budgetsRes,
          forecastRes,
          anomaliesRes,
        ] = await Promise.all([
          financeApi.getDashboardSummary(),
          financeApi.getTransactions(),
          financeApi.getBudgets(),
          financeApi.getForecast(),
          financeApi.getAnomalies(),
        ]);

        this.dashboardSummary = summaryRes.data.data ?? summaryRes.data;
        this.transactions = transactionsRes.data.data ?? transactionsRes.data;
        this.budgets = budgetsRes.data.data ?? budgetsRes.data;
        this.forecast = forecastRes.data.data ?? forecastRes.data;
        this.anomalies = anomaliesRes.data.data ?? anomaliesRes.data;
      } catch (error) {
        this.error =
          error.response?.data?.message ||
          "Failed to load finance dashboard data.";
      } finally {
        this.loading = false;
      }
    },

    async loadAccounts() {
      this.loading = true;
      this.error = null;

      try {
        const response = await financeApi.getAccounts();
        this.accounts = response.data.data ?? response.data;
      } catch (error) {
        this.error =
          error.response?.data?.message || "Failed to load accounts.";
      } finally {
        this.loading = false;
      }
    },

    async loadCategories() {
      try {
        const response = await financeApi.getCategories();
        this.categories = response.data.data ?? response.data;
      } catch (error) {
        this.error =
          error.response?.data?.message || "Failed to load categories.";
      }
    },

    async loadTransactions(params = {}) {
      this.loading = true;
      this.error = null;

      try {
        const response = await financeApi.getTransactions(params);
        this.transactions = response.data.data ?? response.data;
      } catch (error) {
        this.error =
          error.response?.data?.message || "Failed to load transactions.";
      } finally {
        this.loading = false;
      }
    },

    async createTransaction(payload) {
      this.loading = true;
      this.error = null;

      try {
        await financeApi.createTransaction(payload);
        await this.loadTransactions();
        await this.loadFinanceDashboard();
      } catch (error) {
        this.error =
          error.response?.data?.message || "Failed to create transaction.";
        throw error;
      } finally {
        this.loading = false;
      }
    },
  },
});
6. Finance Dashboard Layout

The Finance Dashboard should contain:

Finance Dashboard
│
├── Summary Cards
│   ├── Total Balance
│   ├── Monthly Income
│   ├── Monthly Expenses
│   └── Savings Rate
│
├── Intelligence Cards
│   ├── Savings Forecast
│   ├── Pay Yourself System
│   └── Expense Anomaly Alerts
│
├── Main Analytics
│   ├── Income vs Expenses Chart
│   └── Budget Progress
│
├── Recent Transactions Table
│
└── Add Transaction Form
7. Finance Dashboard View

Create:

src/views/finance/FinanceDashboardView.vue

Code:

<script setup>
import { onMounted } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

import FinanceDashboardCards from "@/components/finance/FinanceDashboardCards.vue";
import FinanceIncomeExpenseChart from "@/components/finance/FinanceIncomeExpenseChart.vue";
import FinanceTransactionsTable from "@/components/finance/FinanceTransactionsTable.vue";
import FinanceBudgetProgress from "@/components/finance/FinanceBudgetProgress.vue";
import FinanceAddTransactionForm from "@/components/finance/FinanceAddTransactionForm.vue";
import FinanceForecastCard from "@/components/finance/FinanceForecastCard.vue";
import FinancePayYourselfCard from "@/components/finance/FinancePayYourselfCard.vue";
import FinanceAnomalyAlerts from "@/components/finance/FinanceAnomalyAlerts.vue";

const financeStore = useFinanceStore();

onMounted(() => {
  financeStore.loadFinanceDashboard();
  financeStore.loadAccounts();
  financeStore.loadCategories();
});
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-slate-900">
        Finance Dashboard
      </h1>

      <p class="text-slate-500 mt-1">
        Track income, expenses, budgets, savings, and financial intelligence.
      </p>
    </div>

    <div
      v-if="financeStore.error"
      class="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-red-700"
    >
      {{ financeStore.error }}
    </div>

    <div
      v-if="financeStore.loading"
      class="mb-6 rounded-xl border border-slate-200 bg-white p-4 text-slate-600"
    >
      Loading finance data...
    </div>

    <FinanceDashboardCards />

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
      <FinanceForecastCard />
      <FinancePayYourselfCard />
      <FinanceAnomalyAlerts />
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
      <div class="xl:col-span-2">
        <FinanceIncomeExpenseChart />
      </div>

      <div>
        <FinanceBudgetProgress />
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
      <div class="xl:col-span-2">
        <FinanceTransactionsTable />
      </div>

      <div>
        <FinanceAddTransactionForm />
      </div>
    </div>
  </div>
</template>
8. Dashboard Cards Component

Create:

src/components/finance/FinanceDashboardCards.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const summary = computed(() => financeStore.dashboardSummary || {});

const formatCurrency = (amount) => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(Number(amount || 0));
};

const cards = computed(() => [
  {
    title: "Total Balance",
    value: formatCurrency(summary.value.total_balance),
    description: "Across all accounts",
  },
  {
    title: "Monthly Income",
    value: formatCurrency(summary.value.monthly_income),
    description: "Current month income",
  },
  {
    title: "Monthly Expenses",
    value: formatCurrency(summary.value.monthly_expenses),
    description: "Current month spending",
  },
  {
    title: "Savings Rate",
    value: `${summary.value.savings_rate || 0}%`,
    description: "Pay Yourself System",
  },
]);
</script>

<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
    <div
      v-for="card in cards"
      :key="card.title"
      class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5"
    >
      <h3 class="text-sm font-medium text-slate-500">
        {{ card.title }}
      </h3>

      <p class="text-3xl font-bold text-slate-900 mt-4">
        {{ card.value }}
      </p>

      <p class="text-sm text-slate-500 mt-2">
        {{ card.description }}
      </p>
    </div>
  </div>
</template>
9. Income vs Expenses Chart

Create:

src/components/finance/FinanceIncomeExpenseChart.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from "chart.js";

import { Bar } from "vue-chartjs";

ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
);

const financeStore = useFinanceStore();

const chartData = computed(() => {
  const chart = financeStore.dashboardSummary?.income_expense_chart || [];

  return {
    labels: chart.map((item) => item.month),
    datasets: [
      {
        label: "Income",
        data: chart.map((item) => item.income),
        backgroundColor: "#10b981",
        borderRadius: 8,
      },
      {
        label: "Expenses",
        data: chart.map((item) => item.expenses),
        backgroundColor: "#ef4444",
        borderRadius: 8,
      },
    ],
  };
});

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: "bottom",
    },
  },
  scales: {
    y: {
      beginAtZero: true,
    },
  },
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 h-[420px]">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-900">
        Income vs Expenses
      </h2>

      <p class="text-sm text-slate-500 mt-1">
        Monthly comparison between money earned and money spent.
      </p>
    </div>

    <div class="h-[320px]">
      <Bar :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>
10. Transactions Table Component

Create:

src/components/finance/FinanceTransactionsTable.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const transactions = computed(() => financeStore.transactions || []);

const formatCurrency = (amount) => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(Number(amount || 0));
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          Recent Transactions
        </h2>

        <p class="text-sm text-slate-500 mt-1">
          Latest income, expenses, and transfers.
        </p>
      </div>

      <RouterLink
        to="/finance/transactions"
        class="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
      >
        View All
      </RouterLink>
    </div>

    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-200 text-left text-slate-500">
            <th class="py-3 pr-4">Date</th>
            <th class="py-3 pr-4">Category</th>
            <th class="py-3 pr-4">Account</th>
            <th class="py-3 pr-4">Type</th>
            <th class="py-3 pr-4 text-right">Amount</th>
          </tr>
        </thead>

        <tbody>
          <tr
            v-for="transaction in transactions.slice(0, 5)"
            :key="transaction.transaction_id"
            class="border-b border-slate-100 hover:bg-slate-50"
          >
            <td class="py-4 pr-4 text-slate-700">
              {{ transaction.transaction_date }}
            </td>

            <td class="py-4 pr-4 font-medium text-slate-900">
              {{ transaction.category_name || "-" }}
            </td>

            <td class="py-4 pr-4 text-slate-600">
              {{ transaction.account_name || "-" }}
            </td>

            <td class="py-4 pr-4">
              <span
                class="px-2 py-1 rounded-full text-xs font-semibold capitalize"
                :class="{
                  'bg-emerald-50 text-emerald-700': transaction.transaction_type === 'income',
                  'bg-red-50 text-red-700': transaction.transaction_type === 'expense',
                  'bg-blue-50 text-blue-700': transaction.transaction_type === 'transfer'
                }"
              >
                {{ transaction.transaction_type }}
              </span>
            </td>

            <td class="py-4 pr-4 text-right font-semibold">
              {{ formatCurrency(transaction.amount) }}
            </td>
          </tr>
        </tbody>
      </table>

      <div
        v-if="transactions.length === 0"
        class="py-8 text-center text-slate-500"
      >
        No transactions found.
      </div>
    </div>
  </div>
</template>
11. Add Transaction Form Component

Create:

src/components/finance/FinanceAddTransactionForm.vue

Code:

<script setup>
import { reactive, computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const accounts = computed(() => financeStore.accounts || []);
const categories = computed(() => financeStore.categories || []);

const form = reactive({
  transaction_type: "expense",
  account_id: "",
  category_id: "",
  amount: "",
  transaction_date: "",
  description: "",
});

const resetForm = () => {
  form.transaction_type = "expense";
  form.account_id = "";
  form.category_id = "";
  form.amount = "";
  form.transaction_date = "";
  form.description = "";
};

const submitTransaction = async () => {
  await financeStore.createTransaction({
    transaction_type: form.transaction_type,
    account_id: form.account_id,
    category_id: form.category_id,
    amount: Number(form.amount),
    transaction_date: form.transaction_date,
    description: form.description,
  });

  resetForm();
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
          required
        >
          <option value="">Select account</option>

          <option
            v-for="account in accounts"
            :key="account.account_id"
            :value="account.account_id"
          >
            {{ account.account_name }}
          </option>
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

          <option
            v-for="category in categories"
            :key="category.category_id"
            :value="category.category_id"
          >
            {{ category.category_name }}
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
          min="0"
          step="0.01"
          placeholder="0.00"
          class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
          required
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
          required
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
12. Budget Progress Component

Create:

src/components/finance/FinanceBudgetProgress.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const budgets = computed(() => financeStore.budgets || []);

const getPercentage = (actual, planned) => {
  if (!planned) return 0;
  return Math.round((Number(actual) / Number(planned)) * 100);
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-900">
        Budget Progress
      </h2>

      <p class="text-sm text-slate-500 mt-1">
        Planned vs actual spending.
      </p>
    </div>

    <div class="space-y-5">
      <div
        v-for="budget in budgets"
        :key="budget.budget_id || budget.name"
      >
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium text-slate-700">
            {{ budget.category_name || budget.budget_name }}
          </span>

          <span class="text-sm font-semibold text-slate-900">
            {{ getPercentage(budget.actual_amount, budget.planned_amount) }}%
          </span>
        </div>

        <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
          <div
            class="h-3 rounded-full"
            :class="{
              'bg-emerald-500': budget.status === 'safe',
              'bg-amber-500': budget.status === 'warning',
              'bg-red-500': budget.status === 'exceeded'
            }"
            :style="{
              width:
                Math.min(
                  getPercentage(budget.actual_amount, budget.planned_amount),
                  100
                ) + '%'
            }"
          ></div>
        </div>

        <div class="flex justify-between mt-1 text-xs text-slate-500">
          <span>Actual: ${{ budget.actual_amount || 0 }}</span>
          <span>Planned: ${{ budget.planned_amount || 0 }}</span>
        </div>
      </div>

      <div
        v-if="budgets.length === 0"
        class="text-sm text-slate-500"
      >
        No active budgets found.
      </div>
    </div>
  </div>
</template>
13. Finance Forecast Card

Create:

src/components/finance/FinanceForecastCard.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const forecast = computed(() => financeStore.forecast || {});

const formatCurrency = (amount) => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(Number(amount || 0));
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <h2 class="text-lg font-bold text-slate-900">
      Savings Forecast
    </h2>

    <p class="text-sm text-slate-500 mt-1">
      Estimated end-of-month financial position.
    </p>

    <div class="mt-6">
      <p class="text-sm text-slate-500">
        Forecasted Savings
      </p>

      <p class="text-3xl font-bold text-emerald-600 mt-2">
        {{ formatCurrency(forecast.forecasted_savings) }}
      </p>
    </div>

    <div class="mt-4 text-sm text-slate-600">
      Expected Net Cash Flow:
      <span class="font-semibold text-slate-900">
        {{ formatCurrency(forecast.expected_net_cash_flow) }}
      </span>
    </div>
  </div>
</template>
14. Pay Yourself Card

Create:

src/components/finance/FinancePayYourselfCard.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const summary = computed(() => financeStore.dashboardSummary || {});
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <h2 class="text-lg font-bold text-slate-900">
      Pay Yourself System
    </h2>

    <p class="text-sm text-slate-500 mt-1">
      Automatic saving logic based on income.
    </p>

    <div class="mt-6">
      <p class="text-sm text-slate-500">
        Current Saving Rate
      </p>

      <p class="text-3xl font-bold text-indigo-600 mt-2">
        {{ summary.savings_rate || 0 }}%
      </p>
    </div>

    <div class="mt-4 text-sm text-slate-600">
      Recommended target:
      <span class="font-semibold text-slate-900">
        50% of income
      </span>
    </div>
  </div>
</template>
15. Expense Anomaly Alerts

Create:

src/components/finance/FinanceAnomalyAlerts.vue

Code:

<script setup>
import { computed } from "vue";
import { useFinanceStore } from "@/stores/financeStore";

const financeStore = useFinanceStore();

const anomalies = computed(() => financeStore.anomalies || []);
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <h2 class="text-lg font-bold text-slate-900">
      Expense Anomalies
    </h2>

    <p class="text-sm text-slate-500 mt-1">
      Unusual spending patterns detected.
    </p>

    <div class="mt-6 space-y-3">
      <div
        v-for="anomaly in anomalies.slice(0, 3)"
        :key="anomaly.anomaly_id || anomaly.message"
        class="rounded-xl border border-amber-200 bg-amber-50 p-3"
      >
        <p class="text-sm font-semibold text-amber-800">
          {{ anomaly.title || "Spending Alert" }}
        </p>

        <p class="text-sm text-amber-700 mt-1">
          {{ anomaly.message }}
        </p>
      </div>

      <div
        v-if="anomalies.length === 0"
        class="text-sm text-slate-500"
      >
        No unusual expenses detected.
      </div>
    </div>
  </div>
</template>
16. Router Configuration

Update:

src/router/index.js

Code:

import { createRouter, createWebHistory } from "vue-router";

import FinanceDashboardView from "@/views/finance/FinanceDashboardView.vue";
import FinanceTransactionsView from "@/views/finance/FinanceTransactionsView.vue";
import FinanceBudgetsView from "@/views/finance/FinanceBudgetsView.vue";
import FinanceAccountsView from "@/views/finance/FinanceAccountsView.vue";
import FinanceIntelligenceView from "@/views/finance/FinanceIntelligenceView.vue";

const routes = [
  {
    path: "/",
    redirect: "/finance",
  },
  {
    path: "/finance",
    name: "finance.dashboard",
    component: FinanceDashboardView,
  },
  {
    path: "/finance/transactions",
    name: "finance.transactions",
    component: FinanceTransactionsView,
  },
  {
    path: "/finance/accounts",
    name: "finance.accounts",
    component: FinanceAccountsView,
  },
  {
    path: "/finance/budgets",
    name: "finance.budgets",
    component: FinanceBudgetsView,
  },
  {
    path: "/finance/intelligence",
    name: "finance.intelligence",
    component: FinanceIntelligenceView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
17. Create Placeholder Views

Create:

src/views/finance/FinanceTransactionsView.vue
src/views/finance/FinanceAccountsView.vue
src/views/finance/FinanceBudgetsView.vue
src/views/finance/FinanceIntelligenceView.vue

Example placeholder:

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <h1 class="text-3xl font-bold text-slate-900">
      Finance Transactions
    </h1>

    <p class="text-slate-500 mt-1">
      Full transaction management page will be implemented in the next step.
    </p>
  </div>
</template>

Change the title for each view.

18. App Layout Sidebar

Create or update:

src/layouts/AppLayout.vue

Code:

<template>
  <div class="flex min-h-screen bg-slate-50">
    <aside class="w-64 min-h-screen bg-slate-900 text-white p-5">
      <h1 class="text-xl font-bold mb-8">
        NIX LIFE OS
      </h1>

      <nav class="space-y-2">
        <RouterLink
          to="/finance"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Finance Dashboard
        </RouterLink>

        <RouterLink
          to="/finance/transactions"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Transactions
        </RouterLink>

        <RouterLink
          to="/finance/accounts"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Accounts
        </RouterLink>

        <RouterLink
          to="/finance/budgets"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Budgets
        </RouterLink>

        <RouterLink
          to="/finance/intelligence"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Intelligence
        </RouterLink>
      </nav>
    </aside>

    <main class="flex-1">
      <RouterView />
    </main>
  </div>
</template>
19. Update App.vue

Open:

src/App.vue

Use:

<script setup>
import AppLayout from "@/layouts/AppLayout.vue";
</script>

<template>
  <AppLayout />
</template>
20. Finance UI Pages Included in STEP 7
Page 1 — /finance

Main finance dashboard:

Summary cards
Income vs expenses chart
Budget progress
Recent transactions
Savings forecast
Pay Yourself summary
Anomaly alerts
Quick add transaction
Page 2 — /finance/transactions

Full transaction management:

Search
Filters
Date range
Type filter
Category filter
Account filter
Paginated table
Add transaction
Edit transaction
Delete transaction
Page 3 — /finance/accounts

Account management:

List accounts
Account balance
Account type
Currency
Main account flag
Savings account flag
Create account
Edit account
Delete account
Page 4 — /finance/budgets

Budget intelligence:

Budget month selector
Budget lines
Planned vs actual
Warning status
Exceeded status
Budget usage charts
Page 5 — /finance/intelligence

Advanced finance intelligence:

Savings forecast
Pay Yourself automation
Expense anomaly detection
AI financial insights
Monthly recommendations
21. Final UI Design Standard

Use this style across all finance pages:

Background: slate-50
Cards: white
Card radius: rounded-2xl
Borders: slate-200
Shadow: shadow-sm
Primary button: indigo-600
Success: emerald-500
Warning: amber-500
Danger: red-500
Main text: slate-900
Secondary text: slate-500
Layout: clean enterprise dashboard
22. STEP 7 Completion Checklist

After this step, you should have:

[ ] Finance dashboard route
[ ] Sidebar navigation
[ ] Finance dashboard view
[ ] Dashboard summary cards
[ ] Income vs expenses chart
[ ] Recent transactions table
[ ] Add transaction form
[ ] Budget progress component
[ ] Forecast card
[ ] Pay Yourself card
[ ] Anomaly alerts card
[ ] Finance API service
[ ] Pinia finance store
[ ] Placeholder pages for accounts, transactions, budgets, and intelligence
[ ] Clean Tailwind dashboard layout
23. Updated Next Step

After finishing Step 7, continue with:

STEP 8 — Connect Vue Finance UI to Laravel APIs

Use this prompt:

Continue after STEP 7 — Finance Frontend UI.

Now connect the Vue Finance UI to the Laravel backend APIs.

Use:
- Axios
- Pinia
- Auth Bearer Token
- Loading states
- Error handling
- Real API data
- Form validation
- Refresh after create/update/delete

Connect these modules:
- Accounts
- Categories
- Transactions
- Budgets
- Dashboard summary
- Savings forecast
- Pay Yourself System
- Expense anomaly detection

Provide:
1. Updated financeApi.js
2. Updated financeStore.js
3. Updated FinanceDashboardCards.vue
4. Updated FinanceTransactionsTable.vue
5. Updated FinanceAddTransactionForm.vue
6. Updated FinanceBudgetProgress.vue
7. Updated FinanceForecastCard.vue
8. Updated FinancePayYourselfCard.vue
9. Updated FinanceAnomalyAlerts.vue
10. Full test commands
11. Expected API response format
12. Troubleshooting guide
Important Note

Your old Step 7 was mostly a static frontend design.
This updated Step 7 is better because it already prepares the frontend for real Laravel API integration by adding:

Axios service layer
Pinia finance store
Loading states
Error handling
Real component structure
Financial intelligence cards
Cleaner routing
Professional dashboard layout