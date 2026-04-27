<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex">
    <!-- Main Sidebar -->
    <aside class="w-72 bg-white border-r border-gray-200 min-h-screen p-6">
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
          active-class="bg-gray-900 text-white"
        >
          Unified Dashboard
        </RouterLink>

        <!-- Finance -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Finance
        </p>

        <RouterLink
          to="/finance"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Finance Dashboard
        </RouterLink>

        <RouterLink
          to="/finance/accounts"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Finance Accounts
        </RouterLink>

        <RouterLink
          to="/finance/transactions"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Finance Transactions
        </RouterLink>

        <RouterLink
          to="/finance/budgets"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
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
          active-class="bg-gray-900 text-white"
        >
          Steps Tracking
        </RouterLink>

        <RouterLink
          to="/health/weight"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Weight Tracking
        </RouterLink>

        <RouterLink
          to="/health/nutrition"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Nutrition Tracking
        </RouterLink>

        <RouterLink
          to="/health/hydration"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Hydration Tracking
        </RouterLink>

        <!-- Projects -->
        <p class="text-xs font-bold text-gray-400 uppercase mt-8 mb-2">
          Projects
        </p>

        <RouterLink
          to="/projects"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Projects Dashboard
        </RouterLink>

        <RouterLink
          to="/projects/tasks"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Project Tasks
        </RouterLink>

        <RouterLink
          to="/projects/milestones"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Project Milestones
        </RouterLink>

        <RouterLink
          to="/projects/progress"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Project Progress
        </RouterLink>

        <RouterLink
          to="/projects/status-updates"
          class="block rounded-xl px-4 py-3 text-gray-700 hover:bg-gray-100"
          active-class="bg-gray-900 text-white"
        >
          Status Updates
        </RouterLink>
      </nav>
    </aside>

    <!-- Page Content -->
    <main class="flex-1 p-8 overflow-y-auto">
      <RouterView />
    </main>
  </div>
</template>