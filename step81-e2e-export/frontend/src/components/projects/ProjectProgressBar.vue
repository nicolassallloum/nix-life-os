<script setup>
const props = defineProps({
  value: {
    type: Number,
    default: 0,
  },
  size: {
    type: String,
    default: "md",
  },
});

function progressColor(value) {
  if (value >= 80) return "bg-emerald-500";
  if (value >= 50) return "bg-blue-500";
  if (value >= 25) return "bg-yellow-500";
  return "bg-red-500";
}

function safeValue(value) {
  if (!value) return 0;
  if (value < 0) return 0;
  if (value > 100) return 100;
  return Math.round(value);
}
</script>

<template>
  <div class="w-full">
    <div class="mb-1 flex items-center justify-between">
      <span class="text-xs font-medium text-gray-500">Progress</span>
      <span class="text-xs font-bold text-gray-700">{{ safeValue(value) }}%</span>
    </div>

    <div
      class="w-full overflow-hidden rounded-full bg-gray-200"
      :class="size === 'sm' ? 'h-2' : 'h-3'"
    >
      <div
        class="h-full rounded-full transition-all duration-500"
        :class="progressColor(safeValue(value))"
        :style="{ width: safeValue(value) + '%' }"
      ></div>
    </div>
  </div>
</template>
