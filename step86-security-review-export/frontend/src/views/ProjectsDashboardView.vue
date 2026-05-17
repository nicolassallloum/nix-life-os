<template>
  <div>
    <h1 class="text-4xl font-bold text-gray-900">
      Projects Dashboard
    </h1>
    <p class="text-gray-500 mt-2">
      Manage all NIX LIFE OS projects.
    </p>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Active Projects</p>
        <h2 class="text-3xl font-bold mt-2">1</h2>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">In Progress</p>
        <h2 class="text-3xl font-bold mt-2">1</h2>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Progress</p>
        <h2 class="text-3xl font-bold mt-2">0%</h2>
      </div>
    </div>
  </div>
</template>