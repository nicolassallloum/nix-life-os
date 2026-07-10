<template>
  <Teleport to="body">
    <div v-if="open" class="todo-confirm" role="dialog" aria-modal="true" :aria-labelledby="titleId">
      <div class="todo-confirm__backdrop" @click="$emit('cancel')"></div>
      <section class="todo-confirm__panel">
        <h2 :id="titleId">{{ title }}</h2>
        <p>{{ message }}</p>
        <div class="todo-confirm__actions">
          <button type="button" class="todo-confirm__button todo-confirm__button--secondary" :disabled="loading" @click="$emit('cancel')">
            Cancel
          </button>
          <button type="button" class="todo-confirm__button todo-confirm__button--danger" :disabled="loading" @click="$emit('confirm')">
            {{ loading ? loadingLabel : confirmLabel }}
          </button>
        </div>
      </section>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const titleId = `todo-confirm-${Math.random().toString(36).slice(2)}`

withDefaults(
  defineProps<{
    open: boolean
    title?: string
    message: string
    confirmLabel?: string
    loadingLabel?: string
    loading?: boolean
  }>(),
  {
    title: 'Confirm action',
    confirmLabel: 'Delete',
    loadingLabel: 'Deleting...',
    loading: false,
  },
)

defineEmits<{
  confirm: []
  cancel: []
}>()
</script>

<style scoped>
.todo-confirm {
  position: fixed;
  inset: 0;
  z-index: 80;
  display: grid;
  place-items: center;
  padding: 16px;
}

.todo-confirm__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.62);
}

.todo-confirm__panel {
  position: relative;
  width: min(100%, 420px);
  padding: 22px;
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 18px;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.28);
}

.todo-confirm__panel h2 {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 900;
}

.todo-confirm__panel p {
  margin: 10px 0 0;
  color: var(--nix-text-muted, #64748b);
  line-height: 1.55;
}

.todo-confirm__actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
}

.todo-confirm__button {
  min-height: 40px;
  padding: 9px 14px;
  border-radius: 12px;
  font-weight: 900;
}

.todo-confirm__button:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.todo-confirm__button--secondary {
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
}

.todo-confirm__button--danger {
  color: #ffffff;
  background: #dc2626;
  border: 1px solid #dc2626;
}

@media (max-width: 640px) {
  .todo-confirm__actions {
    display: grid;
  }
}
</style>
