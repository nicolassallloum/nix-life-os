<template>
  <div class="todo-loading-state" :class="{ 'todo-loading-state--compact': compact }" role="status" aria-live="polite">
    <span class="todo-loading-state__spinner" aria-hidden="true"></span>
    <span>{{ message }}</span>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    message?: string
    compact?: boolean
  }>(),
  {
    message: 'Loading...',
    compact: false,
  },
)
</script>

<style scoped>
.todo-loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  min-height: 150px;
  padding: 24px;
  color: var(--nix-text-muted, #64748b);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 18px;
  box-shadow: var(--nix-shadow-sm, 0 1px 2px rgba(15, 23, 42, 0.05));
  font-size: 0.92rem;
  font-weight: 800;
}

.todo-loading-state--compact {
  min-height: 52px;
  padding: 12px;
}

.todo-loading-state__spinner {
  width: 18px;
  height: 18px;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 999px;
  animation: todo-spin 0.7s linear infinite;
}

@keyframes todo-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
