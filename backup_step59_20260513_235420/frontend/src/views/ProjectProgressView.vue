<template>
  <div>
    <h1 class="text-4xl font-bold text-gray-900">
      Project Progress
    </h1>
    <p class="text-gray-500 mt-2">
      Auto-calculated project completion and progress engine.
    </p>

    <div class="bg-white rounded-2xl shadow p-6 mt-8">
      <p class="text-gray-500 mb-2">Current Project Progress</p>

      <div class="w-full bg-gray-200 rounded-full h-5">
        <div
          class="bg-gray-900 h-5 rounded-full"
          style="width: 0%"
        ></div>
      </div>

      <p class="text-2xl font-bold mt-4">0%</p>
    </div>
  </div>
</template>