<template>
  <div class="min-h-screen bg-slate-50 px-8 py-10">
    <!-- Header -->
    <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <h1 class="text-4xl font-bold text-slate-950">Finance Budgets</h1>
        <p class="mt-3 text-lg text-slate-500">
          Track monthly budget planning, actual expenses, and spending status.
        </p>
      </div>

      <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
        <input
          v-model="selectedMonth"
          type="month"
          class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
          @change="fetchBudgets"
        />

        <button
          type="button"
          class="rounded-2xl bg-indigo-600 px-7 py-4 text-base font-bold text-white shadow-sm transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          :disabled="loading"
          @click="openCreateModal"
        >
          Add Budget
        </button>
      </div>
    </div>

    <!-- Alerts -->
    <div
      v-if="errorMessage"
      class="mb-6 rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div
      v-if="successMessage"
      class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-5 py-4 text-sm font-semibold text-emerald-700"
    >
      {{ successMessage }}
    </div>

    <!-- Loading -->
    <div
      v-if="loading"
      class="rounded-3xl border border-slate-200 bg-white p-10 text-center shadow-sm"
    >
      <p class="text-lg font-semibold text-slate-600">Loading budgets...</p>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="budgets.length === 0"
      class="rounded-3xl border border-dashed border-slate-300 bg-white p-12 text-center shadow-sm"
    >
      <h2 class="text-2xl font-bold text-slate-900">No budgets found</h2>
      <p class="mt-3 text-slate-500">
        Add your first monthly budget to start tracking planned and actual spending.
      </p>

      <button
        type="button"
        class="mt-6 rounded-2xl bg-indigo-600 px-7 py-4 text-base font-bold text-white transition hover:bg-indigo-700"
        @click="openCreateModal"
      >
        Add First Budget
      </button>
    </div>

    <!-- Table -->
    <div
      v-else
      class="overflow-hidden rounded-3xl border border-slate-200 bg-white p-8 shadow-sm"
    >
      <div class="overflow-x-auto">
        <table class="w-full min-w-[980px] border-collapse">
          <thead>
            <tr class="border-b border-slate-200 text-left text-sm font-bold text-slate-500">
              <th class="px-1 py-4">Budget Name</th>
              <th class="px-1 py-4">Category</th>
              <th class="px-1 py-4">Month</th>
              <th class="px-1 py-4 text-right">Planned</th>
              <th class="px-1 py-4 text-right">Actual</th>
              <th class="px-1 py-4">Usage</th>
              <th class="px-1 py-4">Status</th>
              <th class="px-1 py-4 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="budget in budgets"
              :key="budget.id"
              class="border-b border-slate-100 text-base text-slate-900 last:border-b-0"
            >
              <td class="px-1 py-5 font-bold">
                {{ budget.budget_name || "Untitled Budget" }}
              </td>

              <td class="px-1 py-5 text-slate-600">
                {{ displayCategory(budget) }}
              </td>

              <td class="px-1 py-5 text-slate-600">
                {{ formatBudgetMonth(budget.budget_month) }}
              </td>

              <td class="px-1 py-5 text-right text-slate-700">
                {{ formatMoney(budget.budget_amount, budget.currency_code) }}
              </td>

              <td class="px-1 py-5 text-right font-bold">
                {{ formatMoney(budget.spent_amount, budget.currency_code) }}
              </td>

              <td class="px-1 py-5">
                <div class="flex items-center gap-3">
                  <div class="h-4 w-44 overflow-hidden rounded-full bg-slate-100">
                    <div
                      class="h-full rounded-full transition-all"
                      :class="usageBarClass(budget)"
                      :style="{ width: progressWidth(budget) }"
                    ></div>
                  </div>

                  <span class="w-14 text-sm font-bold text-slate-700">
                    {{ normalizedUsage(budget) }}%
                  </span>
                </div>
              </td>

              <td class="px-1 py-5">
                <span
                  class="inline-flex rounded-full px-4 py-2 text-sm font-bold"
                  :class="statusBadgeClass(budget)"
                >
                  {{ statusText(budget) }}
                </span>
              </td>

              <td class="px-1 py-5">
                <div class="flex justify-end gap-4">
                  <button
                    type="button"
                    class="font-bold text-indigo-600 transition hover:text-indigo-800"
                    @click="openEditModal(budget)"
                  >
                    Edit
                  </button>

                  <button
                    type="button"
                    class="font-bold text-red-500 transition hover:text-red-700"
                    @click="deleteBudget(budget)"
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

    <!-- Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 px-4"
    >
      <div class="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl">
        <div class="mb-6 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-2xl font-bold text-slate-950">
              {{ editingBudgetId ? "Edit Budget" : "Add Budget" }}
            </h2>
            <p class="mt-2 text-sm text-slate-500">
              Create or update a monthly budget line.
            </p>
          </div>

          <button
            type="button"
            class="rounded-xl px-3 py-2 text-xl font-bold text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
            @click="closeModal"
          >
            ×
          </button>
        </div>

        <form class="grid grid-cols-1 gap-5 md:grid-cols-2" @submit.prevent="saveBudget">
          <div class="md:col-span-2">
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Budget Name
            </label>
            <input
              v-model.trim="form.budget_name"
              type="text"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              placeholder="May 2026 Food Budget"
              required
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Category
            </label>
            <input
              v-model.trim="form.category"
              type="text"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              placeholder="Food"
              required
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Month
            </label>
            <input
              v-model="form.budget_month"
              type="month"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              required
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Planned Amount
            </label>
            <input
              v-model.number="form.planned_amount"
              type="number"
              min="0"
              step="0.01"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              required
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Spent Amount
            </label>
            <input
              v-model.number="form.spent_amount"
              type="number"
              min="0"
              step="0.01"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              required
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Account
            </label>
            <select
              v-model="form.account_id"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
            >
              <option value="">No account</option>
              <option
                v-for="account in accounts"
                :key="account.id || account.account_id"
                :value="account.id || account.account_id"
              >
                {{ account.account_name }} — {{ account.currency_code }}
              </option>
            </select>
          </div>

          <div>
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Currency
            </label>
            <input
              v-model.trim="form.currency_code"
              type="text"
              class="w-full rounded-2xl border border-slate-200 px-4 py-3 uppercase outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              placeholder="USD"
              required
            />
          </div>

          <div class="md:col-span-2">
            <label class="mb-2 block text-sm font-bold text-slate-700">
              Notes
            </label>
            <textarea
              v-model.trim="form.notes"
              rows="3"
              class="w-full resize-none rounded-2xl border border-slate-200 px-4 py-3 outline-none transition focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
              placeholder="Optional notes"
            ></textarea>
          </div>

          <div class="mt-4 flex justify-end gap-3 md:col-span-2">
            <button
              type="button"
              class="rounded-2xl border border-slate-200 px-6 py-3 font-bold text-slate-600 transition hover:bg-slate-50"
              @click="closeModal"
            >
              Cancel
            </button>

            <button
              type="submit"
              class="rounded-2xl bg-indigo-600 px-7 py-3 font-bold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="saving"
            >
              {{ saving ? "Saving..." : "Save Budget" }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "/api/v1";

const budgets = ref([]);
const accounts = ref([]);
const loading = ref(false);
const saving = ref(false);
const showModal = ref(false);
const editingBudgetId = ref(null);
const errorMessage = ref("");
const successMessage = ref("");

const selectedMonth = ref(getCurrentMonth());

const form = reactive({
  budget_name: "",
  category: "Food",
  budget_month: getCurrentMonth(),
  planned_amount: 0,
  spent_amount: 0,
  account_id: "",
  currency_code: "USD",
  notes: "",
});

const token = computed(() => {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token") ||
    sessionStorage.getItem("token") ||
    sessionStorage.getItem("auth_token") ||
    sessionStorage.getItem("access_token") ||
    ""
  );
});

function authHeaders() {
  return {
    Accept: "application/json",
    "Content-Type": "application/json",
    Authorization: `Bearer ${token.value}`,
  };
}

function getCurrentMonth() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

function clearMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function normalizeBudget(rawBudget) {
  const lines = Array.isArray(rawBudget.lines) ? rawBudget.lines : [];
  const firstLine = lines[0] || {};

  const planned =
    Number(rawBudget.budget_amount ?? 0) ||
    Number(firstLine.planned_amount ?? 0) ||
    0;

  const spent =
    Number(rawBudget.spent_amount ?? 0) ||
    Number(firstLine.spent_amount ?? 0) ||
    0;

  const remaining =
    rawBudget.remaining_amount !== undefined
      ? Number(rawBudget.remaining_amount)
      : planned - spent;

  const usage =
    rawBudget.usage_percentage !== undefined
      ? Number(rawBudget.usage_percentage)
      : planned > 0
        ? Math.round((spent / planned) * 100)
        : 0;

  return {
    ...rawBudget,
    category: rawBudget.category || firstLine.category || "General",
    budget_amount: planned,
    spent_amount: spent,
    remaining_amount: remaining,
    usage_percentage: usage,
    is_over_budget:
      rawBudget.is_over_budget !== undefined
        ? Boolean(rawBudget.is_over_budget)
        : spent > planned,
  };
}

async function fetchBudgets() {
  loading.value = true;
  clearMessages();

  try {
    const url = `${API_BASE_URL}/finance/budgets?month=${encodeURIComponent(
      selectedMonth.value
    )}`;

    const response = await fetch(url, {
      method: "GET",
      headers: authHeaders(),
    });

    const payload = await response.json();

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || "Failed to load budgets.");
    }

    const data = Array.isArray(payload.data) ? payload.data : [];
    budgets.value = data.map(normalizeBudget);
  } catch (error) {
    budgets.value = [];
    errorMessage.value = error.message || "Failed to load budgets.";
  } finally {
    loading.value = false;
  }
}

async function fetchAccounts() {
  try {
    const response = await fetch(`${API_BASE_URL}/finance/accounts`, {
      method: "GET",
      headers: authHeaders(),
    });

    const payload = await response.json();

    if (response.ok && payload.success !== false) {
      accounts.value = Array.isArray(payload.data) ? payload.data : [];

      if (!form.account_id && accounts.value.length > 0) {
        form.account_id = accounts.value[0].id || accounts.value[0].account_id || "";
      }
    }
  } catch {
    accounts.value = [];
  }
}

function openCreateModal() {
  clearMessages();
  editingBudgetId.value = null;

  form.budget_name = "";
  form.category = "Food";
  form.budget_month = selectedMonth.value || getCurrentMonth();
  form.planned_amount = 0;
  form.spent_amount = 0;
  form.currency_code = "USD";
  form.notes = "";

  if (accounts.value.length > 0) {
    form.account_id = accounts.value[0].id || accounts.value[0].account_id || "";
  }

  showModal.value = true;
}

function openEditModal(budget) {
  clearMessages();
  editingBudgetId.value = budget.id;

  const firstLine = Array.isArray(budget.lines) && budget.lines.length > 0
    ? budget.lines[0]
    : {};

  form.budget_name = budget.budget_name || "";
  form.category = budget.category || firstLine.category || "General";
  form.budget_month = normalizeMonthForInput(budget.budget_month);
  form.planned_amount = Number(budget.budget_amount || firstLine.planned_amount || 0);
  form.spent_amount = Number(budget.spent_amount || firstLine.spent_amount || 0);
  form.account_id = firstLine.account_id || "";
  form.currency_code = budget.currency_code || "USD";
  form.notes = budget.notes || "";

  showModal.value = true;
}

function closeModal() {
  showModal.value = false;
  editingBudgetId.value = null;
}

async function saveBudget() {
  saving.value = true;
  clearMessages();

  try {
    const payload = {
      budget_name: form.budget_name,
      category: form.category,
      budget_month: form.budget_month,
      currency_code: form.currency_code || "USD",
      is_active: true,
      notes: form.notes || null,
      lines: [
        {
          account_id: form.account_id || null,
          category: form.category,
          planned_amount: Number(form.planned_amount || 0),
          actual_amount: 0,
          spent_amount: Number(form.spent_amount || 0),
          warning_percentage: 80,
          exceeded_percentage: 100,
          line_notes: `${form.category} budget line`,
        },
      ],
    };

    const isEdit = Boolean(editingBudgetId.value);
    const url = isEdit
      ? `${API_BASE_URL}/finance/budgets/${editingBudgetId.value}`
      : `${API_BASE_URL}/finance/budgets`;

    const response = await fetch(url, {
      method: isEdit ? "PUT" : "POST",
      headers: authHeaders(),
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok || result.success === false) {
      throw new Error(result.message || "Failed to save budget.");
    }

    successMessage.value = isEdit
      ? "Budget updated successfully."
      : "Budget created successfully.";

    closeModal();
    await fetchBudgets();
  } catch (error) {
    errorMessage.value = error.message || "Failed to save budget.";
  } finally {
    saving.value = false;
  }
}

async function deleteBudget(budget) {
  const confirmed = window.confirm(
    `Delete budget "${budget.budget_name}"? This action cannot be undone.`
  );

  if (!confirmed) return;

  clearMessages();

  try {
    const response = await fetch(`${API_BASE_URL}/finance/budgets/${budget.id}`, {
      method: "DELETE",
      headers: authHeaders(),
    });

    const payload = await response.json();

    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || "Failed to delete budget.");
    }

    successMessage.value = "Budget deleted successfully.";
    await fetchBudgets();
  } catch (error) {
    errorMessage.value = error.message || "Failed to delete budget.";
  }
}

function normalizedUsage(budget) {
  return Math.round(Number(budget.usage_percentage || 0));
}

function progressWidth(budget) {
  const usage = Number(budget.usage_percentage || 0);
  return `${Math.min(Math.max(usage, 0), 100)}%`;
}

function statusText(budget) {
  const usage = Number(budget.usage_percentage || 0);

  if (budget.is_over_budget || usage > 100) return "Exceeded";
  if (usage >= 80) return "Warning";
  return "Safe";
}

function usageBarClass(budget) {
  const usage = Number(budget.usage_percentage || 0);

  if (budget.is_over_budget || usage > 100) return "bg-red-500";
  if (usage >= 80) return "bg-amber-500";
  return "bg-emerald-500";
}

function statusBadgeClass(budget) {
  const status = statusText(budget);

  if (status === "Exceeded") {
    return "bg-red-50 text-red-700";
  }

  if (status === "Warning") {
    return "bg-amber-50 text-amber-700";
  }

  return "bg-emerald-50 text-emerald-700";
}

function displayCategory(budget) {
  if (budget.category) return budget.category;

  if (Array.isArray(budget.lines) && budget.lines.length > 0) {
    return budget.lines[0].category || "General";
  }

  return "General";
}

function normalizeMonthForInput(value) {
  if (!value) return getCurrentMonth();

  const stringValue = String(value);
  const match = stringValue.match(/^(\d{4})-(\d{2})/);

  if (match) {
    return `${match[1]}-${match[2]}`;
  }

  return getCurrentMonth();
}

function formatBudgetMonth(value) {
  const normalized = normalizeMonthForInput(value);
  const [year, month] = normalized.split("-");

  const date = new Date(Number(year), Number(month) - 1, 1);

  return date.toLocaleDateString("en-US", {
    month: "long",
    year: "numeric",
  });
}

function formatMoney(value, currency = "USD") {
  const amount = Number(value || 0);

  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: currency || "USD",
    minimumFractionDigits: 2,
  }).format(amount);
}

onMounted(async () => {
  await fetchAccounts();
  await fetchBudgets();
});
</script>