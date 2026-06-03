<template>
  <section class="space-y-4">
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h1 class="text-2xl font-bold text-slate-900">Medicaments</h1>
      <p class="mt-2 text-sm text-slate-500">
        Redirecting to the main Medication Tracking page...
      </p>

      <RouterLink
        to="/health/medications"
        class="mt-4 inline-flex rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
      >
        Open Medication Tracking
      </RouterLink>
    </div>
  </section>
</template>

<script setup>
import { onMounted } from "vue";
import { RouterLink, useRouter } from "vue-router";

const router = useRouter();

onMounted(() => {
  router.replace("/health/medications");
});
</script>
