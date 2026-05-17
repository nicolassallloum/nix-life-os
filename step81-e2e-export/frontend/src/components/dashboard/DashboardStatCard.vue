<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    required: true,
  },
  subtitle: {
    type: String,
    default: "",
  },
  icon: {
    type: String,
    default: "📊",
  },
  tone: {
    type: String,
    default: "blue",
  },
});
</script>

<template>
  <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:shadow-md">
    <div class="flex items-start justify-between">
      <div>
        <p class="text-sm font-medium text-gray-500">
          {{ title }}
        </p>

        <h3 class="mt-2 text-2xl font-bold text-gray-900">
          {{ value }}
        </h3>

        <p v-if="subtitle" class="mt-1 text-sm text-gray-500">
          {{ subtitle }}
        </p>
      </div>

      <div
        class="flex h-12 w-12 items-center justify-center rounded-2xl text-xl"
        :class="{
          'bg-blue-50 text-blue-600': tone === 'blue',
          'bg-green-50 text-green-600': tone === 'green',
          'bg-orange-50 text-orange-600': tone === 'orange',
          'bg-purple-50 text-purple-600': tone === 'purple',
          'bg-red-50 text-red-600': tone === 'red',
        }"
      >
        {{ icon }}
      </div>
    </div>
  </div>
</template>