<template>
  <div class="nix-loading-state">
    <div class="flex items-center gap-3">
      <div class="h-4 w-4 animate-spin rounded-full border-2 border-slate-300 border-t-blue-600" />
      <span>{{ message }}</span>
    </div>
  </div>
</template>

<script setup>
defineProps({
  message: {
    type: String,
    default: 'Loading data...',
  },
})
</script>
