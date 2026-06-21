<template>
  <nav class="flex min-h-full flex-col px-3 py-4">
    <!-- Brand -->
    <div class="mb-6 hidden px-3 lg:block">
      <div class="flex items-center gap-3">
        <div
          class="flex h-11 w-11 items-center justify-center rounded-2xl bg-cyan-500 text-lg font-black text-slate-950"
        >
          N
        </div>

        <div class="min-w-0">
          <h1 class="truncate text-base font-bold text-white">
            Nix Life OS
          </h1>
          <p class="truncate text-xs text-slate-400">
            Personal Operating System
          </p>
        </div>
      </div>
    </div>

    <!-- Main Menu -->
    <div class="space-y-1">
      <RouterLink
        v-for="item in mainMenu"
        :key="item.path"
        :to="item.path"
        class="group flex min-h-11 items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
        active-class="border border-cyan-500/30 bg-cyan-500/10 text-cyan-300"
        @click="$emit('navigate')"
      >
        <span class="shrink-0 text-lg leading-none">
          {{ item.icon }}
        </span>

        <span class="min-w-0 flex-1 truncate">
          {{ item.label }}
        </span>
      </RouterLink>
    </div>

    <!-- Life Modules -->
    <div class="mt-6">
      <p class="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-slate-500">
        Life Modules
      </p>

      <div class="space-y-1">
        <RouterLink
          v-for="item in lifeMenu"
          :key="item.path"
          :to="item.path"
          class="group flex min-h-11 items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
          active-class="border border-cyan-500/30 bg-cyan-500/10 text-cyan-300"
          @click="$emit('navigate')"
        >
          <span class="shrink-0 text-lg leading-none">
            {{ item.icon }}
          </span>

          <span class="min-w-0 flex-1 truncate">
            {{ item.label }}
          </span>
        </RouterLink>
      </div>
    </div>

    <!-- Management -->
    <div class="mt-6">
      <p class="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-slate-500">
        Management
      </p>

      <div class="space-y-1">
        <RouterLink
          v-for="item in managementMenu"
          :key="item.path"
          :to="item.path"
          class="group flex min-h-11 items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
          active-class="border border-cyan-500/30 bg-cyan-500/10 text-cyan-300"
          @click="$emit('navigate')"
        >
          <span class="shrink-0 text-lg leading-none">
            {{ item.icon }}
          </span>

          <span class="min-w-0 flex-1 truncate">
            {{ item.label }}
          </span>
        </RouterLink>
      </div>
    </div>

    <!-- System -->
    <div class="mt-6">
      <p class="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-slate-500">
        System
      </p>

      <div class="space-y-1">
        <RouterLink
          v-for="item in systemMenu"
          :key="item.path"
          :to="item.path"
          class="group flex min-h-11 items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-300 transition hover:bg-slate-800 hover:text-white"
          active-class="border border-cyan-500/30 bg-cyan-500/10 text-cyan-300"
          @click="$emit('navigate')"
        >
          <span class="shrink-0 text-lg leading-none">
            {{ item.icon }}
          </span>

          <span class="min-w-0 flex-1 truncate">
            {{ item.label }}
          </span>
        </RouterLink>

        <!-- Logout Button -->
        <button
          type="button"
          :disabled="isLoggingOut"
          class="group flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm font-medium text-red-300 transition hover:bg-red-500/10 hover:text-red-200 disabled:cursor-not-allowed disabled:opacity-60"
          @click="logout"
        >
          <span class="shrink-0 text-lg leading-none">
            🚪
          </span>

          <span class="min-w-0 flex-1 truncate">
            {{ isLoggingOut ? 'Logging out...' : 'Logout' }}
          </span>
        </button>
      </div>
    </div>

    <!-- Footer -->
    <div class="mt-auto pt-6">
      <div class="rounded-2xl border border-slate-800 bg-slate-950/70 p-3">
        <p class="text-xs font-semibold text-white">
          Mobile Ready
        </p>
        <p class="mt-1 text-xs leading-5 text-slate-400">
          Optimized for dashboard, finance, health, projects, and productivity.
        </p>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref } from 'vue'

defineEmits(['navigate'])

const isLoggingOut = ref(false)

const mainMenu = [
  {
    label: 'Dashboard',
    path: '/dashboard',
    icon: '🏠',
  },
  {
    label: 'Life Balance',
    path: '/life-balance',
    icon: '⚖️',
  },
]

const lifeMenu = [
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
    label: 'Productivity',
    path: '/productivity',
    icon: '✅',
  },
]

const managementMenu = [
  {
    label: 'Users Management',
    path: '/admin/users-management',
    icon: '👥',
  },
  {
    label: 'Point Ideas',
    path: '/admin/point-ideas',
    icon: '💡',
  },
]

const systemMenu = [
  {
    label: 'Settings',
    path: '/settings',
    icon: '⚙️',
  },
  {
    label: 'Profile',
    path: '/profile',
    icon: '👤',
  },
]

const authStorageKeys = [
  'token',
  'auth_token',
  'access_token',
  'nixlifeos_token',
  'user',
  'auth_user',
  'nixlifeos_user',
  'roles',
  'permissions',
]

const getStoredToken = () => {
  return (
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('nixlifeos_token') ||
    sessionStorage.getItem('token') ||
    sessionStorage.getItem('auth_token') ||
    sessionStorage.getItem('access_token') ||
    sessionStorage.getItem('nixlifeos_token')
  )
}

const clearAuthStorage = () => {
  authStorageKeys.forEach((key) => {
    localStorage.removeItem(key)
    sessionStorage.removeItem(key)
  })
}

const logout = async () => {
  if (isLoggingOut.value) {
    return
  }

  isLoggingOut.value = true

  const token = getStoredToken()
  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '/api/v1'

  try {
    if (token) {
      await fetch(`${apiBaseUrl}/auth/logout`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          Authorization: `Bearer ${token}`,
        },
      })
    }
  } catch (error) {
    console.warn('[Logout] API logout failed, clearing local session anyway.', error)
  } finally {
    clearAuthStorage()
    isLoggingOut.value = false

    window.location.href = '/login'
  }
}
</script>