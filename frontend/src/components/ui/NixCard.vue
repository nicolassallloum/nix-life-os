<template>
  <section class="nix-card nix-card-padding" :class="{ 'nix-card--hover': hover }">
    <div v-if="$slots.header || title || subtitle" class="nix-card__header">
      <slot name="header">
        <div>
          <h2 v-if="title" class="nix-card__title">{{ title }}</h2>
          <p v-if="subtitle" class="nix-card__subtitle">{{ subtitle }}</p>
        </div>
      </slot>
    </div>

    <slot />
  </section>
</template>

<script setup lang="ts">
defineProps<{
  title?: string
  subtitle?: string
  hover?: boolean
}>()
</script>

<style scoped>
.nix-card--hover {
  transition:
    transform var(--nix-transition),
    box-shadow var(--nix-transition);
}

.nix-card--hover:hover {
  transform: translateY(-2px);
  box-shadow: var(--nix-shadow-md);
}

.nix-card__header {
  margin-bottom: 16px;
}

.nix-card__title {
  margin: 0;
  color: var(--nix-text);
  font-size: 1.05rem;
  font-weight: 900;
}

.nix-card__subtitle {
  margin: 6px 0 0;
  color: var(--nix-text-muted);
  font-size: 0.9rem;
  line-height: 1.5;
}
</style>
