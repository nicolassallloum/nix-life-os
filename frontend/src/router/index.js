import { createRouter, createWebHistory } from "vue-router";

/*
|--------------------------------------------------------------------------
| Auth Views
|--------------------------------------------------------------------------
*/

const LoginView = () => import("../views/auth/LoginView.vue");
const RegisterView = () => import("../views/auth/RegisterView.vue");

/*
|--------------------------------------------------------------------------
| Dashboard Views
|--------------------------------------------------------------------------
*/

const UnifiedDashboardView = () => import("../views/dashboard/UnifiedDashboardView.vue");
const DashboardView = () => import("../views/dashboard/DashboardView.vue");
const LifeBalanceView = () => import("../views/LifeBalanceView.vue");

/*
|--------------------------------------------------------------------------
| Finance Views
|--------------------------------------------------------------------------
*/

const FinanceDashboardView = () => import("../views/finance/FinanceDashboardView.vue");
const FinanceAccountsView = () => import("../views/finance/FinanceAccountsView.vue");
const FinanceTransactionsView = () => import("../views/finance/FinanceTransactionsView.vue");
const FinanceBudgetsView = () => import("../views/finance/FinanceBudgetsView.vue");

/*
|--------------------------------------------------------------------------
| Health Views
|--------------------------------------------------------------------------
*/

const StepsTrackingView = () => import("../views/health/StepsTrackingView.vue");
const WeightTrackingView = () => import("../views/health/WeightTrackingView.vue");
const NutritionTrackingView = () => import("../views/health/NutritionTrackingView.vue");
const HydrationTrackingView = () => import("../views/health/HydrationTrackingView.vue");
const SleepTrackingView = () => import("../views/health/SleepTrackingView.vue");

/*
|--------------------------------------------------------------------------
| Project Views
|--------------------------------------------------------------------------
*/

const ProjectsDashboardView = () => import("../views/ProjectsDashboardView.vue");
const ProjectTasksView = () => import("../views/ProjectTasksView.vue");
const ProjectMilestonesView = () => import("../views/ProjectMilestonesView.vue");
const ProjectProgressView = () => import("../views/ProjectProgressView.vue");
const StatusUpdatesView = () => import("../views/ProjectStatusUpdatesView.vue");

/*
|--------------------------------------------------------------------------
| Notification Views
|--------------------------------------------------------------------------
*/

const NotificationsView = () => import("../views/notifications/NotificationsView.vue");
const NotificationSettingsView = () => import("../views/notifications/NotificationSettingsView.vue");

/*
|--------------------------------------------------------------------------
| System Views
|--------------------------------------------------------------------------
*/

const MonitoringDashboardView = () => import("../views/monitoring/MonitoringDashboardView.vue");

/*
|--------------------------------------------------------------------------
| Fallback Views
|--------------------------------------------------------------------------
*/

const NotFoundView = () => import("../views/NotFoundView.vue");

const routes = [
  {
    path: "/",
    redirect: "/dashboard",
  },

  /*
  |--------------------------------------------------------------------------
  | Auth Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/login",
    name: "Login",
    component: LoginView,
    meta: {
      guestOnly: true,
      title: "Login",
    },
  },
  {
    path: "/register",
    name: "Register",
    component: RegisterView,
    meta: {
      guestOnly: true,
      title: "Register",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Main Dashboards
  |--------------------------------------------------------------------------
  */

  {
    path: "/dashboard",
    name: "Dashboard",
    component: DashboardView,
    meta: {
      requiresAuth: true,
      title: "Dashboard",
    },
  },
  {
    path: "/unified-dashboard",
    name: "UnifiedDashboard",
    component: UnifiedDashboardView,
    meta: {
      requiresAuth: true,
      title: "Unified Dashboard",
    },
  },
  {
    path: "/life-balance",
    name: "LifeBalance",
    component: LifeBalanceView,
    meta: {
      requiresAuth: true,
      title: "Life Balance",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Finance Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/finance",
    redirect: "/finance/dashboard",
  },
  {
    path: "/finance/dashboard",
    name: "FinanceDashboard",
    component: FinanceDashboardView,
    meta: {
      requiresAuth: true,
      title: "Finance Dashboard",
    },
  },
  {
    path: "/finance/accounts",
    name: "FinanceAccounts",
    component: FinanceAccountsView,
    meta: {
      requiresAuth: true,
      title: "Finance Accounts",
    },
  },
  {
    path: "/finance/transactions",
    name: "FinanceTransactions",
    component: FinanceTransactionsView,
    meta: {
      requiresAuth: true,
      title: "Finance Transactions",
    },
  },
  {
    path: "/finance/budgets",
    name: "FinanceBudgets",
    component: FinanceBudgetsView,
    meta: {
      requiresAuth: true,
      title: "Finance Budgets",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Health Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/health",
    redirect: "/health/steps",
  },
  {
    path: "/health/steps",
    name: "StepsTracking",
    component: StepsTrackingView,
    meta: {
      requiresAuth: true,
      title: "Steps Tracking",
    },
  },
  {
    path: "/health/weight",
    name: "WeightTracking",
    component: WeightTrackingView,
    meta: {
      requiresAuth: true,
      title: "Weight Tracking",
    },
  },
  {
    path: "/health/nutrition",
    name: "NutritionTracking",
    component: NutritionTrackingView,
    meta: {
      requiresAuth: true,
      title: "Nutrition Tracking",
    },
  },
  {
    path: "/health/hydration",
    name: "HydrationTracking",
    component: HydrationTrackingView,
    meta: {
      requiresAuth: true,
      title: "Hydration Tracking",
    },
  },
  {
    path: "/health/sleep",
    name: "SleepTracking",
    component: SleepTrackingView,
    meta: {
      requiresAuth: true,
      title: "Sleep Tracking",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Project Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/projects",
    redirect: "/projects/dashboard",
  },
  {
    path: "/projects/dashboard",
    name: "ProjectsDashboard",
    component: ProjectsDashboardView,
    meta: {
      requiresAuth: true,
      title: "Projects Dashboard",
    },
  },
  {
    path: "/projects/tasks",
    name: "ProjectTasks",
    component: ProjectTasksView,
    meta: {
      requiresAuth: true,
      title: "Project Tasks",
    },
  },
  {
    path: "/projects/milestones",
    name: "ProjectMilestones",
    component: ProjectMilestonesView,
    meta: {
      requiresAuth: true,
      title: "Project Milestones",
    },
  },
  {
    path: "/projects/progress",
    name: "ProjectProgress",
    component: ProjectProgressView,
    meta: {
      requiresAuth: true,
      title: "Project Progress",
    },
  },
  {
    path: "/projects/status-updates",
    name: "StatusUpdates",
    component: StatusUpdatesView,
    meta: {
      requiresAuth: true,
      title: "Status Updates",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Notification Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/notifications",
    name: "Notifications",
    component: NotificationsView,
    meta: {
      requiresAuth: true,
      title: "Notifications",
    },
  },
  {
    path: "/notifications/settings",
    name: "NotificationSettings",
    component: NotificationSettingsView,
    meta: {
      requiresAuth: true,
      title: "Notification Settings",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | System Routes
  |--------------------------------------------------------------------------
  */

  {
    path: "/system/monitoring",
    name: "MonitoringDashboard",
    component: MonitoringDashboardView,
    meta: {
      requiresAuth: true,
      title: "Logging & Monitoring",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | 404 Route
  |--------------------------------------------------------------------------
  */

  {
    path: "/:pathMatch(.*)*",
    name: "NotFound",
    component: NotFoundView,
    meta: {
      title: "Page Not Found",
    },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return {
      top: 0,
      behavior: "smooth",
    };
  },
});

/*
|--------------------------------------------------------------------------
| Router Guard
|--------------------------------------------------------------------------
*/

router.beforeEach((to, from, next) => {
  const token =
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token");

  const isAuthenticated = Boolean(token);

  if (to.meta?.requiresAuth && !isAuthenticated) {
    return next({
      path: "/login",
      query: {
        redirect: to.fullPath,
      },
    });
  }

  if (to.meta?.guestOnly && isAuthenticated) {
    return next("/dashboard");
  }

  if (to.meta?.title) {
    document.title = `${to.meta.title} | Nix Life OS`;
  } else {
    document.title = "Nix Life OS";
  }

  return next();
});

export default router;