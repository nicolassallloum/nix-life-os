<template>
  <article class="nix-card nix-card-padding nix-kpi-card">
    <div class="nix-kpi-card__top">
      <span v-if="icon" class="nix-kpi-card__icon">{{ icon }}</span>
      <span v-if="trend" class="nix-badge" :class="trendClass">{{ trend }}</span>
    </div>

    <p class="nix-kpi-card__label">{{ label }}</p>
    <strong class="nix-kpi-card__value">{{ value }}</strong>
    <p v-if="subtitle" class="nix-kpi-card__subtitle">{{ subtitle }}</p>
  </article>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    label: string
    value: string | number
    subtitle?: string
    icon?: string
    trend?: string
    status?: 'success' | 'warning' | 'danger' | 'info'
  }>(),
  {
    status: 'info',
  },
)

const trendClass = computed(() => `nix-badge-${props.status}`)
</script>

<style scoped>
.nix-kpi-card {
  display: grid;
  gap: 8px;
}

.nix-kpi-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.nix-kpi-card__icon {
  display: grid;
  width: 42px;
  height: 42px;
  place-items: center;
  background: var(--nix-primary-soft);
  border-radius: var(--nix-radius-md);
  font-size: 1.25rem;
}

.nix-kpi-card__label {
  margin: 0;
  color: var(--nix-text-muted);
  font-size: 0.9rem;
  font-weight: 700;
}

.nix-kpi-card__value {
  color: var(--nix-text);
  font-size: 1.9rem;
  font-weight: 950;
  letter-spacing: -0.04em;
}

.nix-kpi-card__subtitle {
  margin: 0;
  color: var(--nix-text-muted);
  font-size: 0.86rem;
}
</style>
