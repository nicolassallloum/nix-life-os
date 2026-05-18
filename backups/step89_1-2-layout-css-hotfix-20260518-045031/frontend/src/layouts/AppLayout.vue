<script setup>
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import api, { clearAuthSession } from '@/services/api'
import { getAuthUser, hasPermission, hasRole } from '@/utils/auth'

const route = useRoute()
const router = useRouter()
const sidebarOpen = ref(false)
const sidebarCollapsed = ref(false)

const baseLinkClass =
  'nix-sidebar-link'
const inactiveLinkClass = 'text-slate-600 hover:bg-slate-100 hover:text-slate-950'
const activeLinkClass = 'nix-sidebar-link-active'

const user = computed(() => getAuthUser())
const canViewAdmin = computed(() => hasRole('admin'))
const canViewSecurity = computed(() => hasPermission('security.view'))
const canManageUsers = computed(() => hasRole('admin') && hasPermission('users.view'))
const canManageRoles = computed(() => hasRole('admin') && hasPermission('roles.manage'))

const menuGroups = computed(() => [
  {
    label: 'Main',
    items: [
      { label: 'Dashboard', to: '/dashboard', match: ['/dashboard'] },
      { label: 'Unified Dashboard', to: '/unified-dashboard', match: ['/unified-dashboard'] },
      { label: 'AI Recommendations', to: '/ai/recommendations', match: ['/ai'] },
      { label: 'Life Balance', to: '/life-balance', match: ['/life-balance'] },
    ],
  },
  {
    label: 'Productivity',
    items: [
      { label: 'Productivity Dashboard', to: '/productivity/dashboard', match: ['/productivity/dashboard'] },
      { label: 'Productivity AI Insights', to: '/productivity/ai-insights', match: ['/productivity/ai-insights'] },
      { label: 'Tasks', to: '/productivity/tasks', match: ['/productivity/tasks', '/tasks'] },
      { label: 'Habits', to: '/productivity/habits', match: ['/productivity/habits'] },
      { label: 'Goals', to: '/productivity/goals', match: ['/productivity/goals'] },
      { label: 'Calendar / Schedule', to: '/productivity/calendar', match: ['/productivity/calendar', '/calendar', '/schedule', '/productivity/schedule'] },
    ],
  },
  {
    label: 'Finance',
    items: [
      { label: 'Finance Dashboard', to: '/finance/dashboard', match: ['/finance/dashboard'] },
      { label: 'Finance AI Insights', to: '/finance/ai-insights', match: ['/finance/ai-insights'] },
      { label: 'Finance Accounts', to: '/finance/accounts', match: ['/finance/accounts'] },
      { label: 'Finance Transactions', to: '/finance/transactions', match: ['/finance/transactions'] },
      { label: 'Finance Budgets', to: '/finance/budgets', match: ['/finance/budgets'] },
      { label: 'Finance Expenses', to: '/finance/expenses', match: ['/finance/expenses'] },
    ],
  },
  {
    label: 'Health',
    items: [
      { label: 'Health Dashboard', to: '/health', exact: true, match: ['/health'] },
      { label: 'Health AI Insights', to: '/health/ai-insights', match: ['/health/ai-insights'] },
      { label: 'Steps Tracking', to: '/health/steps', match: ['/health/steps'] },
      { label: 'Weight Tracking', to: '/health/weight', match: ['/health/weight'] },
      { label: 'Nutrition Tracking', to: '/health/nutrition', match: ['/health/nutrition'] },
      { label: 'Custom Foods', to: '/health/custom-foods', match: ['/health/custom-foods'] },
      { label: 'Hydration Tracking', to: '/health/hydration', match: ['/health/hydration'] },
      { label: 'Sleep Tracking', to: '/health/sleep', match: ['/health/sleep'] },
      { label: 'Medication Tracking', to: '/health/medications', match: ['/health/medications'] },
      { label: 'Medicaments', to: '/health/medicaments', match: ['/health/medicaments'] },
      { label: 'Lab Tests', to: '/health/lab-tests', match: ['/health/lab-tests'] },
      { label: 'Mood Tracking', to: '/health/mood', match: ['/health/mood'] },
      { label: 'Health Alerts', to: '/health/alerts', match: ['/health/alerts'] },
      { label: 'Health Reports', to: '/health/reports', match: ['/health/reports'] },
    ],
  },
  {
    label: 'Projects',
    items: [
      { label: 'Projects Dashboard', to: '/projects/dashboard', match: ['/projects/dashboard'] },
      { label: 'Project List', to: '/projects/list', match: ['/projects/list'] },
      { label: 'Project Tasks', to: '/projects/tasks', match: ['/projects/tasks'] },
      { label: 'Project Milestones', to: '/projects/milestones', match: ['/projects/milestones'] },
      { label: 'Project Progress', to: '/projects/progress', match: ['/projects/progress'] },
      { label: 'Status Updates', to: '/projects/status-updates', match: ['/projects/status-updates'] },
    ],
  },
  {
    label: 'Notifications',
    items: [
      { label: 'Notifications', to: '/notifications', exact: true, match: ['/notifications'] },
      { label: 'Notification Settings', to: '/notifications/settings', match: ['/notifications/settings'] },
    ],
  },
  {
    label: 'System',
    items: [
      { label: 'Logging & Monitoring', to: '/system/monitoring', match: ['/system/monitoring', '/monitoring'] },
    ],
  },
  {
    label: 'Admin & Security',
    show: canViewAdmin.value || canViewSecurity.value || canManageUsers.value || canManageRoles.value,
    items: [
      { label: 'Admin Dashboard', to: '/admin', exact: true, match: ['/admin'], show: canViewAdmin.value },
      { label: 'User Management', to: '/admin/users', match: ['/admin/users', '/user-management/users'], show: canManageUsers.value },
      { label: 'Roles & Permissions', to: '/admin/roles', match: ['/admin/roles', '/admin/permissions', '/security/roles', '/security/permissions', '/user-management/roles'], show: canManageRoles.value },
      { label: 'Security Overview', to: '/security', exact: true, match: ['/security'], show: canViewSecurity.value },
      { label: 'Audit Logs', to: '/security/audit-logs', match: ['/security/audit-logs', '/security/login-history'], show: canViewSecurity.value },
    ],
  },
])

const routeTitle = computed(() => route.meta?.title || 'Nix Life OS')
const routeSubtitle = computed(() => route.meta?.subtitle || 'Personal Operating System')

function isActive(item) {
  return item.match.some((path) => {
    if (item.exact || path === '/health' || path === '/notifications' || path === '/admin' || path === '/security') {
      return route.path === path
    }

    return route.path === path || route.path.startsWith(`${path}/`)
  })
}

function linkClass(item) {
  return [baseLinkClass, isActive(item) ? activeLinkClass : inactiveLinkClass]
}

function visibleItems(group) {
  return group.items.filter((item) => item.show !== false)
}

function isVisibleGroup(group) {
  return group.show !== false && visibleItems(group).length > 0
}

watch(
  () => route.fullPath,
  () => {
    sidebarOpen.value = false
  },
)

async function logout() {
  try {
    await api.post('/auth/logout')
  } catch {
    // Keep logout safe when the backend token is already expired, revoked, or temporarily unavailable.
  } finally {
    clearAuthSession()
    await router.replace('/login')
  }
}
</script>

<template>
  <div class="min-h-screen bg-slate-50 text-slate-900">
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-40 bg-slate-950/50 backdrop-blur-sm lg:hidden"
      @click="sidebarOpen = false"
    />

    <aside
      class="fixed inset-y-0 left-0 z-50 flex flex-col border-r border-slate-200 bg-white shadow-sm transition-all duration-300"
      :class="[
        sidebarCollapsed ? 'lg:w-20' : 'lg:w-72',
        'w-72',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
      ]"
    >
      <div class="flex h-16 shrink-0 items-center justify-between gap-3 border-b border-slate-200 px-4">
        <div class="flex min-w-0 items-center gap-3">
          <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-slate-950 text-sm font-black text-white">
            N
          </div>

          <div v-if="!sidebarCollapsed" class="min-w-0">
            <h1 class="truncate text-sm font-black tracking-wide text-slate-950">NIX LIFE OS</h1>
            <p class="truncate text-xs text-slate-500">Personal Operating System</p>
          </div>
        </div>

        <button
          type="button"
          class="nix-icon-button lg:hidden"
          aria-label="Close menu"
          @click="sidebarOpen = false"
        >
          ✕
        </button>
      </div>

      <div v-if="user?.email && !sidebarCollapsed" class="border-b border-slate-100 px-4 py-3">
        <p class="truncate text-xs font-medium text-slate-500">{{ user.email }}</p>
      </div>

      <nav class="flex-1 space-y-6 overflow-y-auto px-3 py-4">
        <section v-for="group in menuGroups" :key="group.label" v-show="isVisibleGroup(group)">
          <p
            v-if="!sidebarCollapsed"
            class="mb-2 px-3 text-xs font-bold uppercase tracking-wide text-slate-400"
          >
            {{ group.label }}
          </p>

          <div class="space-y-1">
            <RouterLink
              v-for="item in visibleItems(group)"
              :key="item.to"
              :to="item.to"
              :class="linkClass(item)"
              :title="sidebarCollapsed ? item.label : undefined"
            >
              <span
                v-if="sidebarCollapsed"
                class="mx-auto h-2 w-2 rounded-full bg-current opacity-70"
              />
              <span v-else class="truncate">{{ item.label }}</span>
            </RouterLink>
          </div>
        </section>
      </nav>

      <div class="border-t border-slate-200 p-3">
        <button
          type="button"
          class="nix-button-secondary w-full justify-center"
          :class="sidebarCollapsed ? 'px-2' : ''"
          @click="logout"
        >
          {{ sidebarCollapsed ? '⏻' : 'Logout' }}
        </button>
      </div>
    </aside>

    <div
      class="min-h-screen transition-all duration-300"
      :class="sidebarCollapsed ? 'lg:pl-20' : 'lg:pl-72'"
    >
      <header class="sticky top-0 z-30 border-b border-slate-200 bg-white/95 backdrop-blur">
        <div class="flex h-16 items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          <div class="flex min-w-0 items-center gap-3">
            <button
              type="button"
              class="nix-icon-button lg:hidden"
              aria-label="Open menu"
              @click="sidebarOpen = true"
            >
              ☰
            </button>

            <button
              type="button"
              class="nix-icon-button hidden lg:inline-flex"
              aria-label="Toggle sidebar"
              @click="sidebarCollapsed = !sidebarCollapsed"
            >
              ☰
            </button>

            <div class="min-w-0">
              <h1 class="truncate text-lg font-black text-slate-950 sm:text-xl">
                {{ routeTitle }}
              </h1>
              <p class="hidden truncate text-xs text-slate-500 sm:block">
                {{ routeSubtitle }}
              </p>
            </div>
          </div>

          <div class="flex shrink-0 items-center gap-2">
            <span class="hidden rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700 sm:inline-flex">
              UI Stable
            </span>
          </div>
        </div>
      </header>

      <main class="nix-page-shell">
        <div class="nix-page-container">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>
