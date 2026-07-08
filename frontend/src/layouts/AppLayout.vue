<script setup>
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import api, { clearAuthSession } from '@/services/api'
import { getAuthUser, hasPermission, hasRole } from '@/utils/auth'

const route = useRoute()
const router = useRouter()

const sidebarOpen = ref(false)
const sidebarCollapsed = ref(false)
const userMenuOpen = ref(false)

const user = computed(() => getAuthUser())

const canViewAdmin = computed(() => hasRole('admin'))
const canViewSecurity = computed(() => hasPermission('security.view'))
const canManageUsers = computed(() => hasRole('admin') && hasPermission('users.view'))
const canManageRoles = computed(() => hasRole('admin') && hasPermission('roles.manage'))

const menuGroups = computed(() => [
  {
    label: 'Main',
    items: [
      { label: 'Dashboard', icon: '🏠', to: '/dashboard', match: ['/dashboard'] },
    ],
  },
  {
    label: 'Health',
    items: [
      { label: 'Health Dashboard', icon: '❤️', to: '/health/dashboard', match: ['/health', '/health/dashboard'] },
      { label: 'Steps & KM', icon: '🚶', to: '/health/steps', match: ['/health/steps'] },
      { label: 'Sport', icon: '🏃', to: '/health/sports', match: ['/health/sports'] },
      { label: 'Hydration', icon: '💧', to: '/health/hydration', match: ['/health/hydration'] },
      { label: 'Calories', icon: '🔥', to: '/health/calories', match: ['/health/calories', '/health/nutrition'] },
      { label: 'Weight', icon: '⚖️', to: '/health/weight', match: ['/health/weight'] },
      { label: 'Goals & Limits', icon: '🎯', to: '/health/goals', match: ['/health/goals'] },
      { label: 'Medications', icon: '💊', to: '/health/medications', match: ['/health/medications'] },
      { label: 'Lab Tests', icon: '🧪', to: '/health/lab-tests', match: ['/health/lab-tests'] },
      { label: 'Health Reports', icon: '📄', to: '/health/reports', match: ['/health/reports'] },
    ],
  },
  {
    label: 'Finance',
    items: [
      { label: 'Finance', icon: '💰', to: '/finance/dashboard', match: ['/finance'] },
    ],
  },
  {
    label: 'To-Do',
    items: [
      { label: 'Dashboard', icon: '✅', to: '/todo/dashboard', match: ['/todo', '/todo/dashboard'] },
      { label: 'Tasks', icon: '📝', to: '/todo/tasks', match: ['/todo/tasks'] },
      { label: 'Projects', icon: '📌', to: '/todo/projects', match: ['/todo/projects'] },
    ],
  },
  {
    label: 'Projects',
    items: [
      { label: 'Projects', icon: '📁', to: '/projects', exact: true, match: ['/projects'] },
      { label: 'Tasks', icon: '🧩', to: '/projects/tasks', match: ['/projects/tasks'] },
      { label: 'Goals', icon: '🎯', to: '/projects/goals', match: ['/projects/goals'] },
    ],
  },
  {
    label: 'Productivity',
    items: [
      { label: 'Dashboard', icon: '✅', to: '/productivity', exact: true, match: ['/productivity'] },
      { label: 'Goals', icon: '🎯', to: '/productivity/goals', match: ['/productivity/goals'] },
      { label: 'Happy Wins', icon: '🏆', to: '/productivity/happy-wins', match: ['/productivity/happy-wins'] },
    ],
  },
  {
    label: 'Admin',
    show: canViewAdmin.value,
    items: [
      { label: 'User Management', icon: '👥', to: '/admin/users', match: ['/admin/users', '/admin/users-management', '/user-management/users'], show: canViewAdmin.value },
      { label: 'Admin Dashboard', icon: '🛡️', to: '/admin/dashboard', match: ['/admin/dashboard', '/admin'], show: canViewAdmin.value },
    ],
  },
  {
    label: 'System',
    items: [
      { label: 'Profile', icon: '👤', to: '/profile', match: ['/profile'] },
      { label: 'Settings', icon: '⚙️', to: '/settings', match: ['/settings'] },
    ],
  },
])

const routeTitle = computed(() => route.meta?.title || 'Nix Life OS')
const routeSubtitle = computed(() => route.meta?.subtitle || 'Personal Operating System')
const userEmail = computed(() => user.value?.email || 'User')
const userInitial = computed(() => userEmail.value.charAt(0).toUpperCase())

function isActive(item) {
  return item.match.some((path) => {
    if (item.exact || path === '/notifications' || path === '/admin' || path === '/security') {
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
    userMenuOpen.value = false
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
            <h1>Nix Life OS</h1>
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
        <div class="nix-sidebar-user-avatar">{{ userInitial }}</div>
        <div>
          <strong>Signed in</strong>
          <p>{{ user.email }}</p>
        </div>
      </div>

      <nav class="nix-sidebar-nav" aria-label="Main navigation">
        <section
          v-for="group in menuGroups"
          :key="group.label"
          v-show="isVisibleGroup(group)"
          class="nix-sidebar-group"
        >
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
              <span class="nix-sidebar-link-icon">{{ item.icon }}</span>
              <span v-if="!sidebarCollapsed" class="nix-sidebar-link-text">{{ item.label }}</span>
            </RouterLink>
            <RouterLink
      to="/todo"
      class="flex items-center gap-3 rounded-lg px-3 py-2 text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-800"
      active-class="bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-300"
    >
      <span class="text-lg">✅</span>
      <span>To-Do</span>
    </RouterLink>
          </div>
        </section>
      </nav>

      <div class="nix-sidebar-footer">
        <button
          type="button"
          class="nix-sidebar-collapse-button"
          @click="sidebarCollapsed = !sidebarCollapsed"
        >
          {{ sidebarCollapsed ? '→' : 'Collapse Sidebar' }}
        </button>

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

            <div class="nix-user-menu">
              <button
                type="button"
                class="nix-user-menu-button"
                aria-label="Open user menu"
                @click="userMenuOpen = !userMenuOpen"
              >
                <span class="nix-user-menu-avatar">{{ userInitial }}</span>
                <span class="nix-user-menu-email">{{ userEmail }}</span>
                <span>⌄</span>
              </button>

              <div v-if="userMenuOpen" class="nix-user-dropdown">
                <RouterLink to="/profile" class="nix-user-dropdown-link">Profile</RouterLink>
                <RouterLink to="/settings" class="nix-user-dropdown-link">Settings</RouterLink>
                <button type="button" class="nix-user-dropdown-link nix-user-dropdown-button" @click="logout">
                  Logout
                </button>
              </div>
            </div>
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

<style scoped>
.nix-app-shell {
  min-height: 100vh;
  background:
    radial-gradient(circle at top left, rgba(37, 99, 235, 0.08), transparent 34rem),
    var(--nix-bg);
}

.nix-mobile-backdrop {
  position: fixed;
  inset: 0;
  z-index: 49;
  background: rgba(15, 23, 42, 0.5);
  border: 0;
}

.nix-sidebar {
  position: fixed;
  inset: 0 auto 0 0;
  z-index: 50;
  display: flex;
  width: var(--nix-sidebar-width);
  flex-direction: column;
  background: #0f172a;
  border-right: 1px solid rgba(148, 163, 184, 0.16);
  color: #e2e8f0;
  transform: translateX(0);
  transition:
    width var(--nix-transition),
    transform var(--nix-transition);
}

.nix-sidebar--collapsed {
  width: 88px;
}

.nix-sidebar-brand-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: var(--nix-navbar-height);
  padding: 14px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.14);
}

.nix-sidebar-brand-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.nix-sidebar-logo,
.nix-sidebar-user-avatar,
.nix-user-menu-avatar {
  display: grid;
  place-items: center;
  flex: 0 0 auto;
  border-radius: 16px;
  font-weight: 950;
}

.nix-sidebar-logo {
  width: 44px;
  height: 44px;
  color: #ffffff;
  background: linear-gradient(135deg, #2563eb, #06b6d4);
  box-shadow: 0 12px 24px rgba(37, 99, 235, 0.28);
}

.nix-sidebar-brand-text {
  min-width: 0;
}

.nix-sidebar-brand-text h1 {
  margin: 0;
  color: #ffffff;
  font-size: 1rem;
  font-weight: 950;
  letter-spacing: -0.03em;
}

.nix-sidebar-brand-text p,
.nix-sidebar-user p {
  margin: 3px 0 0;
  color: #94a3b8;
  font-size: 0.78rem;
}

.nix-sidebar-user {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 14px;
  padding: 12px;
  background: rgba(15, 23, 42, 0.65);
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 18px;
}

.nix-sidebar-user-avatar {
  width: 36px;
  height: 36px;
  color: #bfdbfe;
  background: rgba(37, 99, 235, 0.22);
}

.nix-sidebar-user strong {
  display: block;
  color: #ffffff;
  font-size: 0.78rem;
}

.nix-sidebar-nav {
  flex: 1;
  min-height: 0;
  padding: 8px 12px 16px;
  overflow-y: auto;
}

.nix-sidebar-group {
  margin-top: 16px;
}

.nix-sidebar-group:first-child {
  margin-top: 4px;
}

.nix-sidebar-group-label {
  margin: 0 0 8px 10px;
  color: #64748b;
  font-size: 0.72rem;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.nix-sidebar-group-links {
  display: grid;
  gap: 4px;
}

.nix-sidebar-link {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 42px;
  padding: 10px 12px;
  color: #cbd5e1;
  border: 1px solid transparent;
  border-radius: 14px;
  font-size: 0.88rem;
  font-weight: 750;
  transition:
    background var(--nix-transition),
    border-color var(--nix-transition),
    color var(--nix-transition),
    transform var(--nix-transition);
}

.nix-sidebar-link:hover {
  color: #ffffff;
  background: rgba(37, 99, 235, 0.12);
  border-color: rgba(96, 165, 250, 0.22);
}

.nix-sidebar-link-active {
  color: #ffffff;
  background: linear-gradient(135deg, rgba(37, 99, 235, 0.95), rgba(8, 145, 178, 0.95));
  box-shadow: 0 10px 22px rgba(37, 99, 235, 0.2);
}

.nix-sidebar-link-icon {
  width: 22px;
  flex: 0 0 22px;
  text-align: center;
}

.nix-sidebar--collapsed .nix-sidebar-link {
  justify-content: center;
  padding-inline: 8px;
}

.nix-sidebar--collapsed .nix-sidebar-link-icon {
  width: auto;
  flex-basis: auto;
}

.nix-sidebar-footer {
  display: grid;
  gap: 8px;
  padding: 14px;
  border-top: 1px solid rgba(148, 163, 184, 0.14);
}

.nix-sidebar-collapse-button,
.nix-button-secondary {
  min-height: 40px;
  padding: 9px 12px;
  color: #e2e8f0;
  background: rgba(15, 23, 42, 0.75);
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 14px;
  font-weight: 800;
}

.nix-logout-button {
  color: #fecaca;
  background: rgba(220, 38, 38, 0.12);
  border-color: rgba(248, 113, 113, 0.24);
}

.nix-main-shell {
  min-width: 0;
  margin-left: var(--nix-sidebar-width);
  transition: margin-left var(--nix-transition);
}

.nix-main-shell--collapsed {
  margin-left: 88px;
}

.nix-app-header {
  position: sticky;
  top: 0;
  z-index: 30;
  min-height: var(--nix-navbar-height);
  background: rgba(246, 248, 251, 0.88);
  border-bottom: 1px solid var(--nix-border);
  backdrop-filter: blur(16px);
}

.nix-app-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  min-height: var(--nix-navbar-height);
  padding: 0 28px;
}

.nix-header-title-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.nix-route-title-block {
  min-width: 0;
}

.nix-route-title-block h1 {
  margin: 0;
  color: var(--nix-text);
  font-size: 1.05rem;
  font-weight: 950;
  letter-spacing: -0.03em;
}

.nix-route-title-block p {
  margin: 3px 0 0;
  color: var(--nix-text-muted);
  font-size: 0.82rem;
}

.nix-icon-button {
  display: grid;
  width: 42px;
  height: 42px;
  place-items: center;
  color: var(--nix-text);
  background: var(--nix-surface);
  border: 1px solid var(--nix-border);
  border-radius: 14px;
  box-shadow: var(--nix-shadow-sm);
}

.nix-mobile-close-button {
  display: none;
  color: #ffffff;
  background: rgba(15, 23, 42, 0.55);
  border-color: rgba(148, 163, 184, 0.18);
}

.nix-mobile-menu-button {
  display: none;
}

.nix-header-actions {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
}

.nix-ui-status-badge {
  display: inline-flex;
  align-items: center;
  min-height: 34px;
  padding: 8px 12px;
  color: #166534;
  background: var(--nix-success-soft);
  border: 1px solid rgba(22, 163, 74, 0.18);
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 900;
}

.nix-user-menu {
  position: relative;
}

.nix-user-menu-button {
  display: flex;
  align-items: center;
  gap: 9px;
  min-height: 42px;
  padding: 6px 10px 6px 6px;
  color: var(--nix-text);
  background: var(--nix-surface);
  border: 1px solid var(--nix-border);
  border-radius: 999px;
  box-shadow: var(--nix-shadow-sm);
}

.nix-user-menu-avatar {
  width: 30px;
  height: 30px;
  color: #ffffff;
  background: var(--nix-primary);
  border-radius: 999px;
}

.nix-user-menu-email {
  max-width: 190px;
  overflow: hidden;
  font-size: 0.86rem;
  font-weight: 800;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.nix-user-dropdown {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  display: grid;
  width: 220px;
  padding: 8px;
  background: var(--nix-surface);
  border: 1px solid var(--nix-border);
  border-radius: 18px;
  box-shadow: var(--nix-shadow-lg);
}

.nix-user-dropdown-link {
  padding: 10px 12px;
  color: var(--nix-text);
  border-radius: 12px;
  font-size: 0.9rem;
  font-weight: 800;
  text-align: left;
}

.nix-user-dropdown-link:hover {
  background: var(--nix-bg-soft);
}

.nix-user-dropdown-button {
  width: 100%;
  color: var(--nix-danger);
  background: transparent;
  border: 0;
}

.nix-page-shell {
  min-height: calc(100vh - var(--nix-navbar-height));
}

.nix-page-container {
  width: 100%;
  max-width: 1440px;
  margin: 0 auto;
  padding: 28px;
}

@media (max-width: 1024px) {
  .nix-sidebar {
    transform: translateX(-100%);
  }

  .nix-sidebar--open {
    transform: translateX(0);
  }

  .nix-sidebar--collapsed {
    width: var(--nix-sidebar-width);
  }

  .nix-main-shell,
  .nix-main-shell--collapsed {
    margin-left: 0;
  }

  .nix-mobile-close-button,
  .nix-mobile-menu-button {
    display: grid;
  }

  .nix-desktop-collapse-button {
    display: none;
  }

  .nix-sidebar-collapse-button {
    display: none;
  }

  .nix-app-header-inner {
    padding: 0 18px;
  }

  .nix-page-container {
    padding: 22px;
  }
}

@media (max-width: 720px) {
  .nix-app-header-inner {
    padding: 0 14px;
  }

  .nix-route-title-block p,
  .nix-ui-status-badge,
  .nix-user-menu-email {
    display: none;
  }

  .nix-page-container {
    padding: 18px 14px 92px;
  }
}
</style>
