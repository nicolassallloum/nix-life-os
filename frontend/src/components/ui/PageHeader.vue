<template>
  <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
    <div class="min-w-0">
      <h1 class="truncate text-xl font-bold text-white sm:text-2xl">
        {{ title }}
      </h1>

      <p
        v-if="description"
        class="mt-1 text-sm leading-6 text-slate-400"
      >
        {{ description }}
      </p>
    </div>

    <div
      v-if="$slots.actions"
      class="flex flex-col gap-2 sm:flex-row sm:items-center"
    >
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    default: ''
  }
})
</script>
