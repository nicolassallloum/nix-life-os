<template>
  <div class="min-h-screen w-full overflow-x-hidden bg-slate-950 text-white">
    <!-- Mobile Header -->
    <MobileHeader @open-sidebar="sidebarOpen = true" />

    <div class="flex min-h-screen w-full">
      <!-- Desktop Sidebar -->
      <aside
        class="hidden w-72 shrink-0 border-r border-slate-800 bg-slate-900/95 lg:block"
      >
        <div class="sticky top-0 h-screen overflow-y-auto">
          <Sidebar />
        </div>
      </aside>

      <!-- Mobile Sidebar Drawer -->
      <Transition name="fade">
        <div
          v-if="sidebarOpen"
          class="fixed inset-0 z-50 lg:hidden"
        >
          <!-- Overlay -->
          <div
            class="absolute inset-0 bg-black/70 backdrop-blur-sm"
            @click="closeSidebar"
          ></div>

          <!-- Drawer -->
          <Transition name="slide">
            <aside
              class="relative z-50 h-full w-72 max-w-[85vw] overflow-y-auto border-r border-slate-800 bg-slate-900 shadow-2xl"
            >
              <div
                class="sticky top-0 z-10 flex items-center justify-between border-b border-slate-800 bg-slate-900 px-4 py-3"
              >
                <div class="min-w-0">
                  <p class="truncate text-sm font-bold text-white">
                    Nix Life OS
                  </p>
                  <p class="truncate text-xs text-slate-400">
                    Mobile Menu
                  </p>
                </div>

                <button
                  type="button"
                  class="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-700 text-slate-200 hover:bg-slate-800"
                  aria-label="Close navigation menu"
                  @click="closeSidebar"
                >
                  ✕
                </button>
              </div>

              <Sidebar @navigate="closeSidebar" />
            </aside>
          </Transition>
        </div>
      </Transition>

      <!-- Main Content -->
      <main class="min-w-0 flex-1 pb-20 lg:pb-0">
        <div class="mx-auto w-full max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
          <RouterView />
        </div>
      </main>
    </div>

    <!-- Mobile Bottom Navigation -->
    <MobileBottomNav />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'

import Sidebar from '@/components/layout/Sidebar.vue'
import MobileHeader from '@/components/layout/MobileHeader.vue'
import MobileBottomNav from '@/components/layout/MobileBottomNav.vue'

const sidebarOpen = ref(false)
const route = useRoute()

const closeSidebar = () => {
  sidebarOpen.value = false
}

watch(
  () => route.fullPath,
  () => {
    sidebarOpen.value = false
  }
)
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-enter-active,
.slide-leave-active {
  transition: transform 0.25s ease;
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(-100%);
}
</style>