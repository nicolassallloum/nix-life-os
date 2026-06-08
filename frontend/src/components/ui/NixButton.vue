<template>
  <button
    :type="type"
    class="nix-btn"
    :class="variantClass"
    :disabled="disabled || loading"
  >
    <span v-if="loading" class="nix-button__spinner" aria-hidden="true"></span>
    <slot>{{ label }}</slot>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    label?: string
    type?: 'button' | 'submit' | 'reset'
    variant?: 'primary' | 'secondary' | 'danger'
    disabled?: boolean
    loading?: boolean
  }>(),
  {
    type: 'button',
    variant: 'primary',
    disabled: false,
    loading: false,
  },
)

const variantClass = computed(() => `nix-btn-${props.variant}`)
</script>

<style scoped>
.nix-button__spinner {
  width: 14px;
  height: 14px;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: nix-spin 0.7s linear infinite;
}

@keyframes nix-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
