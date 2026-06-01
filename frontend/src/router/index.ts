// @ts-nocheck
import { createRouter, createWebHistory } from 'vue-router'
import { canAccessRoute, getAuthToken, getAuthUser } from '@/utils/auth'
import UnderConstructionView from '@/views/system/UnderConstructionView.vue'
import ApplicationDownView from '@/views/system/ApplicationDownView.vue'
import ComingSoonView from '@/views/ComingSoonView.vue'
const LoginView = () => import('@/views/auth/LoginView.vue')
const RegisterView = () => import('@/views/auth/RegisterView.vue')
const UnauthorizedView = () => import('@/views/auth/UnauthorizedView.vue')
const NotFoundView = () => import('@/views/NotFoundView.vue')

const DashboardView = () => import('@/views/dashboard/DashboardView.vue')
const UnifiedDashboardView = () => import('@/views/dashboard/UnifiedDashboardView.vue')
const LifeBalanceView = () => import('@/views/life-balance/LifeBalanceView.vue')
const AIRecommendationsView = () => import('@/views/ai/AIRecommendationsView.vue')

const ProductivityDashboardView = () => import('@/views/productivity/ProductivityDashboardView.vue')
const ProductivityAIInsightsView = () => import('@/views/productivity/ProductivityAIInsightsView.vue')
const TasksView = () => import('@/views/productivity/TasksView.vue')
const HabitsView = () => import('@/views/productivity/HabitsView.vue')
const GoalsView = () => import('@/views/productivity/GoalsView.vue')
const CalendarView = () => import('@/views/productivity/CalendarView.vue')

const FinanceDashboardView = () => import('@/views/finance/FinanceDashboardView.vue')
const FinanceAccountsView = () => import('@/views/finance/FinanceAccountsView.vue')
const FinanceTransactionsView = () => import('@/views/finance/FinanceTransactionsView.vue')
const FinanceBudgetsView = () => import('@/views/finance/FinanceBudgetsView.vue')
const FinanceAIInsightsView = () => import('@/views/finance/FinanceAIInsightsView.vue')
const ExpensesView = () => import('@/views/finance/ExpensesView.vue')

const HealthView = () => import('@/views/health/HealthView.vue')
const HealthAIInsightsView = () => import('@/views/health/HealthAIInsightsView.vue')
const StepsTrackingView = () => import('@/views/health/StepsTrackingView.vue')
const WeightTrackingView = () => import('@/views/health/WeightTrackingView.vue')
const NutritionTrackingView = () => import('@/views/health/NutritionTrackingView.vue')
const HydrationTrackingView = () => import('@/views/health/HydrationTrackingView.vue')
const CustomFoodsView = () => import('@/views/health/CustomFoodsView.vue')
const SleepTrackingView = () => import('@/views/health/SleepTrackingView.vue')
const MedicationTrackingView = () => import('@/views/health/MedicationTrackingView.vue')
const MedicamentsTrackingView = () => import('@/views/health/MedicamentsTrackingView.vue')
const LabTestsTrackingView = () => import('@/views/health/LabTestsTrackingView.vue')
const MoodTrackingView = () => import('@/views/health/MoodTrackingView.vue')
const HealthAlertsView = () => import('@/views/health/HealthAlertsView.vue')
const HealthReportsView = () => import('@/views/health/HealthReportsView.vue')
const NutritionDashboardView = () => import('@/views/health/nutrition/NutritionDashboardView.vue')
const FoodItemsView = () => import('@/views/health/nutrition/FoodItemsView.vue')
const MealLoggerView = () => import('@/views/health/nutrition/MealLoggerView.vue')

const ProjectsDashboardView = () => import('@/views/projects/ProjectDashboardView.vue')
const ProjectsView = () => import('@/views/projects/ProjectsView.vue')
const ProjectTasksView = () => import('@/views/ProjectTasksView.vue')
const ProjectMilestonesView = () => import('@/views/ProjectMilestonesView.vue')
const ProjectProgressView = () => import('@/views/ProjectProgressView.vue')
const ProjectStatusUpdatesView = () => import('@/views/ProjectStatusUpdatesView.vue')

const NotificationsView = () => import('@/views/notifications/NotificationsView.vue')
const NotificationSettingsView = () => import('@/views/notifications/NotificationSettingsView.vue')
const MonitoringDashboardView = () => import('@/views/monitoring/MonitoringDashboardView.vue')

const AdminOverviewView = () => import('@/views/admin/AdminOverviewView.vue')
const AdminUsersView = () => import('@/views/admin/AdminUsersView.vue')
const AdminUsersManagementView = () => import('@/views/admin/AdminUsersManagementView.vue')
const AdminRolesView = () => import('@/views/admin/AdminRolesView.vue')
const SecurityOverviewView = () => import('@/views/security/SecurityOverviewView.vue')
const SecurityAuditLogsView = () => import('@/views/security/SecurityAuditLogsView.vue')

const authStorageKeys = [
  'token',
  'auth_token',
  'access_token',
  'nixlifeos_token',
]

const getStoredToken = () => {
  return (
    getAuthToken?.() ||
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

const routes = [
  { path: '/', redirect: '/dashboard' },

  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: { guestOnly: true, publicLayout: true, title: 'Login' },
  },
  {
    path: '/register',
    name: 'Register',
    component: RegisterView,
    meta: { guestOnly: true, publicLayout: true, title: 'Register' },
  },
  {
    path: '/application-down',
    name: 'ApplicationDown',
    component: ApplicationDownView,
    meta: {
      title: 'Application Temporarily Down',
      requiresAuth: false
    }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: ComingSoonView,
    meta: {
      title: 'Settings',
      requiresAuth: true
    }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: ComingSoonView,
    meta: {
      title: 'Profile',
      requiresAuth: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'PageNotFound',
    component: ComingSoonView,
    meta: {
      title: 'Under Construction',
      requiresAuth: false
    }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: DashboardView,
    meta: { requiresAuth: true, title: 'Dashboard' },
  },
  {
    path: '/unified-dashboard',
    name: 'UnifiedDashboard',
    component: UnifiedDashboardView,
    meta: { requiresAuth: true, title: 'Unified Dashboard' },
  },
  {
    path: '/life-balance',
    name: 'LifeBalance',
    component: LifeBalanceView,
    meta: { requiresAuth: true, title: 'Life Balance' },
  },

  { path: '/ai', redirect: '/ai/recommendations' },
  {
    path: '/ai/recommendations',
    name: 'AIRecommendations',
    component: AIRecommendationsView,
    meta: { requiresAuth: true, title: 'AI Recommendations' },
  },

  { path: '/productivity', redirect: '/productivity/dashboard' },
  {
    path: '/productivity/dashboard',
    name: 'ProductivityDashboard',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Productivity Dashboard' },
  },
  {
    path: '/productivity/ai-insights',
    name: 'ProductivityAIInsights',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Productivity AI Insights' },
  },
  {
    path: '/productivity/tasks',
    name: 'ProductivityTasks',
    component: ComingSoonView,
    alias: ['/tasks'],
    meta: { requiresAuth: true, title: 'Tasks' },
  },
  {
    path: '/productivity/habits',
    name: 'ProductivityHabits',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Habits' },
  },
  {
    path: '/productivity/goals',
    name: 'ProductivityGoals',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Goals' },
  },
  {
    path: '/productivity/calendar',
    name: 'ProductivityCalendar',
    component: ComingSoonView,
    alias: ['/calendar', '/schedule', '/productivity/schedule'],
    meta: { requiresAuth: true, title: 'Calendar / Schedule' },
  },

  { path: '/finance', redirect: '/finance/dashboard' },
  {
    path: '/finance/dashboard',
    name: 'FinanceDashboard',
    component: FinanceDashboardView,
    meta: { requiresAuth: true, title: 'Finance Dashboard' },
  },
  {
    path: '/finance/ai-insights',
    name: 'FinanceAIInsights',
    component: FinanceAIInsightsView,
    meta: { requiresAuth: true, title: 'Finance AI Insights' },
  },
  {
    path: '/finance/accounts',
    name: 'FinanceAccounts',
    component: FinanceAccountsView,
    meta: { requiresAuth: true, title: 'Finance Accounts' },
  },
  {
    path: '/finance/transactions',
    name: 'FinanceTransactions',
    component: FinanceTransactionsView,
    meta: { requiresAuth: true, title: 'Finance Transactions' },
  },
  {
    path: '/finance/budgets',
    name: 'FinanceBudgets',
    component: FinanceBudgetsView,
    meta: { requiresAuth: true, title: 'Finance Budgets' },
  },
  {
    path: '/finance/expenses',
    name: 'FinanceExpenses',
    component: ExpensesView,
    meta: { requiresAuth: true, title: 'Finance Expenses' },
  },

  {
    path: '/health',
    name: 'HealthDashboard',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Health Dashboard' },
  },
  {
    path: '/health/ai-insights',
    name: 'HealthAIInsights',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Health AI Insights' },
  },
  {
    path: '/health/steps',
    name: 'HealthSteps',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Steps Tracking' },
  },
  {
    path: '/health/weight',
    name: 'HealthWeight',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Weight Tracking' },
  },
  {
    path: '/health/nutrition',
    name: 'HealthNutrition',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Nutrition Tracking' },
  },
  {
    path: '/health/nutrition/dashboard',
    name: 'HealthNutritionDashboard',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Nutrition Dashboard' },
  },
  {
    path: '/health/nutrition/food-items',
    name: 'HealthFoodItems',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Food Items' },
  },
  {
    path: '/health/nutrition/meal-logger',
    name: 'HealthMealLogger',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Meal Logger' },
  },
  {
    path: '/health/custom-foods',
    name: 'HealthCustomFoods',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Custom Foods' },
  },
  {
    path: '/health/hydration',
    name: 'HealthHydration',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Hydration Tracking' },
  },
  {
    path: '/health/sleep',
    name: 'HealthSleep',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Sleep Tracking' },
  },

  {
    path: '/offline/sync-center',
    name: 'OfflineSyncCenter',
    component: () => import('@/views/offline/SyncCenterView.vue'),
    meta: { requiresAuth: true, title: 'Offline Sync Center' },
  },
  {
    path: '/health/medications',
    name: 'HealthMedications',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Medication Tracking' },
  },
  {
    path: '/health/medicaments',
    name: 'HealthMedicaments',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Medicaments' },
  },
  {
    path: '/health/lab-tests',
    name: 'HealthLabTests',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Lab Tests' },
  },
  {
    path: '/health/mood',
    name: 'HealthMood',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Mood Tracking' },
  },
  {
    path: '/health/alerts',
    name: 'HealthAlerts',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Health Alerts' },
  },
  {
    path: '/health/reports',
    name: 'HealthReports',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Health Reports' },
  },

  { path: '/projects', redirect: '/projects/list' },
  {
    path: '/projects/dashboard',
    name: 'ProjectsDashboard',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Projects Dashboard' },
  },
  {
    path: '/projects/list',
    name: 'ProjectsList',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Project List' },
  },
  {
    path: '/projects/tasks',
    name: 'ProjectTasks',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Project Tasks' },
  },
  {
    path: '/projects/milestones',
    name: 'ProjectMilestones',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Project Milestones' },
  },
  {
    path: '/projects/progress',
    name: 'ProjectProgress',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Project Progress' },
  },
  {
    path: '/projects/status-updates',
    name: 'ProjectStatusUpdates',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Status Updates' },
  },

  {
    path: '/notifications',
    name: 'Notifications',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Notifications' },
  },
  {
    path: '/notifications/settings',
    name: 'NotificationSettings',
    component: ComingSoonView,
    meta: { requiresAuth: true, title: 'Notification Settings' },
  },

  {
    path: '/system/monitoring',
    name: 'MonitoringDashboard',
    component: ComingSoonView,
    alias: ['/monitoring'],
    meta: { requiresAuth: true, title: 'Logging & Monitoring' },
  },

  {
    path: '/unauthorized',
    name: 'Unauthorized',
    component: UnauthorizedView,
    meta: { requiresAuth: true, publicLayout: false, title: 'Unauthorized' },
  },
  {
    path: '/admin',
    name: 'AdminOverview',
    component: AdminOverviewView,
    meta: { requiresAuth: true, requiresRole: 'admin', title: 'Admin Dashboard' },
  },
  {
    path: '/admin/users-management',
    name: 'AdminUsersManagement',
    component: AdminUsersManagementView,
    meta: {
      requiresAuth: true,
      requiresRole: 'admin',
      permissions: ['users.view'],
      title: 'Users Management',
    },
  },
  {
    path: '/admin/users',
    name: 'AdminUsers',
    component: AdminUsersView,
    meta: {
      requiresAuth: true,
      requiresRole: 'admin',
      permissions: ['users.view'],
      title: 'Admin Users',
    },
  },
  {
    path: '/admin/roles',
    name: 'AdminRoles',
    component: AdminRolesView,
    meta: {
      requiresAuth: true,
      requiresRole: 'admin',
      permissions: ['roles.manage'],
      title: 'Admin Roles',
    },
  },
  {
    path: '/admin/permissions',
    name: 'AdminPermissions',
    component: AdminRolesView,
    meta: {
      requiresAuth: true,
      requiresRole: 'admin',
      permissions: ['roles.manage'],
      title: 'Admin Permissions',
    },
  },
  {
    path: '/security',
    name: 'SecurityOverview',
    component: SecurityOverviewView,
    meta: { requiresAuth: true, permissions: ['security.view'], title: 'Security' },
  },
  {
    path: '/security/audit-logs',
    name: 'SecurityAuditLogs',
    component: SecurityAuditLogsView,
    meta: { requiresAuth: true, permissions: ['security.view'], title: 'Audit Logs' },
  },
  { path: '/security/roles', redirect: '/admin/roles' },
  { path: '/security/permissions', redirect: '/admin/permissions' },
  { path: '/security/login-history', redirect: '/security/audit-logs' },
  { path: '/user-management/users', redirect: '/admin/users-management' },
  { path: '/user-management/roles', redirect: '/admin/roles' },
  { path: '/admin/security', redirect: '/security' },

  {
    path: '/:pathMatch(.*)*',
    name: 'PageNotFound',
    component: ComingSoonView,
    meta: {
      title: 'Under Construction',
      requiresAuth: false
    }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior() {
    return { top: 0, behavior: 'smooth' }
  },
})

router.beforeEach((to, from, next) => {
  const publicPages = ['/login', '/register', '/forgot-password', '/reset-password']
  const token = getStoredToken()
  const user = getAuthUser?.()
  const isPublicPage = publicPages.includes(to.path)

  if (!token && !isPublicPage) {
    next({
      path: '/login',
      query: {
        redirect: to.fullPath,
      },
    })
    return
  }

  if (token && to.meta?.guestOnly) {
    next('/dashboard')
    return
  }

  if (token && to.meta?.requiresRole) {
    const roles = Array.isArray(user?.roles) ? user.roles : []

    if (!roles.includes(to.meta.requiresRole)) {
      next('/unauthorized')
      return
    }
  }

  if (token && Array.isArray(to.meta?.permissions) && to.meta.permissions.length > 0) {
    const permissions = Array.isArray(user?.permissions) ? user.permissions : []
    const hasPermission = to.meta.permissions.some((permission) => permissions.includes(permission))

    if (!hasPermission) {
      next('/unauthorized')
      return
    }
  }

  if (token && typeof canAccessRoute === 'function' && !canAccessRoute(to)) {
    next('/unauthorized')
    return
  }

  next()
})

router.afterEach((to) => {
  const title = to.meta?.title ? `${to.meta.title} | Nix Life OS` : 'Nix Life OS'
  document.title = title
})

router.onError((error) => {
  console.error('Router error:', error)

  const message = String(error?.message || '')

  if (
    message.includes('Failed to fetch dynamically imported module') ||
    message.includes('Importing a module script failed')
  ) {
    window.location.reload()
  }
})

export default router