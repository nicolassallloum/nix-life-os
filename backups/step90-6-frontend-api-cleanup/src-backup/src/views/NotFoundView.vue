<template>
  <div class="flex min-h-[70vh] items-center justify-center px-4">
    <div class="w-full max-w-xl rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
      <div class="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100">
        <span class="text-3xl font-bold text-slate-700">404</span>
      </div>

      <h1 class="text-2xl font-bold text-slate-900">
        Page Not Found
      </h1>

      <p class="mt-3 text-sm leading-6 text-slate-500">
        The page you are trying to open does not exist or was moved.
      </p>

      <div class="mt-6 flex flex-col justify-center gap-3 sm:flex-row">
        <RouterLink
          to="/dashboard"
          class="rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700"
        >
          Go to Dashboard
        </RouterLink>

        <button
          type="button"
          class="rounded-xl border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          @click="router.back()"
        >
          Go Back
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { RouterLink, useRouter } from "vue-router";

const router = useRouter();
</script>
