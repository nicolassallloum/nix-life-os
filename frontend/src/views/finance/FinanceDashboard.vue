<template>
  <div class="space-y-6 p-4">
    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Finance</h1>
        <p class="text-sm text-gray-500">Manage your money, categories, and transactions.</p>
      </div>

      <div class="flex flex-wrap gap-2">
        <button class="btn-primary">
          Add Transaction
        </button>

        <button class="btn-secondary" @click="showCategoryModal = true">
          Add Category
        </button>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="rounded-2xl bg-white p-5 shadow">
        <p class="text-sm text-gray-500">Total Categories</p>
        <h3 class="text-2xl font-bold text-gray-900">{{ categories.length }}</h3>
      </div>

      <div class="rounded-2xl bg-white p-5 shadow">
        <p class="text-sm text-gray-500">Income Categories</p>
        <h3 class="text-2xl font-bold text-green-600">{{ incomeCount }}</h3>
      </div>

      <div class="rounded-2xl bg-white p-5 shadow">
        <p class="text-sm text-gray-500">Expense Categories</p>
        <h3 class="text-2xl font-bold text-red-600">{{ expenseCount }}</h3>
      </div>
    </div>

    <div class="rounded-2xl bg-white p-5 shadow">
      <h2 class="mb-4 text-lg font-bold text-gray-900">Categories</h2>

      <div class="space-y-3">
        <div
          v-for="category in categories"
          :key="category.id"
          class="flex items-center justify-between rounded-xl border p-3"
        >
          <div>
            <p class="font-medium text-gray-900">{{ category.name }}</p>
            <p class="text-sm capitalize text-gray-500">{{ category.type }} · {{ category.status }}</p>
          </div>

          <button
            class="rounded-lg bg-red-50 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-100"
            @click="deleteCategory(category.id)"
          >
            Delete
          </button>
        </div>
      </div>
    </div>

    <CategoryModal
      :show="showCategoryModal"
      @close="showCategoryModal = false"
      @saved="loadCategories"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import CategoryModal from '@/components/finance/CategoryModal.vue'
import { financeCategoryService } from '@/services/financeCategoryService'

const showCategoryModal = ref(false)
const categories = ref<any[]>([])

const incomeCount = computed(() => categories.value.filter((c) => c.type === 'income').length)
const expenseCount = computed(() => categories.value.filter((c) => c.type === 'expense').length)

async function loadCategories() {
  const response = await financeCategoryService.list()
  categories.value = response.data.data
}

async function deleteCategory(id: number) {
  if (!confirm('Are you sure you want to delete this category?')) {
    return
  }

  await financeCategoryService.delete(id)
  await loadCategories()
}

onMounted(loadCategories)
</script>

<style scoped>
.btn-primary {
  border-radius: 0.75rem;
  background: #2563eb;
  padding: 0.6rem 1rem;
  font-weight: 600;
  color: white;
}

.btn-secondary {
  border-radius: 0.75rem;
  background: #f3f4f6;
  padding: 0.6rem 1rem;
  font-weight: 600;
  color: #111827;
}
</style>
