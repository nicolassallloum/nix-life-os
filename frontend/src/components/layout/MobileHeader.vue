<template>
  <header
    class="lg:hidden sticky top-0 z-40 border-b border-slate-800 bg-slate-950/95 backdrop-blur"
  >
    <div class="flex items-center justify-between px-4 py-3">
      <button
        type="button"
        class="flex h-11 w-11 items-center justify-center rounded-xl border border-slate-700 bg-slate-900 text-slate-100 hover:bg-slate-800 active:scale-95"
        aria-label="Open navigation menu"
        @click="$emit('open-sidebar')"
      >
        <span class="text-xl leading-none">☰</span>
      </button>

      <div class="flex min-w-0 flex-1 items-center justify-center px-3">
        <div class="min-w-0 text-center">
          <p class="truncate text-sm font-semibold tracking-wide text-white">
            Nix Life OS
          </p>
          <p class="truncate text-xs text-slate-400">
            Personal Operating System
          </p>
        </div>
      </div>

      <button
        type="button"
        class="flex h-11 w-11 items-center justify-center rounded-xl border border-slate-700 bg-slate-900 text-slate-100 hover:bg-slate-800 active:scale-95"
        aria-label="Notifications"
      >
        <span class="text-lg leading-none">🔔</span>
      </button>
    </div>
  </header>
</template>

<script setup>
defineEmits(['open-sidebar'])
</script>
