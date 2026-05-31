<template>
  <ErrorImageScreen
    image-src="/images/system/application-down.png"
    alt="Nix Life OS application temporarily down"
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