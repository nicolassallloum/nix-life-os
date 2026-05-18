<template>
  <div class="nix-empty-state">
    <div class="mb-3 text-3xl">{{ icon }}</div>

    <h3 class="text-base font-bold text-slate-950">{{ title }}</h3>

    <p class="mt-1 max-w-md text-sm text-slate-500">{{ message }}</p>

    <div v-if="$slots.action" class="mt-4">
      <slot name="action" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  icon: {
    type: String,
    default: '📭',
  },
  title: {
    type: String,
    default: 'No data found',
  },
  message: {
    type: String,
    default: 'There is no information to display yet.',
  },
})
</script>
