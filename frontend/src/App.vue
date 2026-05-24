<script setup>
import { onMounted, ref } from 'vue';
import { updateServiceWorker } from './registerServiceWorker';

const updateAvailable = ref(false);
const swRegistration = ref(null);

onMounted(() => {
  window.addEventListener('pwa-update-available', event => {
    swRegistration.value = event.detail;
    updateAvailable.value = true;
  });

  navigator.serviceWorker?.addEventListener('controllerchange', () => {
    window.location.reload();
  });
});

function refreshApp() {
  updateServiceWorker(swRegistration.value);
}
</script>

<template>
  <RouterView />

  <div
    v-if="updateAvailable"
    class="pwa-update-banner"
  >
    <div>
      <strong>New version available</strong>
      <p>Refresh to update Nix Life OS.</p>
    </div>

    <button @click="refreshApp">
      Refresh
    </button>
  </div>
</template>

<style scoped>
.pwa-update-banner {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 9999;
  width: min(420px, calc(100vw - 48px));
  padding: 18px 20px;
  border-radius: 20px;
  background: rgba(15, 23, 42, 0.96);
  border: 1px solid rgba(34, 211, 238, 0.28);
  color: #f8fafc;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.pwa-update-banner p {
  margin: 4px 0 0;
  color: #94a3b8;
  font-size: 14px;
}

.pwa-update-banner button {
  border: 0;
  border-radius: 999px;
  padding: 10px 16px;
  font-weight: 700;
  color: white;
  cursor: pointer;
  background: linear-gradient(135deg, #22d3ee, #8b5cf6);
}
</style>