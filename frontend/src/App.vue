<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <aside class="fixed left-0 top-0 h-full w-72 bg-white border-r border-gray-200 p-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-8">
        NIX LIFE OS
      </h1>

      <nav class="space-y-2">
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
          Nutrition Dashboard
        </RouterLink>

        <RouterLink
          to="/health/nutrition/meals"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Meal Logger
        </RouterLink>

        <RouterLink
          to="/health/nutrition/foods"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Food Items
        </RouterLink>
      </nav>
    </aside>

    <main class="ml-72 p-8">
      <RouterView />
    </main>
  </div>
</template>