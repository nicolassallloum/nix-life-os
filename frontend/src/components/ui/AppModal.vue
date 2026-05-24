<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-0 sm:items-center sm:p-4"
  >
    <div
      class="max-h-[90vh] w-full overflow-y-auto rounded-t-3xl border border-slate-800 bg-slate-900 p-4 shadow-2xl sm:max-w-xl sm:rounded-3xl sm:p-6"
    >
      <div class="mb-4 flex items-center justify-between gap-3">
        <div class="min-w-0">
          <h2 class="truncate text-lg font-semibold text-white">
            {{ title }}
          </h2>
          <p
            v-if="description"
            class="mt-1 text-sm text-slate-400"
          >
            {{ description }}
          </p>
        </div>

        <button
          class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-700 text-slate-300 hover:bg-slate-800"
          @click="$emit('update:modelValue', false)"
        >
          ✕
        </button>
      </div>

      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: ''
  }
})

defineEmits(['update:modelValue'])
</script>
