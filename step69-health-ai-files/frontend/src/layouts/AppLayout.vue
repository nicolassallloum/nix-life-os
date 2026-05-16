<script setup>
import { RouterLink, RouterView } from "vue-router";

const linkClass =
  "block rounded-xl px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 hover:text-slate-950";

const activeClass =
  "bg-slate-950 text-white hover:bg-slate-950 hover:text-white";
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <div class="flex min-h-screen">
      <!-- Sidebar -->
      <aside class="w-64 shrink-0 border-r border-slate-200 bg-white px-5 py-6">
        <div class="mb-8">
          <h1 class="text-2xl font-black tracking-wide text-slate-950">
            NIX LIFE OS
          </h1>
          <p class="mt-1 text-xs text-slate-500">
            Personal Operating System
          </p>
        </div>

        <nav class="space-y-6">
          <!-- Main -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Main
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/unified-dashboard"
                :class="linkClass"
                :active-class="activeClass"
              >
                Unified Dashboard
              </RouterLink>
              <RouterLink
                to="/ai/recommendations"
                class="nav-link"
                active-class="active"
              >
                AI Recommendations
              </RouterLink>

              <RouterLink
                to="/life-balance"
                :class="linkClass"
                :active-class="activeClass"
              >
                Life Balance
              </RouterLink>
            </div>
          </div>


          <!-- Productivity -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Productivity
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/productivity/dashboard"
                :class="linkClass"
                :active-class="activeClass"
              >
                Productivity Dashboard
              </RouterLink>
            </div>
          </div>

          <!-- Finance -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Finance
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/finance/dashboard"
                :class="linkClass"
                :active-class="activeClass"
              >
                Finance Dashboard
              </RouterLink>

              <RouterLink
                to="/finance/accounts"
                :class="linkClass"
                :active-class="activeClass"
              >
                Finance Accounts
              </RouterLink>

              <RouterLink
                to="/finance/transactions"
                :class="linkClass"
                :active-class="activeClass"
              >
                Finance Transactions
              </RouterLink>

              <RouterLink
                to="/finance/budgets"
                :class="linkClass"
                :active-class="activeClass"
              >
                Finance Budgets
              </RouterLink>
            </div>
          </div>

          <!-- Health -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Health
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/health"
                :class="linkClass"
                :active-class="activeClass"
              >
                Health Dashboard
              </RouterLink>
              <RouterLink
                to="/health/steps"
                :class="linkClass"
                :active-class="activeClass"
              >
                Steps Tracking
              </RouterLink>

              <RouterLink
                to="/health/weight"
                :class="linkClass"
                :active-class="activeClass"
              >
                Weight Tracking
              </RouterLink>

              <RouterLink
                to="/health/nutrition"
                :class="linkClass"
                :active-class="activeClass"
              >
                Nutrition Tracking
              </RouterLink>

              <RouterLink
                to="/health/custom-foods"
                :class="linkClass"
                :active-class="activeClass"
              >
                Custom Foods
              </RouterLink>
              <RouterLink
                to="/health/hydration"
                :class="linkClass"
                :active-class="activeClass"
              >
                Hydration Tracking
              </RouterLink>
              <RouterLink
                to="/health/sleep"
                :class="linkClass"
                :active-class="activeClass"
              >
                Sleep Tracking
              </RouterLink>

              <RouterLink
                to="/health/medications"
                :class="linkClass"
                :active-class="activeClass"
              >
                Medication Tracking
              </RouterLink>
              <RouterLink
                to="/health/medicaments"
                :class="linkClass"
                :active-class="activeClass"
              >
                Medicaments
              </RouterLink>

              <RouterLink
                to="/health/lab-tests"
                :class="linkClass"
                :active-class="activeClass"
              >
                Lab Tests
              </RouterLink>
              <RouterLink to="/health/alerts" class="sidebar-link">
                <span>Health Alerts</span>
              </RouterLink>
              <RouterLink
                to="/health/reports"
                :class="linkClass"
                :active-class="activeClass"
              >
                Health Reports
              </RouterLink>
            </div>
          </div>

          <!-- Projects -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Projects
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/projects/dashboard"
                :class="linkClass"
                :active-class="activeClass"
              >
                Projects Dashboard
              </RouterLink>

              <RouterLink
                to="/projects/tasks"
                :class="linkClass"
                :active-class="activeClass"
              >
                Project Tasks
              </RouterLink>

              <RouterLink
                to="/projects/milestones"
                :class="linkClass"
                :active-class="activeClass"
              >
                Project Milestones
              </RouterLink>

              <RouterLink
                to="/projects/progress"
                :class="linkClass"
                :active-class="activeClass"
              >
                Project Progress
              </RouterLink>

              <RouterLink
                to="/projects/status-updates"
                :class="linkClass"
                :active-class="activeClass"
              >
                Status Updates
              </RouterLink>
              <RouterLink
                to="/projects/list"
                :class="linkClass"
                :active-class="activeClass"
              >
                Project List
              </RouterLink>
            </div>
          </div>

          <!-- Notifications -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
              Notifications
            </p>

            <div class="space-y-1">
              <RouterLink
                to="/notifications"
                :class="linkClass"
                :active-class="activeClass"
              >
                Notifications
              </RouterLink>

              <RouterLink
                to="/notifications/settings"
                :class="linkClass"
                :active-class="activeClass"
              >
                Notification Settings
              </RouterLink>
            </div>
          </div>
        </nav>
      </aside>

      <!-- Page Content -->
      <main class="min-w-0 flex-1 overflow-x-hidden">
        <div class="p-6">
          <RouterView />
        </div>
      </main>
    </div>
  </div>
</template>