import { createRouter, createWebHistory } from "vue-router";

import FinanceDashboardView from "../views/finance/FinanceDashboardView.vue";
import FinanceAccountsView from "../views/finance/FinanceAccountsView.vue";
import FinanceTransactionsView from "../views/finance/FinanceTransactionsView.vue";
import FinanceBudgetsView from "../views/finance/FinanceBudgetsView.vue";
import UnifiedDashboardView from "@/views/dashboard/UnifiedDashboardView.vue";
import HealthStepsView from "../views/health/HealthStepsView.vue";
import HealthWeightView from "../views/health/HealthWeightView.vue";
import HealthNutritionView from "../views/health/HealthNutritionView.vue";
import HealthHydrationView from "../views/HealthHydrationView.vue";
import ProjectDashboardView from "../views/projects/ProjectDashboardView.vue";
import LifeBalanceView from "../views/life-balance/LifeBalanceView.vue";
import ProjectTasksView from "../views/ProjectTasksView.vue";
import ProjectMilestonesView from "../views/ProjectMilestonesView.vue";
import NotificationsView from "../views/notifications/NotificationsView.vue";
import NotificationSettingsView from "../views/notifications/NotificationSettingsView.vue";
import ProjectProgressView from "../views/ProjectProgressView.vue";
import ProjectStatusUpdatesView from "../views/ProjectStatusUpdatesView.vue";

const routes = [
  {
    path: "/",
    redirect: "/finance",
  },

  // Finance
  {
    path: "/finance",
    name: "finance-dashboard",
    component: FinanceDashboardView,
  },
  {
  path: "/dashboard",
  name: "unified-dashboard",
  component: UnifiedDashboardView,
  },
  {
  path: "/notifications",
  name: "notifications",
  component: NotificationsView,
  },
  {
    path: "/notifications/settings",
    name: "notification-settings",
    component: NotificationSettingsView,
  },
  {
    path: "/finance/accounts",
    name: "finance-accounts",
    component: FinanceAccountsView,
  },
  {
  path: "/life-balance",
  name: "LifeBalance",
  component: LifeBalanceView,
  },
  {
    path: "/finance/transactions",
    name: "finance-transactions",
    component: FinanceTransactionsView,
  },
  {
    path: "/finance/budgets",
    name: "finance-budgets",
    component: FinanceBudgetsView,
  },
  // Projects
  {
    path: "/projects",
    name: "projects.dashboard",
    component: ProjectDashboardView,
  },
  // Health
  {
    path: "/health/steps",
    name: "health-steps",
    component: HealthStepsView,
  },
  {
    path: "/health/weight",
    name: "health-weight",
    component: HealthWeightView,
  },
  {
    path: "/health/nutrition",
    name: "health-nutrition",
    component: HealthNutritionView,
  },
  {
    path: "/health/hydration",
    name: "health-hydration",
    component: HealthHydrationView,
  },

  // Projects
  {
  path: "/projects",
  name: "projects.dashboard",
  component: ProjectDashboardView,
  },
  {
    path: "/projects/tasks",
    name: "project-tasks",
    component: ProjectTasksView,
  },
  {
    path: "/projects/milestones",
    name: "project-milestones",
    component: ProjectMilestonesView,
  },
  {
    path: "/projects/progress",
    name: "project-progress",
    component: ProjectProgressView,
  },
  {
    path: "/projects/status-updates",
    name: "project-status-updates",
    component: ProjectStatusUpdatesView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;