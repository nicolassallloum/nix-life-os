<script setup lang="ts">
import { ref } from 'vue'
import { usePushNotifications } from '@/composables/usePushNotifications'

const { enablePushNotifications } = usePushNotifications()

const loading = ref(false)
const enabled = ref(false)
const error = ref<string | null>(null)

async function enable() {
  loading.value = true
  error.value = null

  try {
    await enablePushNotifications()
    enabled.value = true
  } catch (e: any) {
    error.value = e.message || 'Unable to enable notifications.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="push-card">
    <div>
      <strong>Smart Reminders</strong>
      <p>Enable notifications for tasks, finance alerts, health reminders, and project updates.</p>

      <small v-if="error" class="error">
        {{ error }}
      </small>

      <small v-if="enabled" class="success">
        Notifications enabled.
      </small>
    </div>

    <button
      :disabled="loading || enabled"
      @click="enable"
    >
      {{ enabled ? 'Enabled' : loading ? 'Enabling...' : 'Enable' }}
    </button>
  </div>
</template>

<style scoped>
.push-card {
  padding: 18px;
  border-radius: 20px;
  background: #0f172a;
  color: white;
  border: 1px solid rgba(6, 182, 212, 0.25);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

p {
  margin: 4px 0 0;
  color: #94a3b8;
  font-size: 13px;
}

button {
  border: 0;
  border-radius: 12px;
  padding: 10px 16px;
  background: linear-gradient(135deg, #06b6d4, #7c3aed);
  color: white;
  font-weight: 700;
  cursor: pointer;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  display: block;
  margin-top: 8px;
  color: #f87171;
}

.success {
  display: block;
  margin-top: 8px;
  color: #34d399;
}
</style>