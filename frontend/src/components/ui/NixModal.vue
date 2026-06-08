<template>
  <Teleport to="body">
    <div v-if="modelValue" class="nix-modal" role="dialog" aria-modal="true">
      <button class="nix-modal__backdrop" type="button" @click="close"></button>

      <section class="nix-modal__panel">
        <header class="nix-modal__header">
          <div>
            <h2 v-if="title" class="nix-modal__title">{{ title }}</h2>
            <p v-if="subtitle" class="nix-modal__subtitle">{{ subtitle }}</p>
          </div>

          <button class="nix-modal__close" type="button" aria-label="Close modal" @click="close">
            ×
          </button>
        </header>

        <div class="nix-modal__body">
          <slot />
        </div>

        <footer v-if="$slots.footer" class="nix-modal__footer">
          <slot name="footer" />
        </footer>
      </section>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue: boolean
    title?: string
    subtitle?: string
    closeOnBackdrop?: boolean
  }>(),
  {
    closeOnBackdrop: true,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  close: []
}>()

function close() {
  if (!props.closeOnBackdrop) return
  emit('update:modelValue', false)
  emit('close')
}
</script>

<style scoped>
.nix-modal {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: grid;
  place-items: center;
  padding: 18px;
}

.nix-modal__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.55);
  border: 0;
}

.nix-modal__panel {
  position: relative;
  z-index: 1;
  width: min(560px, 100%);
  max-height: 88vh;
  overflow: auto;
  background: var(--nix-surface);
  border-radius: var(--nix-radius-xl);
  box-shadow: var(--nix-shadow-lg);
}

.nix-modal__header,
.nix-modal__footer {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  padding: 20px;
  border-bottom: 1px solid var(--nix-border);
}

.nix-modal__footer {
  justify-content: flex-end;
  border-top: 1px solid var(--nix-border);
  border-bottom: 0;
}

.nix-modal__body {
  padding: 20px;
}

.nix-modal__title {
  margin: 0;
  font-size: 1.2rem;
  font-weight: 900;
}

.nix-modal__subtitle {
  margin: 6px 0 0;
  color: var(--nix-text-muted);
  line-height: 1.5;
}

.nix-modal__close {
  width: 36px;
  height: 36px;
  color: var(--nix-text-muted);
  background: var(--nix-bg-soft);
  border: 1px solid var(--nix-border);
  border-radius: 999px;
  font-size: 1.3rem;
}
</style>
