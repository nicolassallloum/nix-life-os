<template>
  <nav
    class="mobile-safe-area fixed bottom-0 left-0 right-0 z-40 border-t border-slate-800 bg-slate-950/95 backdrop-blur lg:hidden"
  >
    <div class="grid grid-cols-5">
      <RouterLink
        v-for="item in navItems"
        :key="item.path"
        :to="item.path"
        class="flex min-h-14 flex-col items-center justify-center gap-1 px-1 py-2 text-xs font-medium text-slate-400 transition hover:text-cyan-300"
        active-class="text-cyan-300"
      >
        <span class="text-lg leading-none">{{ item.icon }}</span>
        <span class="max-w-full truncate">{{ item.label }}</span>
      </RouterLink>
    </div>
  </nav>
</template>

<script setup>
const navItems = [
  {
    label: 'Home',
    path: '/dashboard',
    icon: '🏠',
  },
  {
    label: 'Finance',
    path: '/finance',
    icon: '💰',
  },
  {
    label: 'Health',
    path: '/health',
    icon: '❤️',
  },
  {
    label: 'Projects',
    path: '/projects',
    icon: '📁',
  },
  {
    label: 'To-Do',
    path: '/todo',
    icon: '✅',
  },
]
</script>