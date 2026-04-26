import { createRouter, createWebHistory } from "vue-router";

import AppLayout from "@/layouts/AppLayout.vue";

import NutritionDashboardView from "@/views/health/nutrition/NutritionDashboardView.vue";
import FoodItemsView from "@/views/health/nutrition/FoodItemsView.vue";
import MealLoggerView from "@/views/health/nutrition/MealLoggerView.vue";
import HealthStepsView from "@/views/health/HealthStepsView.vue";
import FinanceDashboardView from "@/views/finance/FinanceDashboardView.vue";
import FinanceTransactionsView from "@/views/finance/FinanceTransactionsView.vue";
import FinanceBudgetsView from "@/views/finance/FinanceBudgetsView.vue";
import FinanceAccountsView from "@/views/finance/FinanceAccountsView.vue";
import HealthWeightView from "@/views/health/HealthWeightView.vue";
import HealthHydrationView from "@/views/HealthHydrationView.vue";
const routes = [
  {
    path: "/",
    component: AppLayout,
    children: [
      {
        path: "",
        redirect: "/finance",
      },
      {
        path: "finance",
        name: "finance.dashboard",
        component: FinanceDashboardView,
      },
      {
        path: "finance/transactions",
        name: "finance.transactions",
        component: FinanceTransactionsView,
      },
      {
        path: "finance/accounts",
        name: "finance.accounts",
        component: FinanceAccountsView,
      },
      {
        path: "finance/budgets",
        name: "finance.budgets",
        component: FinanceBudgetsView,
      },
    ],
  },
  {
    path: "/health",
    component: AppLayout,
    children: [
      {
        path: "/health/steps",
        name: "HealthSteps",
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
        component: NutritionDashboardView,
      },
      {
        path: "/health/nutrition/foods",
        name: "health-nutrition-foods",
        component: FoodItemsView,
      },
      {
        path: "/health/nutrition/meals",
        name: "health-nutrition-meals",
        component: MealLoggerView,
      },
      {
        path: "/health/hydration",
        name: "health-hydration",
        component: HealthHydrationView,
      },
    ],
  },  
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;