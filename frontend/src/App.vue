<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <div class="flex">
      <!-- Sidebar -->
      <aside class="min-h-screen w-72 bg-white p-6 shadow">
        <h1 class="mb-8 text-2xl font-bold text-gray-900">
          NIX LIFE OS
        </h1>

        <nav class="space-y-2">
          <RouterLink
            to="/finance/accounts"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Accounts
          </RouterLink>

          <RouterLink
            to="/finance/transactions"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Transactions
          </RouterLink>

          <RouterLink
            to="/finance/budgets"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Finance Budgets
          </RouterLink>

          <RouterLink
            to="/health/steps"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Steps Tracking
          </RouterLink>

          <RouterLink
            to="/health/weight"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Weight Tracking
          </RouterLink>

          <RouterLink
            to="/health/nutrition"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Nutrition Tracking
          </RouterLink>

          <RouterLink
            to="/health/hydration"
            class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
          >
            Hydration Tracking
          </RouterLink>
        </nav>
      </aside>

      <!-- Main Content -->
      <main class="flex-1">
        <RouterView />
      </main>
    </div>
  </div>
</template>