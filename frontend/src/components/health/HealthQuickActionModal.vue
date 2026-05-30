<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-xl">
      <div class="mb-4 flex items-center justify-between">
        <h2 class="text-xl font-bold text-gray-900">
          {{ title }}
        </h2>

        <button
          class="rounded-lg px-3 py-1 text-gray-500 hover:bg-gray-100"
          @click="$emit('close')"
        >
          ✕
        </button>
      </div>

      <form class="space-y-4" @submit.prevent="submitForm">
        <template v-if="type === 'steps'">
          <BaseDate v-model="form.entry_date" label="Date" />

          <BaseNumber v-model="form.steps" label="Steps" placeholder="5000" />

          <BaseNumber v-model="form.distance_km" label="KM Distance" placeholder="3.5" step="0.01" />

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

        <template v-if="type === 'weight'">
          <BaseDate v-model="form.entry_date" label="Date" />

          <BaseNumber v-model="form.weight_kg" label="Weight KG" placeholder="64" step="0.01" />

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

        <template v-if="type === 'water'">
          <BaseDate v-model="form.entry_date" label="Date" />

          <BaseNumber v-model="form.amount_ml" label="Water Amount ML" placeholder="500" />

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

        <template v-if="type === 'sleep'">
          <BaseDate v-model="form.entry_date" label="Date" />

          <BaseTime v-model="form.sleep_start" label="Sleep Start" />

          <BaseTime v-model="form.sleep_end" label="Sleep End" />

          <BaseNumber v-model="form.duration_hours" label="Duration Hours" placeholder="7.5" step="0.01" />

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Sleep Quality</label>
            <select v-model="form.quality" class="input-select">
              <option value="">Select quality</option>
              <option value="poor">Poor</option>
              <option value="fair">Fair</option>
              <option value="good">Good</option>
              <option value="excellent">Excellent</option>
            </select>
          </div>

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

        <template v-if="type === 'mood'">
          <BaseDate v-model="form.entry_date" label="Date" />

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Mood</label>
            <select v-model="form.mood" required class="input-select">
              <option value="happy">Happy</option>
              <option value="normal">Normal</option>
              <option value="stressed">Stressed</option>
              <option value="sad">Sad</option>
              <option value="angry">Angry</option>
              <option value="tired">Tired</option>
            </select>
          </div>

          <BaseNumber v-model="form.mood_score" label="Mood Score 1-10" placeholder="7" />

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

        <template v-if="type === 'medication'">
          <BaseInput v-model="form.medication_name" label="Medication Name" placeholder="Medication name" />

          <BaseInput v-model="form.dosage" label="Dosage" placeholder="500mg" />

          <BaseTime v-model="form.medication_time" label="Time" />

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Frequency</label>
            <select v-model="form.frequency_type" required class="input-select">
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
          </div>

          <BaseNumber v-model="form.quantity" label="Quantity" placeholder="1" />

          <BaseDate v-model="form.start_date" label="Start Date" />

          <BaseDate v-model="form.stop_date" label="Stop Date" />

          <div>
            <label class="mb-1 block text-sm font-medium text-gray-700">Status</label>
            <select v-model="form.status" class="input-select">
              <option value="active">Active</option>
              <option value="stopped">Stopped</option>
              <option value="completed">Completed</option>
            </select>
          </div>

          <BaseTextarea v-model="form.notes" label="Notes" />
        </template>

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
            {{ loading ? 'Saving...' : 'Save' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { healthService } from '@/services/healthService'

const props = defineProps<{
  show: boolean
  type: 'steps' | 'weight' | 'water' | 'sleep' | 'mood' | 'medication'
}>()

const emit = defineEmits(['close', 'saved'])

const loading = ref(false)
const error = ref('')

const today = new Date().toISOString().slice(0, 10)

const title = computed(() => {
  const titles: Record<string, string> = {
    steps: 'Add Steps & KM Distance',
    weight: 'Add Weight',
    water: 'Add Hydration',
    sleep: 'Add Sleep Duration',
    mood: 'Add Mood',
    medication: 'Add Medication',
  }

  return titles[props.type]
})

const form = reactive<any>({
  entry_date: today,
  steps: '',
  distance_km: '',
  weight_kg: '',
  amount_ml: '',
  sleep_start: '',
  sleep_end: '',
  duration_hours: '',
  quality: '',
  mood: 'normal',
  mood_score: '',
  medication_name: '',
  dosage: '',
  medication_time: '',
  frequency_type: 'daily',
  quantity: 1,
  start_date: today,
  stop_date: '',
  status: 'active',
  notes: '',
})

watch(
  () => props.show,
  () => {
    error.value = ''
  }
)

async function submitForm() {
  loading.value = true
  error.value = ''

  try {
    if (props.type === 'steps') {
      await healthService.addSteps({
        entry_date: form.entry_date,
        steps: Number(form.steps),
        distance_km: Number(form.distance_km || 0),
        notes: form.notes,
      })
    }

    if (props.type === 'weight') {
      await healthService.addWeight({
        entry_date: form.entry_date,
        weight_kg: Number(form.weight_kg),
        notes: form.notes,
      })
    }

    if (props.type === 'water') {
      await healthService.addWater({
        entry_date: form.entry_date,
        amount_ml: Number(form.amount_ml),
        notes: form.notes,
      })
    }

    if (props.type === 'sleep') {
      await healthService.addSleep({
        entry_date: form.entry_date,
        sleep_start: form.sleep_start || null,
        sleep_end: form.sleep_end || null,
        duration_hours: Number(form.duration_hours),
        quality: form.quality || null,
        notes: form.notes,
      })
    }

    if (props.type === 'mood') {
      await healthService.addMood({
        entry_date: form.entry_date,
        mood: form.mood,
        mood_score: form.mood_score ? Number(form.mood_score) : null,
        notes: form.notes,
      })
    }

    if (props.type === 'medication') {
      await healthService.addMedication({
        medication_name: form.medication_name,
        dosage: form.dosage,
        medication_time: form.medication_time,
        frequency_type: form.frequency_type,
        quantity: Number(form.quantity),
        start_date: form.start_date,
        stop_date: form.stop_date || null,
        status: form.status,
        notes: form.notes,
      })
    }

    emit('saved')
    emit('close')
  } catch (err: any) {
    error.value = err?.response?.data?.message || 'Failed to save health record.'
  } finally {
    loading.value = false
  }
}
</script>

<script lang="ts">
export default {
  components: {
    BaseInput: {
      props: ['modelValue', 'label', 'placeholder'],
      emits: ['update:modelValue'],
      template: `
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">{{ label }}</label>
          <input
            :value="modelValue"
            type="text"
            required
            :placeholder="placeholder"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            @input="$emit('update:modelValue', $event.target.value)"
          />
        </div>
      `,
    },
    BaseDate: {
      props: ['modelValue', 'label'],
      emits: ['update:modelValue'],
      template: `
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">{{ label }}</label>
          <input
            :value="modelValue"
            type="date"
            required
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            @input="$emit('update:modelValue', $event.target.value)"
          />
        </div>
      `,
    },
    BaseTime: {
      props: ['modelValue', 'label'],
      emits: ['update:modelValue'],
      template: `
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">{{ label }}</label>
          <input
            :value="modelValue"
            type="time"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            @input="$emit('update:modelValue', $event.target.value)"
          />
        </div>
      `,
    },
    BaseNumber: {
      props: ['modelValue', 'label', 'placeholder', 'step'],
      emits: ['update:modelValue'],
      template: `
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">{{ label }}</label>
          <input
            :value="modelValue"
            type="number"
            :step="step || 1"
            required
            :placeholder="placeholder"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            @input="$emit('update:modelValue', $event.target.value)"
          />
        </div>
      `,
    },
    BaseTextarea: {
      props: ['modelValue', 'label'],
      emits: ['update:modelValue'],
      template: `
        <div>
          <label class="mb-1 block text-sm font-medium text-gray-700">{{ label }}</label>
          <textarea
            :value="modelValue"
            rows="3"
            class="w-full rounded-xl border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
            @input="$emit('update:modelValue', $event.target.value)"
          ></textarea>
        </div>
      `,
    },
  },
}
</script>

<style scoped>
.input-select {
  width: 100%;
  border-radius: 0.75rem;
  border: 1px solid #d1d5db;
  background: white;
  color: #111827;
  padding: 0.5rem 1rem;
}
</style>
