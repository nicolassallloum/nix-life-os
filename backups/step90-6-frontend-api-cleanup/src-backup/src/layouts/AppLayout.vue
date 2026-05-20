<script setup>
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import api, { clearAuthSession } from '@/services/api'
import { getAuthUser, hasPermission, hasRole } from '@/utils/auth'

const route = useRoute()
const router = useRouter()
const sidebarOpen = ref(false)
const sidebarCollapsed = ref(false)

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
  return ['nix-sidebar-link', isActive(item) ? 'nix-sidebar-link-active' : '']
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
  <div class="nix-app-shell">
    <button
      v-if="sidebarOpen"
      type="button"
      class="nix-mobile-backdrop"
      aria-label="Close menu backdrop"
      @click="sidebarOpen = false"
    />

    <aside
      class="nix-sidebar"
      :class="{
        'nix-sidebar--open': sidebarOpen,
        'nix-sidebar--collapsed': sidebarCollapsed,
      }"
    >
      <div class="nix-sidebar-brand-row">
        <div class="nix-sidebar-brand-wrap">
          <div class="nix-sidebar-logo">N</div>

          <div v-if="!sidebarCollapsed" class="nix-sidebar-brand-text">
            <h1>NIX LIFE OS</h1>
            <p>Personal Operating System</p>
          </div>
        </div>

        <button
          type="button"
          class="nix-icon-button nix-mobile-close-button"
          aria-label="Close menu"
          @click="sidebarOpen = false"
        >
          ✕
        </button>
      </div>

      <div v-if="user?.email && !sidebarCollapsed" class="nix-sidebar-user">
        <p>{{ user.email }}</p>
      </div>

      <nav class="nix-sidebar-nav">
        <section v-for="group in menuGroups" :key="group.label" v-show="isVisibleGroup(group)" class="nix-sidebar-group">
          <p v-if="!sidebarCollapsed" class="nix-sidebar-group-label">
            {{ group.label }}
          </p>

          <div class="nix-sidebar-group-links">
            <RouterLink
              v-for="item in visibleItems(group)"
              :key="item.to"
              :to="item.to"
              :class="linkClass(item)"
              :title="sidebarCollapsed ? item.label : undefined"
            >
              <span v-if="sidebarCollapsed" class="nix-sidebar-dot" />
              <span v-else class="nix-sidebar-link-text">{{ item.label }}</span>
            </RouterLink>
          </div>
        </section>
      </nav>

      <div class="nix-sidebar-footer">
        <button
          type="button"
          class="nix-button-secondary nix-logout-button"
          @click="logout"
        >
          {{ sidebarCollapsed ? '⏻' : 'Logout' }}
        </button>
      </div>
    </aside>

    <div
      class="nix-main-shell"
      :class="{ 'nix-main-shell--collapsed': sidebarCollapsed }"
    >
      <header class="nix-app-header">
        <div class="nix-app-header-inner">
          <div class="nix-header-title-wrap">
            <button
              type="button"
              class="nix-icon-button nix-mobile-menu-button"
              aria-label="Open menu"
              @click="sidebarOpen = true"
            >
              ☰
            </button>

            <button
              type="button"
              class="nix-icon-button nix-desktop-collapse-button"
              aria-label="Toggle sidebar"
              @click="sidebarCollapsed = !sidebarCollapsed"
            >
              ☰
            </button>

            <div class="nix-route-title-block">
              <h1>{{ routeTitle }}</h1>
              <p>{{ routeSubtitle }}</p>
            </div>
          </div>

          <div class="nix-header-actions">
            <span class="nix-ui-status-badge">UI Stable</span>
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
