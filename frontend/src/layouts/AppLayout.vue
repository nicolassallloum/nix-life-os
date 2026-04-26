<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-slate-50 flex">
    <!-- Sidebar -->
    <aside class="w-64 min-h-screen bg-slate-900 text-white p-5">
      <h1 class="text-xl font-bold mb-8">
        NIX LIFE OS
      </h1>

      <nav class="space-y-2">
        <RouterLink
          to="/finance"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Finance Dashboard
        </RouterLink>

        <RouterLink
          to="/finance/transactions"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Transactions
        </RouterLink>

        <RouterLink
          to="/finance/accounts"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Accounts
        </RouterLink>

        <RouterLink
          to="/finance/budgets"
          class="block px-4 py-3 rounded-xl hover:bg-slate-800"
        >
          Budgets
        </RouterLink>
      </nav>
    </aside>

    <!-- Page Content -->
    <main class="flex-1">
      <RouterView />
    </main>
  </div>
</template>