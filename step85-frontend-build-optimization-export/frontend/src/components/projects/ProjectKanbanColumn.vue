<script setup>
import ProjectProgressBar from "./ProjectProgressBar.vue";

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  projects: {
    type: Array,
    default: () => [],
  },
});

function priorityClass(priority) {
  const classes = {
    low: "bg-gray-100 text-gray-600",
    medium: "bg-blue-100 text-blue-700",
    high: "bg-orange-100 text-orange-700",
    critical: "bg-red-100 text-red-700",
  };

  return classes[priority] || "bg-gray-100 text-gray-600";
}

function cleanText(value) {
  if (!value) return "-";

  return value
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}
</script>

<template>
  <div class="min-h-[500px] rounded-2xl border border-gray-200 bg-gray-50 p-4">
    <div class="mb-4 flex items-center justify-between">
      <h3 class="text-sm font-bold uppercase tracking-wide text-gray-700">
        {{ title }}
      </h3>

      <span class="rounded-full bg-white px-3 py-1 text-xs font-bold text-gray-600 shadow-sm">
        {{ projects.length }}
      </span>
    </div>

    <div class="space-y-4">
      <div
        v-for="project in projects"
        :key="project.id"
        class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm"
      >
        <div class="mb-3 flex items-start justify-between gap-2">
          <div>
            <h4 class="font-bold text-gray-900">
              {{ project.project_name }}
            </h4>

            <p class="text-xs text-gray-500">
              {{ project.project_code || "No Code" }}
            </p>
          </div>

          <span
            class="rounded-full px-2 py-1 text-[11px] font-bold"
            :class="priorityClass(project.priority)"
          >
            {{ cleanText(project.priority) }}
          </span>
        </div>

        <p class="mb-3 line-clamp-2 text-xs text-gray-500">
          {{ project.description || "No description." }}
        </p>

        <ProjectProgressBar :value="project.progress_percentage" size="sm" />
      </div>

      <div
        v-if="projects.length === 0"
        class="rounded-2xl border border-dashed border-gray-300 bg-white p-6 text-center text-sm text-gray-400"
      >
        No projects
      </div>
    </div>
  </div>
</template>
