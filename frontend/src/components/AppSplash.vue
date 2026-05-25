<template>
  <div v-if="visible" class="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-950">
    <div class="flex flex-col items-center text-center px-6">
      <div class="mb-6 flex h-24 w-24 items-center justify-center rounded-3xl bg-slate-900 shadow-2xl ring-1 ring-cyan-400/30">
        <img
          src="/icons/icon-192x192.png"
          alt="Nix Life OS"
          class="h-16 w-16 object-contain"
        />
      </div>

      <h1 class="text-3xl font-bold tracking-tight text-white">
        Nix Life OS
      </h1>

      <p class="mt-3 text-sm font-medium text-slate-400">
        Finance • Health • Productivity • Projects
      </p>

      <div class="mt-8 h-1 w-40 overflow-hidden rounded-full bg-slate-800">
        <div class="h-full w-1/2 animate-pulse rounded-full bg-cyan-400"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'

const visible = ref(true)

onMounted(() => {
  window.setTimeout(() => {
    visible.value = false
  }, 900)
})
</script>
<script setup>
import AppSplash from './components/AppSplash.vue'
</script>

<template>
  <AppSplash />
  <RouterView />
</template>
