<script setup>
import { computed } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'

const route = useRoute()
const usesPublicLayout = computed(() => route.meta?.publicLayout === true)
</script>

<template>
  <RouterView v-if="usesPublicLayout" />
  <AppLayout v-else />
</template>
