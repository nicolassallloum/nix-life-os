<script setup lang="ts">
import InstallPrompt from '@/components/pwa/InstallPrompt.vue'
import OfflineBanner from '@/components/pwa/OfflineBanner.vue'
import UpdateAvailablePrompt from '@/components/pwa/UpdateAvailablePrompt.vue'
</script>

<template>
  <OfflineBanner />
  <UpdateAvailablePrompt />

  <RouterView />

  <InstallPrompt />
</template>