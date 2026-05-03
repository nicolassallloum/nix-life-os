import { createRouter, createWebHistory } from "vue-router";
import { h } from "vue";

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

// Monitoring
import MonitoringDashboardView from "../views/monitoring/MonitoringDashboardView.vue";

/*
|--------------------------------------------------------------------------
| Unauthorized View
|--------------------------------------------------------------------------
*/
const UnauthorizedView = {
  name: "UnauthorizedView",
  setup() {
    return () =>
      h(
        "div",
        {
          class: "min-h-screen flex items-center justify-center bg-gray-50",
        },
        [
          h(
            "div",
            {
              class:
                "bg-white rounded-2xl shadow-sm border border-gray-200 p-8 max-w-md text-center",
            },
            [
              h(
                "h1",
                {
                  class: "text-2xl font-bold text-gray-900 mb-2",
                },
                "Access Denied"
              ),
              h(
                "p",
                {
                  class: "text-gray-500 mb-6",
                },
                "You do not have permission to access this page."
              ),
              h(
                "button",
                {
                  class:
                    "inline-block rounded-xl bg-gray-900 text-white px-5 py-3 hover:bg-gray-800",
                  onClick: () => {
                    window.location.href = "/monitoring";
                  },
                },
                "Go to Monitoring"
              ),
            ]
          ),
        ]
      );
  },
};

/*
|--------------------------------------------------------------------------
| Routes
|--------------------------------------------------------------------------
*/
const routes = [
  /*
  |--------------------------------------------------------------------------
  | Root
  |--------------------------------------------------------------------------
  */
  {
    path: "/",
    redirect: "/monitoring",
  },

  /*
  |--------------------------------------------------------------------------
  | Monitoring
  |--------------------------------------------------------------------------
  */
  {
    path: "/monitoring",
    name: "monitoring",
    component: MonitoringDashboardView,
    meta: {
      requiresAuth: true,
      skipPermission: true,
    },
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
      skipPermission: true,
    },
  },

  /*
  |--------------------------------------------------------------------------
  | Finance
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
  | Health
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
  | Projects
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
  | Notifications
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
  | Life Balance
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
  | Security
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
  | Unauthorized
  |--------------------------------------------------------------------------
  */
  {
    path: "/unauthorized",
    name: "unauthorized",
    component: UnauthorizedView,
  },

  /*
  |--------------------------------------------------------------------------
  | 404 Fallback
  |--------------------------------------------------------------------------
  */
  {
    path: "/:pathMatch(.*)*",
    redirect: "/monitoring",
  },
];

/*
|--------------------------------------------------------------------------
| Router Instance
|--------------------------------------------------------------------------
*/
const router = createRouter({
  history: createWebHistory(),
  routes,
});

/*
|--------------------------------------------------------------------------
| Global Route Guard - Testing Version
|--------------------------------------------------------------------------
| This version keeps token checking but disables frontend permission blocking.
| Backend APIs are still protected by Laravel/Sanctum.
|--------------------------------------------------------------------------
*/
router.beforeEach((to) => {
  const token =
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token");

  const publicPages = ["/unauthorized"];
  const isPublicPage = publicPages.includes(to.path);

  if (to.meta.requiresAuth && !token && !isPublicPage) {
    return {
      path: "/unauthorized",
    };
  }

  /*
  |--------------------------------------------------------------------------
  | Permission Check Disabled Temporarily
  |--------------------------------------------------------------------------
  | Reason:
  | - Allows all sidebar pages to open during web testing.
  | - Fixes the issue where only Monitoring and Dashboard worked.
  |--------------------------------------------------------------------------
  */

  return true;
});

export default router;