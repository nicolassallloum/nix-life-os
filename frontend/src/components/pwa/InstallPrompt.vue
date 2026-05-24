<script setup lang="ts">
import { usePwaInstall } from '@/composables/usePwaInstall'

const { canInstall, isInstalled, installApp } = usePwaInstall()
</script>

<template>
  <div
    v-if="canInstall && !isInstalled"
    class="pwa-install-card"
  >
    <div>
      <strong>Install Nix Life OS</strong>
      <p>Use it like a mobile app with faster access and offline support.</p>
    </div>

    <button @click="installApp">
      Install App
    </button>
  </div>
</template>

<style scoped>
.pwa-install-card {
  position: fixed;
  left: 16px;
  right: 16px;
  bottom: 20px;
  z-index: 9999;
  max-width: 520px;
  margin: 0 auto;
  padding: 16px;
  border-radius: 20px;
  background: linear-gradient(135deg, #020617, #0f172a);
  color: #fff;
  border: 1px solid rgba(6, 182, 212, 0.35);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  gap: 16px;
  justify-content: space-between;
}

p {
  margin: 4px 0 0;
  color: #94a3b8;
  font-size: 13px;
}

button {
  border: 0;
  border-radius: 14px;
  padding: 10px 16px;
  background: linear-gradient(135deg, #06b6d4, #7c3aed);
  color: white;
  font-weight: 700;
  cursor: pointer;
}
</style>App.vue