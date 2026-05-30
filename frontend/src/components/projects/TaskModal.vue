<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-2xl bg-white p-6 shadow-xl">
      <div class="mb-4 flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900">
          Add Project Task
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
          <label class="mb-1 block text-sm font-medium text-gray-700">Project</label>
          <select
            v-model="form.project_id"
            required
            class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2 text-gray-900 focus:border-blue-500 focus:outline-none"
          >
            <option value="">Select Project</option>
            <option
              v-for="project in projects"
              :key="project.id"
              :value="project.id"
            >
              {{ project.name || project.title }}
            </option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Task Title</label>
          <input
            v-model="form.title"
            type="text"
            required
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            placeholder="Task title"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Description</label>
          <textarea
            v-model="form.description"
            rows="3"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
          ></textarea>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Priority</label>
            <select v-model="form.priority" class="input-select">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="critical">Critical</option>
            </select>
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Status</label>
            <select v-model="form.status" class="input-select">
              <option value="todo">Todo</option>
              <option value="in_progress">In Progress</option>
              <option value="done">Done</option>
              <option value="blocked">Blocked</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Start Date</label>
            <input v-model="form.start_date" type="date" class="input-field" />
          </div>

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Due Date</label>
            <input v-model="form.due_date" type="date" class="input-field" />
          </div>
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Assigned To</label>
          <input
            v-model="form.assigned_to"
            type="text"
            class="input-field"
            placeholder="Person name or email"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">Notes</label>
          <textarea v-model="form.notes" rows="3" class="input-field"></textarea>
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
            {{ loading ? 'Saving...' : 'Save Task' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { projectTaskService } from '@/services/projectTaskService'

const props = defineProps<{
  show: boolean
  projects: any[]
  selectedProjectId?: number | null
}>()

const emit = defineEmits(['close', 'saved'])

const loading = ref(false)
const error = ref('')

const form = reactive<any>({
  project_id: '',
  title: '',
  description: '',
  priority: 'medium',
  status: 'todo',
  start_date: '',
  due_date: '',
  assigned_to: '',
  notes: '',
})

watch(
  () => props.show,
  () => {
    if (props.selectedProjectId) {
      form.project_id = props.selectedProjectId
    }

    error.value = ''
  }
)

async function submitForm() {
  loading.value = true
  error.value = ''

  try {
    await projectTaskService.create({
      project_id: Number(form.project_id),
      title: form.title,
      description: form.description || null,
      priority: form.priority,
      status: form.status,
      start_date: form.start_date || null,
      due_date: form.due_date || null,
      assigned_to: form.assigned_to || null,
      notes: form.notes || null,
    })

    emit('saved')
    emit('close')

    form.title = ''
    form.description = ''
    form.priority = 'medium'
    form.status = 'todo'
    form.start_date = ''
    form.due_date = ''
    form.assigned_to = ''
    form.notes = ''
  } catch (err: any) {
    error.value = err?.response?.data?.message || 'Failed to save task.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.input-field,
.input-select {
  width: 100%;
  border-radius: 0.75rem;
  border: 1px solid #d1d5db;
  background: white;
  color: #111827;
  padding: 0.5rem 1rem;
}
</style>
