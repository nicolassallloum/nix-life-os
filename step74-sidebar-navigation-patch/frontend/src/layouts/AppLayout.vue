<script setup>
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import api, { clearAuthSession } from '@/services/api'
import { getAuthUser, hasPermission, hasRole } from '@/utils/auth'

const route = useRoute()
const router = useRouter()
const sidebarOpen = ref(false)

const baseLinkClass =
  'flex items-center rounded-xl px-4 py-2.5 text-sm font-medium transition-colors'
const inactiveLinkClass = 'text-slate-700 hover:bg-slate-100 hover:text-slate-950'
const activeLinkClass = 'bg-slate-950 text-white shadow-sm hover:bg-slate-950 hover:text-white'

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
  } catch (_error) {
    // Keep logout safe when the backend token is already expired or revoked.
  } finally {
    clearAuthSession()
    await router.replace('/login')
  }
}
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <header class="sticky top-0 z-40 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 lg:hidden">
      <div>
        <h1 class="text-lg font-black tracking-wide text-slate-950">NIX LIFE OS</h1>
        <p class="text-xs text-slate-500">Personal Operating System</p>
      </div>

      <button
        type="button"
        class="rounded-xl border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700"
        @click="sidebarOpen = !sidebarOpen"
      >
        {{ sidebarOpen ? 'Close' : 'Menu' }}
      </button>
    </header>

    <div v-if="sidebarOpen" class="fixed inset-0 z-30 bg-slate-950/40 lg:hidden" @click="sidebarOpen = false" />

    <div class="flex min-h-screen">
      <aside
        class="fixed inset-y-0 left-0 z-40 w-72 shrink-0 transform border-r border-slate-200 bg-white px-5 py-6 transition-transform duration-200 lg:static lg:z-auto lg:w-64 lg:translate-x-0"
        :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
      >
        <div class="mb-8 flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h1 class="text-2xl font-black tracking-wide text-slate-950">NIX LIFE OS</h1>
            <p class="mt-1 text-xs text-slate-500">Personal Operating System</p>
            <p v-if="user?.email" class="mt-3 truncate text-xs text-slate-500">{{ user.email }}</p>
          </div>

          <button
            type="button"
            class="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-600 lg:hidden"
            @click="sidebarOpen = false"
          >
            ✕
          </button>
        </div>

        <nav class="max-h-[calc(100vh-9rem)] space-y-6 overflow-y-auto pr-1">
          <section v-for="group in menuGroups" :key="group.label" v-show="isVisibleGroup(group)">
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              {{ group.label }}
            </p>

            <div class="space-y-1">
              <RouterLink
                v-for="item in visibleItems(group)"
                :key="item.to"
                :to="item.to"
                :class="linkClass(item)"
              >
                {{ item.label }}
              </RouterLink>
            </div>
          </section>

          <button
            type="button"
            class="w-full rounded-xl border border-slate-200 px-4 py-2 text-left text-sm font-semibold text-slate-700 hover:bg-slate-100"
            @click="logout"
          >
            Logout
          </button>
        </nav>
      </aside>

      <main class="min-w-0 flex-1 overflow-x-hidden lg:ml-0">
        <div class="p-4 sm:p-6 lg:p-8">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>
