<script setup>
defineProps({
  title: {
    type: String,
    default: 'No data available yet',
  },
  message: {
    type: String,
    default: 'Create your first record to start seeing insights here.',
  },
  actionLabel: {
    type: String,
    default: '',
  },
  actionTo: {
    type: String,
    default: '',
  },
})
</script>

<template>
  <div class="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-white text-xl shadow-sm">
      ∅
    </div>

    <h3 class="mt-4 text-base font-bold text-slate-900">
      {{ title }}
    </h3>

    <p class="mx-auto mt-2 max-w-md text-sm text-slate-500">
      {{ message }}
    </p>

    <RouterLink
      v-if="actionLabel && actionTo"
      :to="actionTo"
      class="mt-5 inline-flex items-center justify-center rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
    >
      {{ actionLabel }}
    </RouterLink>
  </div>
</template>
