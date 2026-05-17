<script setup>
import ProjectProgressBar from "./ProjectProgressBar.vue";

const props = defineProps({
  project: {
    type: Object,
    required: true,
  },
});

function formatDate(date) {
  if (!date) return "Not set";

  return new Date(date).toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "2-digit",
  });
}

function statusClass(status) {
  const classes = {
    planned: "bg-gray-100 text-gray-700",
    in_progress: "bg-blue-100 text-blue-700",
    on_hold: "bg-yellow-100 text-yellow-700",
    completed: "bg-emerald-100 text-emerald-700",
    cancelled: "bg-red-100 text-red-700",
  };

  return classes[status] || "bg-gray-100 text-gray-700";
}

function priorityClass(priority) {
  const classes = {
    low: "bg-gray-100 text-gray-700",
    medium: "bg-blue-100 text-blue-700",
    high: "bg-orange-100 text-orange-700",
    critical: "bg-red-100 text-red-700",
  };

  return classes[priority] || "bg-gray-100 text-gray-700";
}

function cleanText(value) {
  if (!value) return "-";

  return value
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}
</script>

<template>
  <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm transition hover:shadow-md">
    <div class="mb-4 flex items-start justify-between gap-3">
      <div>
        <h3 class="text-lg font-bold text-gray-900">
          {{ project.project_name }}
        </h3>

        <p class="mt-1 text-sm text-gray-500">
          {{ project.project_code || "No Code" }}
        </p>
      </div>

      <span
        class="rounded-full px-3 py-1 text-xs font-bold"
        :class="statusClass(project.status)"
      >
        {{ cleanText(project.status) }}
      </span>
    </div>

    <p class="mb-4 line-clamp-2 text-sm text-gray-600">
      {{ project.description || "No description available." }}
    </p>

    <ProjectProgressBar :value="project.progress_percentage" />

    <div class="mt-4 grid grid-cols-2 gap-3 text-sm">
      <div class="rounded-xl bg-gray-50 p-3">
        <p class="text-xs font-medium text-gray-500">Priority</p>
        <span
          class="mt-1 inline-block rounded-full px-2 py-1 text-xs font-bold"
          :class="priorityClass(project.priority)"
        >
          {{ cleanText(project.priority) }}
        </span>
      </div>

      <div class="rounded-xl bg-gray-50 p-3">
        <p class="text-xs font-medium text-gray-500">Target Date</p>
        <p class="mt-1 font-semibold text-gray-800">
          {{ formatDate(project.target_end_date) }}
        </p>
      </div>
    </div>
  </div>
</template>
