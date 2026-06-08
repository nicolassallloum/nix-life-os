<template>
  <header class="nix-page-header">
    <div>
      <p v-if="eyebrow" class="nix-page-header__eyebrow">{{ eyebrow }}</p>
      <h1 class="nix-page-title">{{ title }}</h1>
      <p v-if="subtitle" class="nix-page-subtitle">{{ subtitle }}</p>
    </div>

    <div v-if="$slots.actions" class="nix-actions nix-page-header__actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
  eyebrow?: string
}>()
</script>

<style scoped>
.nix-page-header__eyebrow {
  margin: 0 0 6px;
  color: var(--nix-primary);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.nix-page-header__actions {
  justify-content: flex-end;
}

@media (max-width: 720px) {
  .nix-page-header__actions {
    justify-content: stretch;
  }
}
</style>
