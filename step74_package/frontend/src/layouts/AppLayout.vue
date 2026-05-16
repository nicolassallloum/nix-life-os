<script setup>
import { computed } from 'vue'
import { RouterLink, RouterView, useRouter } from 'vue-router'
import api, { clearAuthSession } from '@/services/api'
import { getAuthUser, hasPermission, hasRole } from '@/utils/auth'

const router = useRouter()

const linkClass =
  'block rounded-xl px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 hover:text-slate-950'

const activeClass = 'bg-slate-950 text-white hover:bg-slate-950 hover:text-white'

const user = computed(() => getAuthUser())
const canViewAdmin = computed(() => hasRole('admin'))
const canViewSecurity = computed(() => hasPermission('security.view'))
const canManageUsers = computed(() => hasRole('admin') && hasPermission('users.view'))

async function logout() {
  try {
    await api.post('/auth/logout')
  } catch (_error) {
    // The local session must still be cleared when the API token is already expired.
  } finally {
    clearAuthSession()
    router.push('/login')
  }
}
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <div class="flex min-h-screen">
      <aside class="w-64 shrink-0 border-r border-slate-200 bg-white px-5 py-6">
        <div class="mb-8">
          <h1 class="text-2xl font-black tracking-wide text-slate-950">NIX LIFE OS</h1>
          <p class="mt-1 text-xs text-slate-500">Personal Operating System</p>
          <p v-if="user?.email" class="mt-3 truncate text-xs text-slate-500">{{ user.email }}</p>
        </div>

        <nav class="space-y-6">
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Main</p>
            <div class="space-y-1">
              <RouterLink to="/dashboard" :class="linkClass" :active-class="activeClass">
                Dashboard
              </RouterLink>
              <RouterLink to="/unified-dashboard" :class="linkClass" :active-class="activeClass">
                Unified Dashboard
              </RouterLink>
              <RouterLink to="/ai/recommendations" :class="linkClass" :active-class="activeClass">
                AI Recommendations
              </RouterLink>
              <RouterLink to="/life-balance" :class="linkClass" :active-class="activeClass">
                Life Balance
              </RouterLink>
            </div>
          </div>

          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Productivity</p>
            <div class="space-y-1">
              <RouterLink to="/productivity/dashboard" :class="linkClass" :active-class="activeClass">
                Productivity Dashboard
              </RouterLink>
              <RouterLink to="/productivity/ai-insights" :class="linkClass" :active-class="activeClass">
                Productivity AI Insights
              </RouterLink>
              <RouterLink to="/productivity/tasks" :class="linkClass" :active-class="activeClass">
                Tasks
              </RouterLink>
              <RouterLink to="/productivity/habits" :class="linkClass" :active-class="activeClass">
                Habits
              </RouterLink>
              <RouterLink to="/productivity/goals" :class="linkClass" :active-class="activeClass">
                Goals
              </RouterLink>
              <RouterLink to="/productivity/calendar" :class="linkClass" :active-class="activeClass">
                Calendar / Schedule
              </RouterLink>
            </div>
          </div>

          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Finance</p>
            <div class="space-y-1">
              <RouterLink to="/finance/dashboard" :class="linkClass" :active-class="activeClass">
                Finance Dashboard
              </RouterLink>
              <RouterLink to="/finance/accounts" :class="linkClass" :active-class="activeClass">
                Finance Accounts
              </RouterLink>
              <RouterLink to="/finance/transactions" :class="linkClass" :active-class="activeClass">
                Finance Transactions
              </RouterLink>
              <RouterLink to="/finance/budgets" :class="linkClass" :active-class="activeClass">
                Finance Budgets
              </RouterLink>
            </div>
          </div>

          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Health</p>
            <div class="space-y-1">
              <RouterLink to="/health" :class="linkClass" :active-class="activeClass">
                Health Dashboard
              </RouterLink>
              <RouterLink to="/health/ai-insights" :class="linkClass" :active-class="activeClass">
                Health AI Insights
              </RouterLink>
              <RouterLink to="/health/steps" :class="linkClass" :active-class="activeClass">
                Steps Tracking
              </RouterLink>
              <RouterLink to="/health/weight" :class="linkClass" :active-class="activeClass">
                Weight Tracking
              </RouterLink>
              <RouterLink to="/health/nutrition" :class="linkClass" :active-class="activeClass">
                Nutrition Tracking
              </RouterLink>
              <RouterLink to="/health/custom-foods" :class="linkClass" :active-class="activeClass">
                Custom Foods
              </RouterLink>
              <RouterLink to="/health/hydration" :class="linkClass" :active-class="activeClass">
                Hydration Tracking
              </RouterLink>
              <RouterLink to="/health/sleep" :class="linkClass" :active-class="activeClass">
                Sleep Tracking
              </RouterLink>
              <RouterLink to="/health/medications" :class="linkClass" :active-class="activeClass">
                Medication Tracking
              </RouterLink>
              <RouterLink to="/health/lab-tests" :class="linkClass" :active-class="activeClass">
                Lab Tests
              </RouterLink>
              <RouterLink to="/health/alerts" :class="linkClass" :active-class="activeClass">
                Health Alerts
              </RouterLink>
              <RouterLink to="/health/reports" :class="linkClass" :active-class="activeClass">
                Health Reports
              </RouterLink>
            </div>
          </div>

          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Projects</p>
            <div class="space-y-1">
              <RouterLink to="/projects/dashboard" :class="linkClass" :active-class="activeClass">
                Projects Dashboard
              </RouterLink>
              <RouterLink to="/projects/list" :class="linkClass" :active-class="activeClass">
                Project List
              </RouterLink>
              <RouterLink to="/projects/tasks" :class="linkClass" :active-class="activeClass">
                Project Tasks
              </RouterLink>
              <RouterLink to="/projects/milestones" :class="linkClass" :active-class="activeClass">
                Project Milestones
              </RouterLink>
              <RouterLink to="/projects/progress" :class="linkClass" :active-class="activeClass">
                Project Progress
              </RouterLink>
              <RouterLink to="/projects/status-updates" :class="linkClass" :active-class="activeClass">
                Status Updates
              </RouterLink>
            </div>
          </div>

          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Notifications</p>
            <div class="space-y-1">
              <RouterLink to="/notifications" :class="linkClass" :active-class="activeClass">
                Notifications
              </RouterLink>
              <RouterLink to="/notifications/settings" :class="linkClass" :active-class="activeClass">
                Notification Settings
              </RouterLink>
            </div>
          </div>

          <div v-if="canViewAdmin || canViewSecurity || canManageUsers">
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">Admin & Security</p>
            <div class="space-y-1">
              <RouterLink v-if="canViewAdmin" to="/admin" :class="linkClass" :active-class="activeClass">
                Admin Dashboard
              </RouterLink>
              <RouterLink v-if="canManageUsers" to="/admin/users" :class="linkClass" :active-class="activeClass">
                User Management
              </RouterLink>
              <RouterLink v-if="canViewAdmin" to="/admin/roles" :class="linkClass" :active-class="activeClass">
                Roles & Permissions
              </RouterLink>
              <RouterLink v-if="canViewSecurity" to="/security" :class="linkClass" :active-class="activeClass">
                Security
              </RouterLink>
              <RouterLink v-if="canViewSecurity" to="/security/audit-logs" :class="linkClass" :active-class="activeClass">
                Audit Logs
              </RouterLink>
            </div>
          </div>

          <button
            type="button"
            class="w-full rounded-xl border border-slate-200 px-4 py-2 text-left text-sm font-semibold text-slate-700 hover:bg-slate-100"
            @click="logout"
          >
            Logout
          </button>
        </nav>
      </aside>

      <main class="min-w-0 flex-1 overflow-x-hidden">
        <div class="p-6">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>
