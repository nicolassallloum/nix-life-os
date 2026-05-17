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
        The page you are trying to open does not exist, was moved, or the route is not registered yet.
      </p>

      <div class="mt-6 flex flex-col justify-center gap-3 sm:flex-row">
        <RouterLink
          to="/dashboard"
          class="rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700"
        >
          Go to Dashboard
        </RouterLink>

        <RouterLink
          to="/finance/dashboard"
          class="rounded-xl border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          Finance Dashboard
        </RouterLink>
      </div>

      <div class="mt-8 rounded-xl bg-slate-50 p-4 text-left">
        <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Debug Info
        </p>

        <div class="mt-3 space-y-2 text-sm text-slate-600">
          <p>
            <span class="font-medium text-slate-800">Current Route:</span>
            {{ route.fullPath }}
          </p>

          <p>
            <span class="font-medium text-slate-800">Route Name:</span>
            {{ route.name || "Not registered" }}
          </p>

          <p>
            <span class="font-medium text-slate-800">Tip:</span>
            Check
            <code class="rounded bg-white px-1 py-0.5 text-xs text-slate-800">
              src/router/index.js
            </code>
            and confirm the path exists.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRoute } from "vue-router";

const route = useRoute();
</script>