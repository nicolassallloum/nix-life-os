<template>
  <section class="min-h-[60vh] flex items-center justify-center px-4">
    <div class="max-w-xl rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
      <p class="text-sm font-semibold uppercase tracking-wide text-red-600">403 Forbidden</p>
      <h1 class="mt-2 text-3xl font-bold text-slate-950">Access Not Allowed</h1>
      <p class="mt-3 text-slate-600">
        Your current account does not have permission to open this page.
      </p>
      <div class="mt-6 flex flex-col justify-center gap-3 sm:flex-row">
        <RouterLink
          to="/dashboard"
          class="inline-flex rounded-xl bg-slate-950 px-5 py-3 text-sm font-semibold text-white hover:bg-slate-800"
        >
          Back to Dashboard
        </RouterLink>
        <RouterLink
          to="/login"
          class="inline-flex rounded-xl border border-slate-300 px-5 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Login with Another Account
        </RouterLink>
      </div>
    </div>
  </section>
</template>

<script setup>
import { RouterLink } from 'vue-router'
</script>
