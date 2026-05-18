<template>
  <div :class="alertClass">
    <slot />
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'info',
  },
})

const alertClass = computed(() => {
  const variants = {
    default: 'nix-alert',
    info: 'nix-alert-info',
    success: 'nix-alert-success',
    warning: 'nix-alert-warning',
    error: 'nix-alert-error',
  }

  return variants[props.variant] || variants.info
})
</script>
