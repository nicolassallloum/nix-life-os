import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

/*
|--------------------------------------------------------------------------
| Auth Views
|--------------------------------------------------------------------------
*/

const LoginView = () => import('../views/auth/LoginView.vue')
const RegisterView = () => import('../views/auth/RegisterView.vue')

/*
|--------------------------------------------------------------------------
| Dashboard Views
|--------------------------------------------------------------------------
*/

const UnifiedDashboardView = () => import('../views/dashboard/UnifiedDashboardView.vue')
const DashboardView = () => import('../views/dashboard/DashboardView.vue')
const LifeBalanceView = () => import('../views/life-balance/LifeBalanceView.vue')

/*
|--------------------------------------------------------------------------
| AI Views
|--------------------------------------------------------------------------
*/

const AIRecommendationsView = () => import('@/views/ai/AIRecommendationsView.vue')

/*
|--------------------------------------------------------------------------
| Productivity Views
|--------------------------------------------------------------------------
*/

const ProductivityDashboardView = () =>
  import('../views/productivity/ProductivityDashboardView.vue')

const TasksView = () => import('../views/productivity/TasksView.vue')
const GoalsView = () => import('../views/productivity/GoalsView.vue')
const HabitsView = () => import('../views/productivity/HabitsView.vue')
const CalendarView = () => import('../views/productivity/CalendarView.vue')
const ProductivityAIInsightsView = () =>
  import('../views/productivity/ProductivityAIInsightsView.vue')

/*
|--------------------------------------------------------------------------
| Finance Views
|--------------------------------------------------------------------------
*/

const FinanceDashboardView = () => import('../views/finance/FinanceDashboardView.vue')
const FinanceAccountsView = () => import('../views/finance/FinanceAccountsView.vue')
const FinanceTransactionsView = () => import('../views/finance/FinanceTransactionsView.vue')
const FinanceBudgetsView = () => import('../views/finance/FinanceBudgetsView.vue')
const FinanceAIInsightsView = () => import('../views/finance/FinanceAIInsightsView.vue')
/*
|--------------------------------------------------------------------------
| Health Views
|--------------------------------------------------------------------------
*/

const HealthView = () => import('@/views/health/HealthView.vue')
const StepsTrackingView = () => import('../views/health/StepsTrackingView.vue')
const WeightTrackingView = () => import('../views/health/WeightTrackingView.vue')
const NutritionTrackingView = () => import('../views/health/NutritionTrackingView.vue')
const HydrationTrackingView = () => import('../views/health/HydrationTrackingView.vue')
const HealthAlertsView = () => import('@/views/health/HealthAlertsView.vue')
const HealthReportsView = () => import('@/views/health/HealthReportsView.vue')

/*
|--------------------------------------------------------------------------
| Project Views
|--------------------------------------------------------------------------
*/

const ProjectsDashboardView = () => import('../views/projects/ProjectDashboardView.vue')
const ProjectsView = () => import('../views/projects/ProjectsView.vue')
const ProjectTasksView = () => import('../views/ProjectTasksView.vue')
const ProjectMilestonesView = () => import('../views/ProjectMilestonesView.vue')
const ProjectProgressView = () => import('../views/ProjectProgressView.vue')
const StatusUpdatesView = () => import('../views/ProjectStatusUpdatesView.vue')

/*
|--------------------------------------------------------------------------
| Notification Views
|--------------------------------------------------------------------------
*/

const NotificationsView = () => import('../views/notifications/NotificationsView.vue')
const NotificationSettingsView = () => import('../views/notifications/NotificationSettingsView.vue')

/*
|--------------------------------------------------------------------------
| System Views
|--------------------------------------------------------------------------
*/

const MonitoringDashboardView = () => import('../views/monitoring/MonitoringDashboardView.vue')

/*
|--------------------------------------------------------------------------
| Fallback Views
|--------------------------------------------------------------------------
*/

const NotFoundView = () => import('../views/NotFoundView.vue')

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/dashboard',
  },

  /*
  |--------------------------------------------------------------------------
  | Auth Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: {
      guestOnly: true,
      title: 'Login',
    },
  },
  {
    path: '/register',
    name: 'Register',
    component: RegisterView,
    meta: {
      guestOnly: true,
      title: 'Register',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Main Dashboards
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

  /*
  |--------------------------------------------------------------------------
  | AI Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/ai',
    redirect: '/ai/recommendations',
  },
  {
    path: '/ai/recommendations',
    name: 'AIRecommendations',
    component: AIRecommendationsView,
    meta: {
      requiresAuth: true,
      title: 'AI Recommendations',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Productivity Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/productivity',
    redirect: '/productivity/dashboard',
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
    path: '/productivity/tasks',
    name: 'Tasks',
    component: TasksView,
    meta: {
      requiresAuth: true,
      title: 'Tasks',
    },
  },
  {
    path: '/tasks',
    redirect: '/productivity/tasks',
  },
  {
    path: '/productivity/goals',
    name: 'Goals',
    component: GoalsView,
    meta: {
      requiresAuth: true,
      title: 'Goals',
    },
  },
  {
    path: '/productivity/habits',
    name: 'Habits',
    component: HabitsView,
    meta: {
      requiresAuth: true,
      title: 'Habits',
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
    path: '/productivity/calendar',
    name: 'ProductivityCalendar',
    component: CalendarView,
    alias: ['/calendar', '/schedule', '/productivity/schedule'],
    meta: {
      requiresAuth: true,
      title: 'Calendar / Schedule',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Finance Routes
  |--------------------------------------------------------------------------
  */

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

  /*
  |--------------------------------------------------------------------------
  | Health Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/health',
    name: 'HealthDashboard',
    component: HealthView,
    meta: {
      requiresAuth: true,
      title: 'Health Dashboard',
    },
  },
  {
    path: '/health/steps',
    name: 'StepsTracking',
    component: StepsTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Steps Tracking',
    },
  },
  {
    path: '/health/weight',
    name: 'WeightTracking',
    component: WeightTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Weight Tracking',
    },
  },
  {
    path: '/health/nutrition',
    name: 'NutritionTracking',
    component: NutritionTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Nutrition Tracking',
    },
  },
  {
    path: '/health/custom-foods',
    name: 'HealthCustomFoods',
    component: () => import('@/views/health/CustomFoodsView.vue'),
    meta: {
      requiresAuth: true,
      title: 'Custom Foods',
    },
  },
  {
    path: '/health/hydration',
    name: 'HydrationTracking',
    component: HydrationTrackingView,
    meta: {
      requiresAuth: true,
      title: 'Hydration Tracking',
    },
  },
  {
    path: '/health/medications',
    name: 'HealthMedications',
    component: () => import('@/views/health/MedicationTrackingView.vue'),
    meta: {
      requiresAuth: true,
      title: 'Medication Tracking',
    },
  },
  {
    path: '/health/medicaments',
    name: 'MedicamentsTracking',
    component: () => import('@/views/health/MedicamentsTrackingView.vue'),
    meta: {
      requiresAuth: true,
      title: 'Medicaments',
    },
  },
  {
    path: '/health/lab-tests',
    name: 'LabTestsTracking',
    component: () => import('@/views/health/LabTestsTrackingView.vue'),
    meta: {
      requiresAuth: true,
      title: 'Lab Tests',
    },
  },
  {
    path: '/health/alerts',
    name: 'HealthAlerts',
    component: HealthAlertsView,
    meta: {
      requiresAuth: true,
      title: 'Health Alerts',
    },
  },
  {
    path: '/health/reports',
    name: 'HealthReports',
    component: HealthReportsView,
    meta: {
      requiresAuth: true,
      title: 'Health Reports',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Project Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/projects',
    redirect: '/projects/list',
  },
  {
    path: '/projects/list',
    name: 'ProjectsList',
    component: ProjectsView,
    meta: {
      requiresAuth: true,
      title: 'Project List',
    },
  },
  {
    path: '/projects/dashboard',
    name: 'ProjectsDashboard',
    component: ProjectsDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Projects Dashboard',
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
    path: '/projects/milestones',
    name: 'ProjectMilestones',
    component: ProjectMilestonesView,
    meta: {
      requiresAuth: true,
      title: 'Project Milestones',
    },
  },
  {
    path: '/projects/progress',
    name: 'ProjectProgress',
    component: ProjectProgressView,
    meta: {
      requiresAuth: true,
      title: 'Project Progress',
    },
  },
  {
    path: '/projects/status-updates',
    name: 'StatusUpdates',
    component: StatusUpdatesView,
    meta: {
      requiresAuth: true,
      title: 'Status Updates',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Notification Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/notifications',
    name: 'Notifications',
    component: NotificationsView,
    meta: {
      requiresAuth: true,
      title: 'Notifications',
    },
  },
  {
    path: '/notifications/settings',
    name: 'NotificationSettings',
    component: NotificationSettingsView,
    meta: {
      requiresAuth: true,
      title: 'Notification Settings',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | System Routes
  |--------------------------------------------------------------------------
  */

  {
    path: '/system/monitoring',
    name: 'MonitoringDashboard',
    component: MonitoringDashboardView,
    meta: {
      requiresAuth: true,
      title: 'Logging & Monitoring',
    },
  },

  /*
  |--------------------------------------------------------------------------
  | 404 Route
  |--------------------------------------------------------------------------
  */

  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: NotFoundView,
    meta: {
      title: 'Page Not Found',
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

router.beforeEach((to, _from, next) => {
  const token =
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token')

  const isAuthenticated = Boolean(token)

  if (to.meta?.requiresAuth && !isAuthenticated) {
    return next({
      path: '/login',
      query: {
        redirect: to.fullPath,
      },
    })
  }

  if (to.meta?.guestOnly && isAuthenticated) {
    return next('/dashboard')
  }

  if (to.meta?.title) {
    document.title = `${String(to.meta.title)} | Nix Life OS`
  } else {
    document.title = 'Nix Life OS'
  }

  return next()
})

export default router