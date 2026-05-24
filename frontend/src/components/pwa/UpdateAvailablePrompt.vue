<script setup lang="ts">
import { onMounted, ref } from 'vue'

const updateAvailable = ref(false)

onMounted(() => {
  window.addEventListener('pwa-update-available', () => {
    updateAvailable.value = true
  })
})

async function refreshApp() {
  if (window.__NIX_PWA_UPDATE__) {
    await window.__NIX_PWA_UPDATE__(true)
  } else {
    window.location.reload()
  }
}
</script>

<template>
  <div
    v-if="updateAvailable"
    class="update-card"
  >
    <span>A new version of Nix Life OS is available.</span>

    <button @click="refreshApp">
      Update
    </button>
  </div>
</template>

<style scoped>
.update-card {
  position: fixed;
  left: 16px;
  right: 16px;
  bottom: 100px;
  z-index: 9999;
  max-width: 520px;
  margin: 0 auto;
  padding: 14px 16px;
  border-radius: 18px;
  background: #0f172a;
  color: white;
  border: 1px solid rgba(124, 58, 237, 0.45);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

button {
  border: 0;
  border-radius: 12px;
  padding: 8px 14px;
  background: #7c3aed;
  color: white;
  font-weight: 700;
  cursor: pointer;
}
</style>