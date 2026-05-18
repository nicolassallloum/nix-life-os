<template>
  <button :type="type" :disabled="disabled || loading" :class="buttonClass">
    <span v-if="loading">Loading...</span>
    <slot v-else />
  </button>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
  },
  type: {
    type: String,
    default: 'button',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  loading: {
    type: Boolean,
    default: false,
  },
})

const buttonClass = computed(() => {
  const variants = {
    primary: 'nix-button',
    secondary: 'nix-button-secondary',
    danger: 'nix-button-danger',
  }

  return variants[props.variant] || variants.primary
})
</script>
