<script setup>
defineProps({
  activities: {
    type: Array,
    default: () => [],
  },
});

function getActivityIcon(type) {
  if (type === "finance") return "💰";
  if (type === "health") return "❤️";
  if (type === "project") return "📌";
  if (type === "nutrition") return "🍽️";
  if (type === "hydration") return "💧";
  return "🔔";
}
</script>

<template>
  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
    <div class="mb-5 flex items-center justify-between">
      <div>
        <h3 class="text-lg font-bold text-gray-900">
          Recent Activity
        </h3>
        <p class="text-sm text-gray-500">
          Latest finance, health, and project updates
        </p>
      </div>
    </div>

    <div v-if="activities.length" class="space-y-4">
      <div
        v-for="activity in activities"
        :key="activity.id"
        class="flex items-start gap-3 rounded-xl border border-gray-100 p-3"
      >
        <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-50 text-lg">
          {{ getActivityIcon(activity.type) }}
        </div>

        <div class="flex-1">
          <p class="text-sm font-semibold text-gray-900">
            {{ activity.title }}
          </p>

          <p class="text-sm text-gray-500">
            {{ activity.description }}
          </p>

          <p class="mt-1 text-xs text-gray-400">
            {{ activity.activity_date }}
          </p>
        </div>
      </div>
    </div>

    <div v-else class="rounded-xl bg-gray-50 p-6 text-center">
      <p class="text-sm text-gray-500">
        No recent activity yet.
      </p>
    </div>
  </div>
</template>