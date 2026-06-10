// @ts-nocheck
import { createRouter, createWebHistory } from 'vue-router'
import { canAccessRoute, getAuthToken, getAuthUser } from '@/utils/auth'
import api from '@/services/api'

import ApplicationDownView from '@/views/system/ApplicationDownView.vue'
import ComingSoonView from '@/views/system/ComingSoonView.vue'


const LabTestsView = () => import('@/views/health/LabTestsView.vue')
const LabTestUploadView = () => import('@/views/health/LabTestUploadView.vue')
const LabTestPreviewView = () => import('@/views/health/LabTestPreviewView.vue')

const LoginView = () => import('@/views/auth/LoginView.vue')
const RegisterView = () => import('@/views/auth/RegisterView.vue')
const UnauthorizedView = () => import('@/views/auth/UnauthorizedView.vue')
const HealthView = () => import('@/views/health/HealthView.vue')
const HealthAIInsightsView = () => import('@/views/health/HealthAIInsightsView.vue')
const StepsTrackingView = () => import('@/views/health/StepsTrackingView.vue')
const WeightTrackingView = () => import('@/views/health/WeightTrackingView.vue')
const NutritionTrackingView = () => import('@/views/health/NutritionTrackingView.vue')
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
const StepsView = () => import('@/views/health/StepsView.vue')
const DashboardView = () => import('@/views/dashboard/DashboardView.vue')
const UnifiedDashboardView = () => import('@/views/dashboard/UnifiedDashboardView.vue')
const LifeBalanceView = () => import('@/views/life-balance/LifeBalanceView.vue')
const AIRecommendationsView = () => import('@/views/ai/AIRecommendationsView.vue')
// const HealthView = () => import('@/views/health/HealthView.vue')
const FinanceDashboardView = () => import('@/views/finance/FinanceDashboardView.vue')
const FinanceAccountsView = () => import('@/views/finance/FinanceAccountsView.vue')
const FinanceTransactionsView = () => import('@/views/finance/FinanceTransactionsView.vue')
const FinanceBudgetsView = () => import('@/views/finance/FinanceBudgetsView.vue')
const FinanceAIInsightsView = () => import('@/views/finance/FinanceAIInsightsView.vue')
const ExpensesView = () => import('@/views/finance/ExpensesView.vue')

const ProjectsView = () => import('@/views/projects/ProjectsView.vue')
const ProjectGoalsView = () => import('@/views/projects/ProjectGoalsView.vue')
const ProjectTasksView = () => import('@/views/projects/ProjectTasksView.vue')
const ProjectDetailsView = () => import('@/views/projects/ProjectDetailsView.vue')
const ProjectDashboardView = () => import('@/views/projects/ProjectDashboardView.vue')
const ProductivityView = () => import('@/views/productivity/ProductivityView.vue')
const ProductivityDashboardView = () => import('@/views/productivity/ProductivityDashboardView.vue')
const ProductivityAIInsightsView = () => import('@/views/productivity/ProductivityAIInsightsView.vue')
const ProductivityTasksView = () => import('@/views/productivity/TasksView.vue')
const ProductivityHabitsView = () => import('@/views/productivity/HabitsView.vue')
const ProductivityGoalsView = () => import('@/views/productivity/ProductivityGoalsView.vue')
const ProductivityCalendarView = () => import('@/views/productivity/CalendarView.vue')
const HappyWinsView = () => import('@/views/productivity/HappyWinsView.vue')
const SettingsView = () => import('@/views/settings/SettingsView.vue')
const ProfileView = () => import('@/views/profile/ProfileView.vue')


const AdminOverviewView = () => import('@/views/admin/AdminOverviewView.vue')
const AdminUsersView = () => import('@/views/admin/AdminUsersView.vue')
const AdminUsersManagementView = () => import('@/views/admin/AdminUsersManagementView.vue')
const AdminRolesView = () => import('@/views/admin/AdminRolesView.vue')
const SecurityOverviewView = () => import('@/views/security/SecurityOverviewView.vue')
const SecurityAuditLogsView = () => import('@/views/security/SecurityAuditLogsView.vue')

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

  {
    path: '/health/lab-tests',
    name: 'health-lab-tests',
    component: LabTestsView,
  },
  {
    path: '/health/lab-tests/upload',
    name: 'health-lab-tests-upload',
    component: LabTestUploadView,
  },
  {
    path: '/health/lab-tests/:id/preview',
    name: 'health-lab-tests-preview',
    component: LabTestPreviewView,
  },

  {
    path: '/',
    redirect: '/dashboard',
  },

  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: {
      guestOnly: true,
      publicLayout: true,
      title: 'Login',
    },
  },
  {
    path: '/register',
    name: 'Register',
    component: RegisterView,
    meta: {
      guestOnly: true,
      publicLayout: true,
      title: 'Register',
    },
  },
  {
    path: '/finance/budgets/create',
    name: 'CreateBudget',
    component: () => import('@/views/finance/CreateBudgetView.vue'),
    meta: { requiresAuth: true }
  },

  {
    path: '/finance/categories/create',
    name: 'CreateFinanceCategory',
    component: () => import('@/views/finance/CreateCategoryView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/dashboard',
    name: 'AdminDashboard',
    component: () => import('@/views/admin/AdminDashboardView.vue'),
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/test-coming-soon',
    name: 'TestComingSoon',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Coming Soon Test',
    },
  },
  {
    path: '/application-down',
    name: 'ApplicationDown',
    component: ApplicationDownView,
    meta: {
      title: 'Application Temporarily Down',
      requiresAuth: false,
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Version 1 Available Pages
  |--------------------------------------------------------------------------
  */

  {
    path: '/dashboard',
    name: 'Dashboard',
    component: DashboardView,
    meta: {
      requiresAuth: true,
      title: 'Dashboard',
    },
  },
  {
    path: '/unified-dashboard',
    name: 'UnifiedDashboard',
    component: UnifiedDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Unified Dashboard',
    },
  },
  {
    path: '/life-balance',
    name: 'LifeBalance',
    component: LifeBalanceView,
    meta: {
      requiresAuth: true,
      title: 'Life Balance',
    },
  },

  {
    path: '/finance',
    redirect: '/finance/dashboard',
  },
  {
    path: '/finance/dashboard',
    name: 'FinanceDashboard',
    component: FinanceDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Finance Dashboard',
    },
  },
  {
    path: '/finance/ai-insights',
    name: 'FinanceAIInsights',
    component: FinanceAIInsightsView,
    meta: {
      requiresAuth: true,
      title: 'Finance AI Insights',
    },
  },
  {
    path: '/finance/accounts',
    name: 'FinanceAccounts',
    component: FinanceAccountsView,
    meta: {
      requiresAuth: true,
      title: 'Finance Accounts',
    },
  },
  {
    path: '/finance/transactions',
    name: 'FinanceTransactions',
    component: FinanceTransactionsView,
    meta: {
      requiresAuth: true,
      title: 'Finance Transactions',
    },
  },
  {
    path: '/finance/budgets',
    name: 'FinanceBudgets',
    component: FinanceBudgetsView,
    meta: {
      requiresAuth: true,
      title: 'Finance Budgets',
    },
  },
  {
    path: '/finance/expenses',
    name: 'FinanceExpenses',
    component: ExpensesView,
    meta: {
      requiresAuth: true,
      title: 'Finance Expenses',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Coming Soon Pages - Not Ready in Version 1
  |--------------------------------------------------------------------------
  */

  {
    path: '/ai',
    redirect: '/ai/recommendations',
  },
  {
    path: '/ai/recommendations',
    name: 'AIRecommendations',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'AI Recommendations - Coming Soon',
    },
  },

  {
    path: '/health',
    name: 'health',
    component: HealthView,
    meta: {
      requiresAuth: true,
      title: 'Health Dashboard'
    }
  },
  {
    path: '/health/ai-insights',
    name: 'health-ai-insights',
    component: HealthAIInsightsView,
    meta: {
      requiresAuth: true,
      title: 'Health AI Insights'
    }
  },
  {
    path: '/health/steps',
    name: 'health-steps',
    component: StepsTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Steps Tracking'
    }
  },
  {
    path: '/health/weight',
    name: 'health-weight',
    component: WeightTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Weight Tracking'
    }
  },
  {
    path: '/health/nutrition',
    name: 'health-nutrition',
    component: NutritionTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Nutrition Tracking'
    }
  },
  {
    path: '/health/nutrition/dashboard',
    name: 'health-nutrition-dashboard',
    component: NutritionDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Nutrition Dashboard'
    }
  },
  {
    path: '/health/nutrition/food-items',
    name: 'health-nutrition-food-items',
    component: FoodItemsView,
    meta: {
      requiresAuth: true,
      title: 'Food Items'
    }
  },
  {
    path: '/health/nutrition/meal-logger',
    name: 'health-nutrition-meal-logger',
    component: MealLoggerView,
    meta: {
      requiresAuth: true,
      title: 'Meal Logger'
    }
  },
  {
    path: '/health/custom-foods',
    name: 'health-custom-foods',
    component: CustomFoodsView,
    meta: {
      requiresAuth: true,
      title: 'Custom Foods'
    }
  },
  {
    path: '/health/hydration',
    name: 'health-hydration',
    component: () => import('@/views/health/HydrationView.vue'),
    meta: {
      requiresAuth: true,
      title: 'Hydration Tracking'
    }
  },
  {
    path: '/health/sleep',
    name: 'health-sleep',
    component: SleepTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Sleep Tracking'
    }
  },
  {
    path: '/health/medications',
    name: 'health-medications',
    component: MedicationTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Medication Tracking'
    }
  },
  {
    path: '/health/medicaments',
    name: 'health-medicaments',
    component: MedicamentsTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Medicaments Tracking'
    }
  },
  {
    path: '/projects',
    redirect: '/projects/list',
  },
  {
    path: '/projects/dashboard',
    name: 'ProjectsDashboard',
    component: ProjectDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Projects Dashboard',
    },
  },
  {
    path: '/projects/list',
    name: 'ProjectsList',
    component: ProjectsView,
    meta: {
      requiresAuth: true,
      title: 'Projects',
    },
  },
  {
    path: '/projects/tasks',
    name: 'ProjectTasks',
    component: ProjectTasksView,
    meta: {
      requiresAuth: true,
      title: 'Project Tasks',
    },
  },
  {
    path: '/projects/goals',
    name: 'ProjectGoals',
    component: ProjectGoalsView,
    meta: {
      requiresAuth: true,
      title: 'Project Goals',
    },
  },
  {
    path: '/projects/:id/tasks',
    name: 'ProjectTasksByProject',
    component: ProjectTasksView,
    meta: {
      requiresAuth: true,
      title: 'Project Tasks',
    },
  },
  {
    path: '/projects/:id/goals',
    name: 'ProjectGoalsByProject',
    component: ProjectGoalsView,
    meta: {
      requiresAuth: true,
      title: 'Project Goals',
    },
  },
  {
    path: '/projects/:id',
    name: 'ProjectDetails',
    component: ProjectDetailsView,
    meta: {
      requiresAuth: true,
      title: 'Project Details',
    },
  },
  {
    path: '/projects/milestones',
    name: 'ProjectMilestones',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Project Milestones - Coming Soon',
    },
  },
  {
    path: '/projects/progress',
    name: 'ProjectProgress',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Project Progress - Coming Soon',
    },
  },
  {
    path: '/projects/status-updates',
    name: 'ProjectStatusUpdates',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Status Updates - Coming Soon',
    },
  },

  {
    path: '/productivity',
    name: 'Productivity',
    component: ProductivityView,
    meta: {
      requiresAuth: true,
      title: 'Productivity',
    },
  },
  {
    path: '/productivity/dashboard',
    name: 'ProductivityDashboard',
    component: ProductivityDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Productivity Dashboard',
    },
  },
  {
    path: '/productivity/ai-insights',
    name: 'ProductivityAIInsights',
    component: ProductivityAIInsightsView,
    meta: {
      requiresAuth: true,
      title: 'Productivity AI Insights',
    },
  },
  {
    path: '/productivity/tasks',
    name: 'ProductivityTasks',
    component: ProductivityTasksView,
    alias: ['/tasks'],
    meta: {
      requiresAuth: true,
      title: 'Productivity Tasks',
    },
  },
  {
    path: '/productivity/habits',
    name: 'ProductivityHabits',
    component: ProductivityHabitsView,
    meta: {
      requiresAuth: true,
      title: 'Productivity Habits',
    },
  },
  {
    path: '/productivity/goals',
    name: 'ProductivityGoals',
    component: ProductivityGoalsView,
    meta: {
      requiresAuth: true,
      title: 'Productivity Goals',
    },
  },
  {
    path: '/productivity/happy-wins',
    name: 'ProductivityHappyWins',
    component: HappyWinsView,
    meta: {
      requiresAuth: true,
      title: 'Happy Wins',
    },
  },

  {
    path: '/productivity/calendar',
    name: 'ProductivityCalendar',
    component: ProductivityCalendarView,
    alias: ['/calendar', '/schedule', '/productivity/schedule'],
    meta: {
      requiresAuth: true,
      title: 'Productivity Calendar',
    },
  },

  {
    path: '/settings',
    name: 'Settings',
    component: SettingsView,
    meta: {
      requiresAuth: true,
      title: 'Settings',
    },
  },
  {
    path: '/profile',
    name: 'Profile',
    component: ProfileView,
    meta: {
      requiresAuth: true,
      title: 'Profile',
    },
  },

  {
    path: '/notifications',
    name: 'Notifications',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Notifications - Coming Soon',
    },
  },
  {
    path: '/notifications/settings',
    name: 'NotificationSettings',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Notification Settings - Coming Soon',
    },
  },

  {
    path: '/offline/sync-center',
    name: 'OfflineSyncCenter',
    component: ComingSoonView,
    meta: {
      requiresAuth: true,
      title: 'Offline Sync Center - Coming Soon',
    },
  },

  {
    path: '/system/monitoring',
    name: 'MonitoringDashboard',
    component: ComingSoonView,
    alias: ['/monitoring'],
    meta: {
      requiresAuth: true,
      title: 'Logging & Monitoring - Coming Soon',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Admin / Security Pages
  |--------------------------------------------------------------------------
  */

  {
    path: '/unauthorized',
    name: 'Unauthorized',
    component: UnauthorizedView,
    meta: {
      requiresAuth: true,
      publicLayout: false,
      title: 'Unauthorized',
    },
  },
  {
    path: '/admin',
    name: 'AdminOverview',
    component: AdminOverviewView,
    meta: {
      requiresAuth: true,
      requiresRole: 'admin',
      title: 'Admin Dashboard',
    },
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
    meta: {
      requiresAuth: true,
      permissions: ['security.view'],
      title: 'Security',
    },
  },
  {
    path: '/security/audit-logs',
    name: 'SecurityAuditLogs',
    component: SecurityAuditLogsView,
    meta: {
      requiresAuth: true,
      permissions: ['security.view'],
      title: 'Audit Logs',
    },
  },

  {
    path: '/security/roles',
    redirect: '/admin/roles',
  },
  {
    path: '/security/permissions',
    redirect: '/admin/permissions',
  },
  {
    path: '/security/login-history',
    redirect: '/security/audit-logs',
  },
  {
    path: '/user-management/users',
    redirect: '/admin/users-management',
  },
  {
    path: '/user-management/roles',
    redirect: '/admin/roles',
  },
  {
    path: '/admin/security',
    redirect: '/security',
  },

  /*
  |--------------------------------------------------------------------------
  | Final 404 Route
  |--------------------------------------------------------------------------
  */

  {
    path: '/:pathMatch(.*)*',
    name: 'PageNotFound',
    component: ComingSoonView,
    meta: {
      title: 'Page Not Available',
      requiresAuth: false,
    },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior() {
    return {
      top: 0,
      behavior: 'smooth',
    }
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

  if (token && to.meta?.requiresAdmin) {
    const email = String(user?.email || '').toLowerCase()

    if (email !== 'admin@nixlifeos.com') {
      next('/unauthorized')
      return
    }
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

  if (getStoredToken() && !to.meta?.publicLayout) {
    api.post('/track-visit', {
      page_url: window.location.href,
      page_name: String(to.name || to.path),
      referrer: document.referrer || null,
    }).catch(() => {})
  }
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
