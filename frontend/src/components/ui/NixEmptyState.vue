<template>
  <section class="nix-empty-state">
    <div v-if="icon" class="nix-empty-state__icon">{{ icon }}</div>
    <h2 class="nix-empty-state__title">{{ title }}</h2>
    <p v-if="message" class="nix-empty-state__message">{{ message }}</p>

    <div v-if="$slots.actions" class="nix-actions nix-empty-state__actions">
      <slot name="actions" />
    </div>
  </section>
</template>

<script setup lang="ts">
defineProps<{
  title: string
  message?: string
  icon?: string
}>()
</script>

<style scoped>
.nix-empty-state {
  display: grid;
  place-items: center;
  gap: 10px;
  min-height: 280px;
  padding: 28px;
  text-align: center;
  background: var(--nix-surface);
  border: 1px dashed var(--nix-border-strong);
  border-radius: var(--nix-radius-xl);
}

.nix-empty-state__icon {
  display: grid;
  width: 56px;
  height: 56px;
  place-items: center;
  background: var(--nix-primary-soft);
  border-radius: 999px;
  font-size: 1.8rem;
}

.nix-empty-state__title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 900;
}

.nix-empty-state__message {
  max-width: 520px;
  margin: 0;
  color: var(--nix-text-muted);
  line-height: 1.6;
}

.nix-empty-state__actions {
  justify-content: center;
  margin-top: 8px;
}
</style>
