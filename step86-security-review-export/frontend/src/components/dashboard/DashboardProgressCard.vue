<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  value: {
    type: Number,
    default: 0,
  },
  subtitle: {
    type: String,
    default: "",
  },
});
</script>

<template>
  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
    <div class="mb-4 flex items-center justify-between">
      <div>
        <h3 class="text-base font-semibold text-gray-900">
          {{ title }}
        </h3>

        <p v-if="subtitle" class="text-sm text-gray-500">
          {{ subtitle }}
        </p>
      </div>

      <span class="rounded-full bg-gray-100 px-3 py-1 text-sm font-semibold text-gray-700">
        {{ value }}%
      </span>
    </div>

    <div class="h-3 w-full rounded-full bg-gray-100">
      <div
        class="h-3 rounded-full bg-gray-900 transition-all duration-500"
        :style="{ width: `${value}%` }"
      ></div>
    </div>
  </div>
</template>