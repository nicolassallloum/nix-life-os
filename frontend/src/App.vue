<script setup>
import { RouterLink, RouterView } from "vue-router";
import { hasPermission } from "@/utils/permissions";
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex">
    <!-- Main Sidebar -->
    <aside class="w-72 bg-white border-r border-gray-200 min-h-screen p-6 overflow-y-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">
        NIX LIFE OS
      </h1>

      <p class="text-sm text-gray-500 mb-8">
        Personal Operating System
      </p>

      <nav class="space-y-2">
        <!-- Main -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-4 mb-2">
          Main
        </p>

        <RouterLink
          to="/dashboard"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Unified Dashboard
        </RouterLink>

        <RouterLink
          to="/life-balance"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Life Balance
        </RouterLink>

        <!-- Finance -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Finance
        </p>

        <RouterLink
          to="/finance"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Finance Dashboard
        </RouterLink>

        <RouterLink
          to="/finance/accounts"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Finance Accounts
        </RouterLink>

        <RouterLink
          to="/finance/transactions"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Finance Transactions
        </RouterLink>

        <RouterLink
          to="/finance/budgets"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Finance Budgets
        </RouterLink>

        <!-- Health -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Health
        </p>

        <RouterLink
          to="/health/steps"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Steps Tracking
        </RouterLink>

        <RouterLink
          to="/health/weight"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Weight Tracking
        </RouterLink>

        <RouterLink
          to="/health/nutrition"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Nutrition Tracking
        </RouterLink>

        <RouterLink
          to="/health/hydration"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Hydration Tracking
        </RouterLink>
        <RouterLink
          to="/health/sleep"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Sleep Tracking
        </RouterLink>
        <!-- Projects -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Projects
        </p>

        <RouterLink
          to="/projects"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Projects Dashboard
        </RouterLink>

        <RouterLink
          to="/projects/tasks"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Project Tasks
        </RouterLink>

        <RouterLink
          to="/projects/milestones"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Project Milestones
        </RouterLink>

        <RouterLink
          to="/projects/progress"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Project Progress
        </RouterLink>

        <RouterLink
          to="/projects/status-updates"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Status Updates
        </RouterLink>

        <!-- Notifications -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Notifications
        </p>

        <RouterLink
          to="/notifications"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Notifications
        </RouterLink>

        <RouterLink
          to="/notifications/settings"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Notification Settings
        </RouterLink>

        <!-- Automation -->
        <template v-if="hasPermission('automation.view')">
          <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
            Automation
          </p>

          <RouterLink
            to="/automation"
            class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
            active-class="bg-gray-900 text-white hover:bg-gray-900"
          >
            Automation
          </RouterLink>
        </template>

        <!-- Security -->
        <template v-if="hasPermission('security.manage')">
          <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
            Security
          </p>

          <RouterLink
            to="/security/roles"
            class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
            active-class="bg-gray-900 text-white hover:bg-gray-900"
          >
            Security & Roles
          </RouterLink>
        </template>

        <!-- System -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          System
        </p>

        <RouterLink
          to="/monitoring"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white hover:bg-gray-900"
        >
          Logging & Monitoring
        </RouterLink>
      </nav>
    </aside>

    <!-- Page Content -->
    <main class="flex-1 p-8 overflow-y-auto">
      <RouterView />
    </main>
  </div>
</template>