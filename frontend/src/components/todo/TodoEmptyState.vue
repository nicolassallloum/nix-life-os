<template>
  <div class="todo-empty-state">
    <div class="todo-empty-state__icon" aria-hidden="true">{{ icon }}</div>
    <h3>{{ title }}</h3>
    <p>{{ message }}</p>
    <slot />
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    title: string
    message: string
    icon?: string
  }>(),
  {
    icon: '+',
  },
)
</script>

<style scoped>
.todo-empty-state {
  display: grid;
  place-items: center;
  gap: 8px;
  min-height: 150px;
  padding: 24px;
  color: var(--nix-text-muted, #64748b);
  text-align: center;
  background: rgba(148, 163, 184, 0.08);
  border: 1px dashed rgba(148, 163, 184, 0.45);
  border-radius: 18px;
}

.todo-empty-state__icon {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  color: #0891b2;
  background: #ecfeff;
  border-radius: 999px;
  font-size: 1.1rem;
  font-weight: 900;
}

.todo-empty-state h3 {
  margin: 0;
  color: var(--nix-text, #0f172a);
  font-size: 1rem;
  font-weight: 900;
}

.todo-empty-state p {
  max-width: 46ch;
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.5;
}

:global(.dark) .todo-empty-state {
  background: rgba(15, 23, 42, 0.38);
  border-color: rgba(148, 163, 184, 0.32);
}

:global(.dark) .todo-empty-state__icon {
  color: #67e8f9;
  background: rgba(6, 182, 212, 0.15);
}
</style>
