<template>
  <ErrorImageScreen
    image-src="/images/system/api-error.png"
    alt="Nix Life OS failed to load data"
    :show-buttons="true"
    @retry="retryPage"
  />
</template>

<script setup>
import ErrorImageScreen from '@/components/ErrorImageScreen.vue'

const retryPage = () => {
  window.location.reload()
}
</script>