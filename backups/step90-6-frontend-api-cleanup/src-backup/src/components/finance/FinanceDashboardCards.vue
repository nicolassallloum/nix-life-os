<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Finance Dashboard</h1>
        <p class="text-sm text-slate-500">
          Monitor accounts, income, expenses, budgets, and recent transactions.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
        :disabled="loading"
        @click="loadFinanceDashboard"
      >
        {{ loading ? "Refreshing..." : "Refresh" }}
      </button>
    </div>

    <!-- Error -->
    <div
      v-if="error"
      class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ error }}
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
      <div
        v-for="card in cards"
        :key="card.title"
        class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
      >
        <div class="flex items-start justify-between gap-3">
          <div>
            <p class="text-sm font-medium text-slate-500">
              {{ card.title }}
            </p>

            <h2 class="mt-2 text-2xl font-bold text-slate-900">
              {{ card.value }}
            </h2>

            <p class="mt-1 text-xs text-slate-500">
              {{ card.description }}
            </p>
          </div>

          <span
            class="rounded-full px-2.5 py-1 text-xs font-semibold"
            :class="card.change === 'Live'
              ? 'bg-indigo-50 text-indigo-700'
              : 'bg-slate-100 text-slate-600'"
          >
            {{ card.change }}
          </span>
        </div>
      </div>
    </div>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
      <!-- Left/Main Column -->
      <div class="space-y-6 xl:col-span-2">
        <!-- Income vs Expenses -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-5">
            <h2 class="text-lg font-semibold text-slate-900">Income vs Expenses</h2>
            <p class="text-sm text-slate-500">
              Monthly comparison between money earned and money spent.
            </p>
          </div>

          <div v-if="chartMonths.length === 0" class="py-12 text-center text-sm text-slate-500">
            No transaction data available for chart.
          </div>

          <div v-else class="space-y-4">
            <div
              v-for="month in chartMonths"
              :key="month.month"
              class="space-y-2"
            >
              <div class="flex items-center justify-between text-xs text-slate-500">
                <span class="font-medium text-slate-700">{{ month.month }}</span>
                <span>
                  Income: {{ formatMoney(month.income) }} |
                  Expenses: {{ formatMoney(month.expense) }}
                </span>
              </div>

              <div class="grid grid-cols-2 gap-3">
                <div>
                  <div class="h-3 rounded-full bg-slate-100">
                    <div
                      class="h-3 rounded-full bg-emerald-500"
                      :style="{ width: `${getChartWidth(month.income)}%` }"
                    ></div>
                  </div>
                  <p class="mt-1 text-xs text-emerald-600">Income</p>
                </div>

                <div>
                  <div class="h-3 rounded-full bg-slate-100">
                    <div
                      class="h-3 rounded-full bg-red-500"
                      :style="{ width: `${getChartWidth(month.expense)}%` }"
                    ></div>
                  </div>
                  <p class="mt-1 text-xs text-red-600">Expenses</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Transactions -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-4 flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold text-slate-900">Recent Transactions</h2>
              <p class="text-sm text-slate-500">
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

          <div
            v-if="transactionError"
            class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
          >
            {{ transactionError }}
          </div>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-left text-sm">
              <thead>
                <tr class="border-b border-slate-200 text-slate-500">
                  <th class="py-3 pr-4 font-medium">Date</th>
                  <th class="py-3 pr-4 font-medium">Category</th>
                  <th class="py-3 pr-4 font-medium">Account</th>
                  <th class="py-3 pr-4 font-medium">Type</th>
                  <th class="py-3 pr-4 font-medium text-right">Amount</th>
                  <th class="py-3 pr-4 font-medium">Status</th>
                </tr>
              </thead>

              <tbody>
                <tr v-if="loadingTransactions">
                  <td colspan="6" class="py-6 text-center text-sm text-slate-500">
                    Loading transactions...
                  </td>
                </tr>

                <tr v-else-if="recentTransactions.length === 0">
                  <td colspan="6" class="py-6 text-center text-sm text-slate-500">
                    No transactions found.
                  </td>
                </tr>

                <tr
                  v-else
                  v-for="transaction in recentTransactions"
                  :key="transaction.id"
                  class="border-b border-slate-100 text-slate-700"
                >
                  <td class="py-3 pr-4">
                    {{ formatDate(transaction.transaction_date) }}
                  </td>

                  <td class="py-3 pr-4 font-medium text-slate-800">
                    {{ transaction.category || "-" }}
                  </td>

                  <td class="py-3 pr-4">
                    {{ transaction.account?.account_name || "-" }}
                  </td>

                  <td class="py-3 pr-4">
                    <span
                      class="rounded-full px-2 py-1 text-xs font-medium capitalize"
                      :class="getTransactionTypeClass(transaction.transaction_type)"
                    >
                      {{ transaction.transaction_type || "-" }}
                    </span>
                  </td>

                  <td
                    class="py-3 pr-4 text-right font-semibold"
                    :class="transaction.transaction_type === 'income'
                      ? 'text-emerald-700'
                      : 'text-red-700'"
                  >
                    {{ transaction.transaction_type === "expense" ? "-" : "" }}
                    {{ formatMoney(transaction.amount, transaction.currency_code || "USD") }}
                  </td>

                  <td class="py-3 pr-4">
                    <span class="rounded-full bg-slate-100 px-2 py-1 text-xs text-slate-600">
                      Completed
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Right Column -->
      <div class="space-y-6">
        <!-- Budget Progress -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-5">
            <h2 class="text-lg font-semibold text-slate-900">Budget Progress</h2>
            <p class="text-sm text-slate-500">
              Planned vs actual spending.
            </p>
          </div>

          <div v-if="budgetProgress.length === 0" class="py-6 text-center text-sm text-slate-500">
            No budget data available.
          </div>

          <div v-else class="space-y-5">
            <div
              v-for="budget in budgetProgress"
              :key="budget.category"
              class="space-y-2"
            >
              <div class="flex items-center justify-between text-sm">
                <span class="font-medium text-slate-700">
                  {{ budget.category }}
                </span>
                <span class="font-semibold text-slate-800">
                  {{ budget.percentage }}%
                </span>
              </div>

              <div class="h-2.5 rounded-full bg-slate-100">
                <div
                  class="h-2.5 rounded-full"
                  :class="getBudgetColorClass(budget.percentage)"
                  :style="{ width: `${Math.min(budget.percentage, 100)}%` }"
                ></div>
              </div>

              <div class="flex items-center justify-between text-xs text-slate-500">
                <span>Actual: {{ formatMoney(budget.actual) }}</span>
                <span>Planned: {{ formatMoney(budget.planned) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Add Transaction Form -->
        <FinanceAddTransactionForm @saved="handleTransactionSaved" />

        <!-- Accounts Snapshot -->
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <div>
              <h2 class="text-lg font-semibold text-slate-900">Accounts</h2>
              <p class="text-sm text-slate-500">
                Current account balances.
              </p>
            </div>

            <RouterLink
              to="/finance/accounts"
              class="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
            >
              Manage
            </RouterLink>
          </div>

          <div v-if="accounts.length === 0" class="py-6 text-center text-sm text-slate-500">
            No accounts found.
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="account in accounts"
              :key="account.id"
              class="rounded-xl border border-slate-100 bg-slate-50 px-4 py-3"
            >
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="font-semibold text-slate-900">
                    {{ account.account_name }}
                  </p>
                  <p class="text-xs text-slate-500">
                    {{ account.account_type }} • {{ account.currency_code }}
                  </p>
                </div>

                <p
                  class="font-bold"
                  :class="Number(account.current_balance || 0) < 0
                    ? 'text-red-700'
                    : 'text-slate-900'"
                >
                  {{ formatMoney(account.current_balance, account.currency_code || "USD") }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading Overlay Text -->
    <div v-if="loading" class="text-center text-sm text-slate-500">
      Loading finance dashboard...
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import FinanceAddTransactionForm from "../../components/finance/FinanceAddTransactionForm.vue";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api/v1";

const accounts = ref([]);
const recentTransactions = ref([]);
const budgets = ref([]);

const loading = ref(false);
const loadingTransactions = ref(false);
const error = ref("");
const transactionError = ref("");

const token = () =>
  localStorage.getItem("token") ||
  localStorage.getItem("auth_token") ||
  localStorage.getItem("access_token");

const loadAccounts = async () => {
  const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token()}`,
    },
  });

  const result = await response.json();

  if (!response.ok || result.success === false) {
    throw new Error(result.message || "Failed to load accounts.");
  }

  accounts.value = Array.isArray(result.data) ? result.data : [];
};

const loadTransactions = async () => {
  try {
    loadingTransactions.value = true;
    transactionError.value = "";

    const response = await fetch(
      `${API_BASE_URL}/finance/transactions?per_page=5`,
      {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token()}`,
        },
      }
    );

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to load transactions.");
    }

    recentTransactions.value = Array.isArray(result.data?.data)
      ? result.data.data
      : [];
  } catch (err) {
    console.error("Load transactions error:", err);
    transactionError.value = err.message || "Failed to load transactions.";
  } finally {
    loadingTransactions.value = false;
  }
};

const loadBudgets = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/finance/budgets`, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token()}`,
      },
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      budgets.value = [];
      return;
    }

    if (Array.isArray(result.data)) {
      budgets.value = result.data;
      return;
    }

    if (Array.isArray(result.data?.data)) {
      budgets.value = result.data.data;
      return;
    }

    budgets.value = [];
  } catch (err) {
    console.warn("Budget data unavailable:", err);
    budgets.value = [];
  }
};

const loadFinanceDashboard = async () => {
  try {
    loading.value = true;
    error.value = "";

    await Promise.all([
      loadAccounts(),
      loadTransactions(),
      loadBudgets(),
    ]);
  } catch (err) {
    console.error("Finance dashboard load error:", err);
    error.value = err.message || "Failed to load finance dashboard.";
  } finally {
    loading.value = false;
  }
};

const totalBalance = computed(() => {
  return accounts.value.reduce((sum, account) => {
    return sum + Number(account.current_balance || 0);
  }, 0);
});

const currentMonthKey = computed(() => {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
});

const monthlyTransactions = computed(() => {
  return recentTransactions.value.filter((transaction) => {
    if (!transaction.transaction_date) return false;
    return formatDate(transaction.transaction_date).startsWith(currentMonthKey.value);
  });
});

const monthlyIncome = computed(() => {
  return monthlyTransactions.value
    .filter((transaction) => transaction.transaction_type === "income")
    .reduce((sum, transaction) => sum + Number(transaction.amount || 0), 0);
});

const monthlyExpenses = computed(() => {
  return monthlyTransactions.value
    .filter((transaction) => transaction.transaction_type === "expense")
    .reduce((sum, transaction) => sum + Number(transaction.amount || 0), 0);
});

const savingsRate = computed(() => {
  if (monthlyIncome.value <= 0) return 0;

  const savings = monthlyIncome.value - monthlyExpenses.value;
  return Math.round((savings / monthlyIncome.value) * 100);
});

const cards = computed(() => [
  {
    title: "Total Balance",
    value: formatMoney(totalBalance.value),
    change: "Live",
    description: "Across all accounts",
  },
  {
    title: "Monthly Income",
    value: formatMoney(monthlyIncome.value),
    change: "Live",
    description: "Current month income",
  },
  {
    title: "Monthly Expenses",
    value: formatMoney(monthlyExpenses.value),
    change: "Live",
    description: "Current month spending",
  },
  {
    title: "Savings Rate",
    value: `${savingsRate.value}%`,
    change: "Live",
    description: "Pay Yourself System",
  },
]);

const budgetProgress = computed(() => {
  if (budgets.value.length > 0) {
    return budgets.value.map((budget) => {
      const planned = Number(
        budget.budget_amount ||
        budget.planned_amount ||
        budget.amount ||
        0
      );

      const actual = Number(
        budget.spent_amount ||
        budget.actual_amount ||
        0
      );

      const percentage = planned > 0
        ? Math.round((actual / planned) * 100)
        : 0;

      return {
        category: budget.category || budget.budget_name || "Budget",
        planned,
        actual,
        percentage,
      };
    });
  }

  const categories = {};

  recentTransactions.value
    .filter((transaction) => transaction.transaction_type === "expense")
    .forEach((transaction) => {
      const category = transaction.category || "Other";

      if (!categories[category]) {
        categories[category] = {
          category,
          actual: 0,
          planned: 500,
        };
      }

      categories[category].actual += Number(transaction.amount || 0);
    });

  return Object.values(categories).map((item) => ({
    ...item,
    percentage: item.planned > 0
      ? Math.round((item.actual / item.planned) * 100)
      : 0,
  }));
});

const chartMonths = computed(() => {
  const grouped = {};

  recentTransactions.value.forEach((transaction) => {
    if (!transaction.transaction_date) return;

    const date = new Date(transaction.transaction_date);
    const month = date.toLocaleString("en-US", {
      month: "short",
      year: "numeric",
    });

    if (!grouped[month]) {
      grouped[month] = {
        month,
        income: 0,
        expense: 0,
      };
    }

    if (transaction.transaction_type === "income") {
      grouped[month].income += Number(transaction.amount || 0);
    }

    if (transaction.transaction_type === "expense") {
      grouped[month].expense += Number(transaction.amount || 0);
    }
  });

  return Object.values(grouped).slice(0, 6);
});

const maxChartValue = computed(() => {
  const values = chartMonths.value.flatMap((month) => [
    month.income,
    month.expense,
  ]);

  return Math.max(...values, 1);
});

const getChartWidth = (value) => {
  return Math.round((Number(value || 0) / maxChartValue.value) * 100);
};

const formatMoney = (amount, currency = "USD") => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
  }).format(Number(amount || 0));
};

const formatDate = (date) => {
  if (!date) return "-";
  return new Date(date).toISOString().slice(0, 10);
};

const getTransactionTypeClass = (type) => {
  if (type === "income") {
    return "bg-emerald-100 text-emerald-700";
  }

  if (type === "expense") {
    return "bg-red-100 text-red-700";
  }

  return "bg-blue-100 text-blue-700";
};

const getBudgetColorClass = (percentage) => {
  if (percentage >= 100) {
    return "bg-red-500";
  }

  if (percentage >= 80) {
    return "bg-orange-500";
  }

  return "bg-emerald-500";
};

const handleTransactionSaved = async () => {
  await loadFinanceDashboard();
};

onMounted(() => {
  loadFinanceDashboard();
});
</script>