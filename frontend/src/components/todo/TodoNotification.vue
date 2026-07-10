<template>
  <Transition name="todo-notification">
    <div v-if="message" class="todo-notification" :class="toneClass" role="status" aria-live="polite">
      <strong>{{ title }}</strong>
      <span>{{ message }}</span>
      <button type="button" aria-label="Dismiss notification" @click="$emit('dismiss')">x</button>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    type?: 'success' | 'error' | 'info'
    message?: string
  }>(),
  {
    type: 'info',
    message: '',
  },
)

defineEmits<{
  dismiss: []
}>()

const title = computed(() => {
  if (props.type === 'success') return 'Success'
  if (props.type === 'error') return 'Error'

  return 'Notice'
})

const toneClass = computed(() => `todo-notification--${props.type}`)
</script>

<style scoped>
.todo-notification {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border: 1px solid transparent;
  border-radius: 14px;
  font-size: 0.9rem;
  line-height: 1.4;
}

.todo-notification strong {
  font-weight: 900;
}

.todo-notification span {
  min-width: 0;
}

.todo-notification button {
  width: 28px;
  height: 28px;
  color: inherit;
  border: 0;
  border-radius: 999px;
  background: transparent;
  font-weight: 900;
}

.todo-notification--success {
  color: #166534;
  background: #dcfce7;
  border-color: #bbf7d0;
}

.todo-notification--error {
  color: #991b1b;
  background: #fee2e2;
  border-color: #fecaca;
}

.todo-notification--info {
  color: #155e75;
  background: #ecfeff;
  border-color: #a5f3fc;
}

.todo-notification-enter-active,
.todo-notification-leave-active {
  transition:
    opacity 0.18s ease,
    transform 0.18s ease;
}

.todo-notification-enter-from,
.todo-notification-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

:global(.dark) .todo-notification--success {
  color: #bbf7d0;
  background: rgba(34, 197, 94, 0.14);
  border-color: rgba(134, 239, 172, 0.22);
}

:global(.dark) .todo-notification--error {
  color: #fecaca;
  background: rgba(239, 68, 68, 0.14);
  border-color: rgba(252, 165, 165, 0.22);
}

:global(.dark) .todo-notification--info {
  color: #a5f3fc;
  background: rgba(6, 182, 212, 0.14);
  border-color: rgba(103, 232, 249, 0.22);
}
</style>
