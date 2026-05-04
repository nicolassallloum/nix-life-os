import { createRouter, createWebHistory } from "vue-router";

const viewModules = import.meta.glob("../views/**/*.vue");

const MissingView = {
  template: `
    <div class="p-8">
      <div class="bg-white border border-red-200 rounded-2xl shadow-sm p-6">
        <h1 class="text-2xl font-bold text-red-700 mb-2">View File Not Found</h1>
        <p class="text-gray-700 mb-4">
          This route is registered, but the Vue view file was not found.
        </p>
        <p class="text-sm text-gray-500">
          Check src/router/index.js and src/views folder names.
        </p>
      </div>
    </div>
  `,
};

function loadView(candidates) {
  for (const path of candidates) {
    if (viewModules[path]) {
      return viewModules[path];
    }
  }

  return MissingView;
}

const LoginView = loadView([
  "../views/auth/LoginView.vue",
  "../views/LoginView.vue",
  "../views/Auth/LoginView.vue",
]);

const RegisterView = loadView([
  "../views/auth/RegisterView.vue",
  "../views/RegisterView.vue",
  "../views/Auth/RegisterView.vue",
]);

const UnifiedDashboardView = loadView([
  "../views/UnifiedDashboardView.vue",
  "../views/dashboard/UnifiedDashboardView.vue",
  "../views/DashboardView.vue",
  "../views/Dashboard.vue",
  "../views/UnifiedDashboard.vue",
]);

const LifeBalanceView = loadView([
  "../views/LifeBalanceView.vue",
  "../views/life/LifeBalanceView.vue",
  "../views/LifeBalance.vue",
]);

const FinanceDashboardView = loadView([
  "../views/finance/FinanceDashboardView.vue",
  "../views/finance/FinanceDashboard.vue",
  "../views/FinanceDashboardView.vue",
  "../views/FinanceDashboard.vue",
]);

const FinanceAccountsView = loadView([
  "../views/finance/FinanceAccountsView.vue",
  "../views/finance/FinanceAccounts.vue",
  "../views/FinanceAccountsView.vue",
  "../views/FinanceAccounts.vue",
]);

const FinanceTransactionsView = loadView([
  "../views/finance/FinanceTransactionsView.vue",
  "../views/finance/FinanceTransactions.vue",
  "../views/FinanceTransactionsView.vue",
  "../views/FinanceTransactions.vue",
]);

const FinanceBudgetsView = loadView([
  "../views/finance/FinanceBudgetsView.vue",
  "../views/finance/FinanceBudgets.vue",
  "../views/FinanceBudgetsView.vue",
  "../views/FinanceBudgets.vue",
]);

const StepsTrackingView = loadView([
  "../views/health/StepsTrackingView.vue",
  "../views/health/HealthStepsView.vue",
  "../views/health/HealthStepLogsView.vue",
  "../views/HealthStepsView.vue",
]);

const WeightTrackingView = loadView([
  "../views/health/WeightTrackingView.vue",
  "../views/health/HealthWeightView.vue",
  "../views/health/HealthWeightLogsView.vue",
  "../views/HealthWeightView.vue",
]);

const NutritionTrackingView = loadView([
  "../views/health/NutritionTrackingView.vue",
  "../views/health/HealthNutritionView.vue",
  "../views/health/HealthMealView.vue",
  "../views/HealthNutritionView.vue",
]);

const HydrationTrackingView = loadView([
  "../views/health/HydrationTrackingView.vue",
  "../views/health/HealthHydrationView.vue",
  "../views/health/HealthHydrationLogsView.vue",
  "../views/HealthHydrationView.vue",
]);

const ProjectsDashboardView = loadView([
  "../views/projects/ProjectsDashboardView.vue",
  "../views/projects/ProjectDashboardView.vue",
  "../views/projects/ProjectsDashboard.vue",
  "../views/ProjectsDashboardView.vue",
]);

const ProjectsTasksView = loadView([
  "../views/projects/ProjectsTasksView.vue",
  "../views/projects/ProjectTasksView.vue",
  "../views/projects/ProjectTasks.vue",
  "../views/ProjectsTasksView.vue",
]);

const ProjectsMilestonesView = loadView([
  "../views/projects/ProjectsMilestonesView.vue",
  "../views/projects/ProjectMilestonesView.vue",
  "../views/projects/ProjectMilestones.vue",
  "../views/ProjectsMilestonesView.vue",
]);

const ProjectsProgressView = loadView([
  "../views/projects/ProjectsProgressView.vue",
  "../views/projects/ProjectProgressView.vue",
  "../views/projects/ProjectProgress.vue",
  "../views/ProjectsProgressView.vue",
]);

const StatusUpdatesView = loadView([
  "../views/projects/StatusUpdatesView.vue",
  "../views/projects/ProjectStatusUpdatesView.vue",
  "../views/StatusUpdatesView.vue",
]);

const NotificationsView = loadView([
  "../views/notifications/NotificationsView.vue",
  "../views/notifications/Notifications.vue",
  "../views/NotificationsView.vue",
]);

const NotificationSettingsView = loadView([
  "../views/notifications/NotificationSettingsView.vue",
  "../views/notifications/NotificationsSettingsView.vue",
  "../views/NotificationSettingsView.vue",
]);

const MonitoringDashboardView = loadView([
  "../views/monitoring/MonitoringDashboardView.vue",
  "../views/monitoring/LoggingMonitoringView.vue",
  "../views/MonitoringDashboardView.vue",
  "../views/LoggingMonitoringView.vue",
]);

const routes = [
  {
    path: "/login",
    name: "login",
    component: LoginView,
    meta: {
      public: true,
      title: "Login",
    },
  },
  {
    path: "/register",
    name: "register",
    component: RegisterView,
    meta: {
      public: true,
      title: "Register",
    },
  },

  {
    path: "/",
    name: "unified-dashboard",
    component: UnifiedDashboardView,
    meta: {
      requiresAuth: true,
      title: "Unified Dashboard",
    },
  },
  {
    path: "/life-balance",
    name: "life-balance",
    component: LifeBalanceView,
    meta: {
      requiresAuth: true,
      title: "Life Balance",
    },
  },

  {
    path: "/finance",
    redirect: "/finance/dashboard",
  },
  {
    path: "/finance/dashboard",
    name: "finance-dashboard",
    component: FinanceDashboardView,
    meta: {
      requiresAuth: true,
      title: "Finance Dashboard",
    },
  },
  {
    path: "/finance/accounts",
    name: "finance-accounts",
    component: FinanceAccountsView,
    meta: {
      requiresAuth: true,
      title: "Finance Accounts",
    },
  },
  {
    path: "/finance/transactions",
    name: "finance-transactions",
    component: FinanceTransactionsView,
    meta: {
      requiresAuth: true,
      title: "Finance Transactions",
    },
  },
  {
    path: "/finance/budgets",
    name: "finance-budgets",
    component: FinanceBudgetsView,
    meta: {
      requiresAuth: true,
      title: "Finance Budgets",
    },
  },

  {
    path: "/health",
    redirect: "/health/steps",
  },
  {
    path: "/health/steps",
    name: "steps-tracking",
    component: StepsTrackingView,
    meta: {
      requiresAuth: true,
      title: "Steps Tracking",
    },
  },
  {
    path: "/health/weight",
    name: "weight-tracking",
    component: WeightTrackingView,
    meta: {
      requiresAuth: true,
      title: "Weight Tracking",
    },
  },
  {
    path: "/health/nutrition",
    name: "nutrition-tracking",
    component: NutritionTrackingView,
    meta: {
      requiresAuth: true,
      title: "Nutrition Tracking",
    },
  },
  {
    path: "/health/hydration",
    name: "hydration-tracking",
    component: HydrationTrackingView,
    meta: {
      requiresAuth: true,
      title: "Hydration Tracking",
    },
  },

  {
    path: "/projects",
    redirect: "/projects/dashboard",
  },
  {
    path: "/projects/dashboard",
    name: "projects-dashboard",
    component: ProjectsDashboardView,
    meta: {
      requiresAuth: true,
      title: "Projects Dashboard",
    },
  },
  {
    path: "/projects/tasks",
    name: "projects-tasks",
    component: ProjectsTasksView,
    meta: {
      requiresAuth: true,
      title: "Project Tasks",
    },
  },
  {
    path: "/projects/milestones",
    name: "projects-milestones",
    component: ProjectsMilestonesView,
    meta: {
      requiresAuth: true,
      title: "Project Milestones",
    },
  },
  {
    path: "/projects/progress",
    name: "projects-progress",
    component: ProjectsProgressView,
    meta: {
      requiresAuth: true,
      title: "Project Progress",
    },
  },
  {
    path: "/projects/status-updates",
    name: "status-updates",
    component: StatusUpdatesView,
    meta: {
      requiresAuth: true,
      title: "Status Updates",
    },
  },

  {
    path: "/notifications",
    name: "notifications",
    component: NotificationsView,
    meta: {
      requiresAuth: true,
      title: "Notifications",
    },
  },
  {
    path: "/notifications/settings",
    name: "notification-settings",
    component: NotificationSettingsView,
    meta: {
      requiresAuth: true,
      title: "Notification Settings",
    },
  },

  {
    path: "/monitoring",
    name: "monitoring-dashboard",
    component: MonitoringDashboardView,
    meta: {
      requiresAuth: true,
      title: "Logging & Monitoring",
    },
  },

  {
    path: "/:pathMatch(.*)*",
    redirect: "/",
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

router.beforeEach((to, from, next) => {
  const token =
    localStorage.getItem("nix_token") ||
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token");

  const isPublicPage = to.meta.public === true;
  const requiresAuth = to.meta.requiresAuth === true || !isPublicPage;

  if (requiresAuth && !token) {
    return next({
      path: "/login",
      query: {
        redirect: to.fullPath,
      },
    });
  }

  if ((to.path === "/login" || to.path === "/register") && token) {
    return next("/");
  }

  document.title = to.meta.title
    ? `${to.meta.title} | NIX LIFE OS`
    : "NIX LIFE OS";

  return next();
});

export default router;