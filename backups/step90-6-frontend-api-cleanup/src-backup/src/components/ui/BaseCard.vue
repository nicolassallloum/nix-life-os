<template>
  <section class="nix-card">
    <div v-if="$slots.header || title" class="nix-card-header">
      <div>
        <h2 v-if="title" class="nix-card-title">{{ title }}</h2>
        <p v-if="subtitle" class="nix-card-subtitle">{{ subtitle }}</p>
      </div>

      <slot name="header" />
    </div>

    <slot />
  </section>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
})
</script>
