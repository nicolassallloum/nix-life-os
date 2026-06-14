<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mx-auto max-w-3xl">
      <div class="mb-6 flex items-center justify-between gap-3">
        <div>
          <h1 class="text-3xl font-bold text-slate-900">Create Finance Category</h1>
          <p class="mt-1 text-sm text-slate-500">
            Add income or expense categories used by your finance transactions.
          </p>
        </div>

        <RouterLink
          to="/finance/dashboard"
          class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Back
        </RouterLink>
      </div>

      <div
        v-if="successMessage"
        class="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700"
      >
        {{ successMessage }}
      </div>

      <div
        v-if="errorMessage"
        class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
      >
        {{ errorMessage }}
      </div>

      <section class="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-slate-900">Existing Categories</h2>
            <p class="text-sm text-slate-500">Only created categories are used by Finance Transactions.</p>
          </div>

          <button
            type="button"
            class="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            @click="loadCategories"
          >
            Refresh
          </button>
        </div>

        <div v-if="loadingCategories" class="py-6 text-center text-slate-500">
          Loading categories...
        </div>

        <div v-else-if="categories.length === 0" class="py-6 text-center text-slate-500">
          No categories found.
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left text-slate-500">
                <th class="py-3 pr-4">Name</th>
                <th class="py-3 pr-4">Type</th>
                <th class="py-3 pr-4">Status</th>
                <th class="py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="category in categories" :key="category.id" class="border-b border-slate-100">
                <td class="py-3 pr-4 font-semibold text-slate-800">{{ category.name || category.category_name }}</td>
                <td class="py-3 pr-4 capitalize text-slate-600">{{ category.type || category.category_type }}</td>
                <td class="py-3 pr-4 text-slate-600">{{ category.status || 'active' }}</td>
                <td class="py-3 text-right">
                  <button
                    type="button"
                    class="font-semibold text-red-600 hover:text-red-800"
                    @click="deleteCategory(category)"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <form class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm" @submit.prevent="saveCategory">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Category Name</label>
            <input
              v-model="form.name"
              type="text"
              class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Food, Salary, Transport..."
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Type</label>
            <select
              v-model="form.type"
              class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="expense">Expense</option>
              <option value="income">Income</option>
            </select>
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Icon</label>
            <input
              v-model="form.icon"
              type="text"
              class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="💰"
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Color</label>
            <input
              v-model="form.color"
              type="text"
              class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="#4f46e5"
            />
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Status</label>
            <select
              v-model="form.status"
              class="w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <RouterLink
            to="/finance/dashboard"
            class="rounded-xl border border-slate-200 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            Cancel
          </RouterLink>

          <button
            type="submit"
            :disabled="saving"
            class="rounded-xl bg-indigo-600 px-6 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
          >
            {{ saving ? 'Saving...' : 'Save Category' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import api from '@/services/api'

const saving = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const categories = ref([])
const loadingCategories = ref(false)

const form = reactive({
  name: '',
  type: 'expense',
  icon: '',
  color: '',
  status: 'active',
})


async function loadCategories() {
  loadingCategories.value = true

  try {
    const response = await api.get('/finance/categories')
    categories.value = Array.isArray(response.data?.data) ? response.data.data : []
  } catch (error) {
    errorMessage.value = error?.message || 'Failed to load categories.'
  } finally {
    loadingCategories.value = false
  }
}

async function deleteCategory(category) {
  const id = category.id || category.category_id

  if (!id) {
    return
  }

  if (!confirm(`Delete category "${category.name || category.category_name}"?`)) {
    return
  }

  try {
    await api.delete(`/finance/categories/${id}`)
    successMessage.value = 'Category deleted successfully.'
    await loadCategories()
  } catch (error) {
    errorMessage.value = error?.message || 'Failed to delete category.'
  }
}

async function saveCategory() {
  successMessage.value = ''
  errorMessage.value = ''

  if (!form.name.trim()) {
    errorMessage.value = 'Category name is required.'
    return
  }

  saving.value = true

  try {
    await api.post('/finance/categories', {
      name: form.name.trim(),
      type: form.type,
      icon: form.icon || null,
      color: form.color || null,
      status: form.status,
    })

    successMessage.value = 'Category created successfully.'
    form.name = ''
    form.icon = ''
    form.color = ''
    form.status = 'active'
    await loadCategories()
  } catch (error) {
    errorMessage.value = error?.message || 'Failed to create category.'
  } finally {
    saving.value = false
  }
}

onMounted(loadCategories)
</script>
