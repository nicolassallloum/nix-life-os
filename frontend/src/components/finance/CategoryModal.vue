<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
      <div class="mb-4 flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900">
          Add Finance Category
        </h2>

        <button
          class="rounded-lg px-3 py-1 text-gray-500 hover:bg-gray-100"
          @click="$emit('close')"
        >
          ✕
        </button>
      </div>

      <form class="space-y-4" @submit.prevent="submitForm">
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Category Name</label>
          <input
            v-model="form.name"
            type="text"
            required
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            placeholder="Food, Salary, Rent"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Type</label>
          <select
            v-model="form.type"
            required
            class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none"
          >
            <option value="expense">Expense</option>
            <option value="income">Income</option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Icon</label>
          <input
            v-model="form.icon"
            type="text"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            placeholder="food, salary, rent"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Color</label>
          <input
            v-model="form.color"
            type="color"
            class="h-11 w-full rounded-xl border border-gray-300 px-2 py-1"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Status</label>
          <select
            v-model="form.status"
            class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none"
          >
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div v-if="error" class="rounded-xl bg-red-50 p-3 text-sm text-red-700">
          {{ error }}
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button
            type="button"
            class="rounded-xl border px-4 py-2 text-gray-700 hover:bg-gray-50"
            @click="$emit('close')"
          >
            Cancel
          </button>

          <button
            type="submit"
            :disabled="loading"
            class="rounded-xl bg-blue-600 px-5 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
          >
            {{ loading ? 'Saving...' : 'Save Category' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { financeCategoryService } from '@/services/financeCategoryService'

defineProps<{
  show: boolean
}>()

const emit = defineEmits(['close', 'saved'])

const loading = ref(false)
const error = ref('')

const form = reactive({
  name: '',
  type: 'expense',
  icon: '',
  color: '#2563eb',
  status: 'active',
})

async function submitForm() {
  loading.value = true
  error.value = ''

  try {
    await financeCategoryService.create({
      name: form.name,
      type: form.type as 'income' | 'expense',
      icon: form.icon,
      color: form.color,
      status: form.status as 'active' | 'inactive',
    })

    emit('saved')
    emit('close')

    form.name = ''
    form.type = 'expense'
    form.icon = ''
    form.color = '#2563eb'
    form.status = 'active'
  } catch (err: any) {
    error.value = err?.response?.data?.message || 'Failed to save category.'
  } finally {
    loading.value = false
  }
}
</script>
