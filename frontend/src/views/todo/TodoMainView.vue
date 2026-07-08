<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
        To-Do
      </h1>
      <p class="text-gray-600 dark:text-gray-300">
        Manage tasks, projects, schedules, completion progress, and points.
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <section
        v-for="section in sections"
        :key="section"
        class="rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5 shadow-sm"
      >
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white">
          {{ section }}
        </h2>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
          This section will be connected to the To-Do backend APIs in the next steps.
        </p>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
const sections = [
  'Dashboard Summary',
  'Projects',
  'General Task List',
  'Monthly Tasks',
  'Weekly Tasks',
  'Daily Tasks',
  'Completed Tasks',
  'Points Summary',
]
</script>

