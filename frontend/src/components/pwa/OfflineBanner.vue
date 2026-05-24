<script setup lang="ts">
import { useNetworkStatus } from '@/composables/useNetworkStatus'

const { isOnline } = useNetworkStatus()
</script>

<template>
  <div
    v-if="!isOnline"
    class="offline-banner"
  >
    You are offline. Some Nix Life OS features may be limited.
  </div>
</template>

<style scoped>
.offline-banner {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  padding: 10px 16px;
  background: #f97316;
  color: white;
  text-align: center;
  font-weight: 700;
  z-index: 10000;
}
</style>