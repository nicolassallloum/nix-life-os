import { createRouter, createWebHistory } from "vue-router";
import { hasPermission } from "@/utils/permissions";

// Dashboard
import UnifiedDashboardView from "@/views/dashboard/UnifiedDashboardView.vue";

// Finance
import FinanceDashboardView from "../views/finance/FinanceDashboardView.vue";
import FinanceAccountsView from "../views/finance/FinanceAccountsView.vue";
import FinanceTransactionsView from "../views/finance/FinanceTransactionsView.vue";
import FinanceBudgetsView from "../views/finance/FinanceBudgetsView.vue";

// Health
import HealthStepsView from "../views/health/HealthStepsView.vue";
import HealthWeightView from "../views/health/HealthWeightView.vue";
import HealthNutritionView from "../views/health/HealthNutritionView.vue";
import HealthHydrationView from "../views/HealthHydrationView.vue";

// Projects
import ProjectDashboardView from "../views/projects/ProjectDashboardView.vue";
import ProjectTasksView from "../views/ProjectTasksView.vue";
import ProjectMilestonesView from "../views/ProjectMilestonesView.vue";
import ProjectProgressView from "../views/ProjectProgressView.vue";
import ProjectStatusUpdatesView from "../views/ProjectStatusUpdatesView.vue";

// Notifications
import NotificationsView from "../views/notifications/NotificationsView.vue";
import NotificationSettingsView from "../views/notifications/NotificationSettingsView.vue";

// Life Balance
import LifeBalanceView from "../views/life-balance/LifeBalanceView.vue";

// Security
import SecurityRolesView from "../views/SecurityRolesView.vue";

const routes = [
  {
    path: "/",
    redirect: "/dashboard",
  },

  /*
  |--------------------------------------------------------------------------
  | Unified Dashboard
  |--------------------------------------------------------------------------
  */
  {
    path: "/dashboard",
    name: "unified-dashboard",
    component: UnifiedDashboardView,
    meta: {
      requiresAuth: true,
      permission: "dashboard.view",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Finance Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/finance",
    name: "finance-dashboard",
    component: FinanceDashboardView,
    meta: {
      requiresAuth: true,
      permission: "finance.view",
    },
  },
  {
    path: "/finance/accounts",
    name: "finance-accounts",
    component: FinanceAccountsView,
    meta: {
      requiresAuth: true,
      permission: "finance.view",
    },
  },
  {
    path: "/finance/transactions",
    name: "finance-transactions",
    component: FinanceTransactionsView,
    meta: {
      requiresAuth: true,
      permission: "finance.view",
    },
  },
  {
    path: "/finance/budgets",
    name: "finance-budgets",
    component: FinanceBudgetsView,
    meta: {
      requiresAuth: true,
      permission: "finance.view",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Health Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/health/steps",
    name: "health-steps",
    component: HealthStepsView,
    meta: {
      requiresAuth: true,
      permission: "health.view",
    },
  },
  {
    path: "/health/weight",
    name: "health-weight",
    component: HealthWeightView,
    meta: {
      requiresAuth: true,
      permission: "health.view",
    },
  },
  {
    path: "/health/nutrition",
    name: "health-nutrition",
    component: HealthNutritionView,
    meta: {
      requiresAuth: true,
      permission: "health.view",
    },
  },
  {
    path: "/health/hydration",
    name: "health-hydration",
    component: HealthHydrationView,
    meta: {
      requiresAuth: true,
      permission: "health.view",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Project Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/projects",
    name: "projects-dashboard",
    component: ProjectDashboardView,
    meta: {
      requiresAuth: true,
      permission: "projects.view",
    },
  },
  {
    path: "/projects/tasks",
    name: "project-tasks",
    component: ProjectTasksView,
    meta: {
      requiresAuth: true,
      permission: "projects.view",
    },
  },
  {
    path: "/projects/milestones",
    name: "project-milestones",
    component: ProjectMilestonesView,
    meta: {
      requiresAuth: true,
      permission: "projects.view",
    },
  },
  {
    path: "/projects/progress",
    name: "project-progress",
    component: ProjectProgressView,
    meta: {
      requiresAuth: true,
      permission: "projects.view",
    },
  },
  {
    path: "/projects/status-updates",
    name: "project-status-updates",
    component: ProjectStatusUpdatesView,
    meta: {
      requiresAuth: true,
      permission: "projects.view",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Notifications Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/notifications",
    name: "notifications",
    component: NotificationsView,
    meta: {
      requiresAuth: true,
      permission: "notifications.view",
    },
  },
  {
    path: "/notifications/settings",
    name: "notification-settings",
    component: NotificationSettingsView,
    meta: {
      requiresAuth: true,
      permission: "notifications.manage",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Life Balance Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/life-balance",
    name: "life-balance",
    component: LifeBalanceView,
    meta: {
      requiresAuth: true,
      permission: "dashboard.view",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Security Routes
  |--------------------------------------------------------------------------
  */
  {
    path: "/security/roles",
    name: "security-roles",
    component: SecurityRolesView,
    meta: {
      requiresAuth: true,
      permission: "security.manage",
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Unauthorized Fallback
  |--------------------------------------------------------------------------
  */
  {
    path: "/unauthorized",
    name: "unauthorized",
    component: {
      template: `
        <div class="min-h-screen flex items-center justify-center bg-gray-50">
          <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 max-w-md text-center">
            <h1 class="text-2xl font-bold text-gray-900 mb-2">
              Access Denied
            </h1>
            <p class="text-gray-500 mb-6">
              You do not have permission to access this page.
            </p>
            <RouterLink
              to="/dashboard"
              class="inline-block rounded-xl bg-gray-900 text-white px-5 py-3 hover:bg-gray-800"
            >
              Go to Dashboard
            </RouterLink>
          </div>
        </div>
      `,
    },
  },

  /*
  |--------------------------------------------------------------------------
  | 404 Fallback
  |--------------------------------------------------------------------------
  */
  {
    path: "/:pathMatch(.*)*",
    redirect: "/dashboard",
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

/*
|--------------------------------------------------------------------------
| Global Route Guard
|--------------------------------------------------------------------------
| Checks:
| 1. User must have token for protected routes.
| 2. User must have required permission.
|--------------------------------------------------------------------------
*/
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem("token");

  if (to.meta.requiresAuth && !token) {
    return next("/dashboard");
  }

  if (to.meta.permission && !hasPermission(to.meta.permission)) {
    return next("/unauthorized");
  }

  return next();
});

export default router;permissions.js