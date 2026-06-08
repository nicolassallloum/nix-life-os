<template>
  <div class="nix-loading" :class="{ 'nix-loading--page': page }">
    <span class="nix-loading__spinner" aria-hidden="true"></span>
    <p v-if="message" class="nix-loading__message">{{ message }}</p>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    message?: string
    page?: boolean
  }>(),
  {
    message: 'Loading...',
    page: false,
  },
)
</script>

<style scoped>
.nix-loading {
  display: grid;
  place-items: center;
  gap: 12px;
  padding: 24px;
  color: var(--nix-text-muted);
}

.nix-loading--page {
  min-height: 50vh;
}

.nix-loading__spinner {
  width: 34px;
  height: 34px;
  border: 3px solid var(--nix-border);
  border-top-color: var(--nix-primary);
  border-radius: 50%;
  animation: nix-spin 0.75s linear infinite;
}

.nix-loading__message {
  margin: 0;
  font-weight: 700;
}

@keyframes nix-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
