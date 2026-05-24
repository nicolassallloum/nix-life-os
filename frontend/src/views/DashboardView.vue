<template>
  <div class="space-y-5">
    <PageHeader
      title="Dashboard"
      description="Overview of your finance, health, projects, and productivity."
    />

    <!-- KPI Cards -->
    <section class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div
        v-for="card in cards"
        :key="card.title"
        class="rounded-2xl border border-slate-800 bg-slate-900/80 p-4 shadow-lg sm:p-5"
      >
        <p class="text-sm text-slate-400">
          {{ card.title }}
        </p>

        <div class="mt-3 flex items-end justify-between gap-3">
          <h3 class="truncate text-2xl font-bold text-white">
            {{ card.value }}
          </h3>

          <span class="shrink-0 rounded-full bg-cyan-500/10 px-2.5 py-1 text-xs font-semibold text-cyan-300">
            {{ card.trend }}
          </span>
        </div>
      </div>
    </section>

    <!-- Main Layout -->
    <section class="grid grid-cols-1 gap-5 xl:grid-cols-3">
      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-4 xl:col-span-2">
        <div class="mb-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 class="text-base font-semibold text-white">
              Monthly Overview
            </h2>
            <p class="text-sm text-slate-400">
              Finance and productivity activity.
            </p>
          </div>

          <select class="w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-white sm:w-auto">
            <option>This Month</option>
            <option>Last Month</option>
          </select>
        </div>

        <div class="flex h-64 items-center justify-center rounded-xl border border-dashed border-slate-700 text-sm text-slate-400 sm:h-80">
          Chart Area
        </div>
      </div>

      <div class="rounded-2xl border border-slate-800 bg-slate-900/80 p-4">
        <h2 class="text-base font-semibold text-white">
          Today Summary
        </h2>

        <div class="mt-4 space-y-3">
          <div
            v-for="item in summary"
            :key="item.label"
            class="flex items-center justify-between gap-3 rounded-xl bg-slate-950/70 p-3"
          >
            <span class="text-sm text-slate-400">
              {{ item.label }}
            </span>

            <span class="text-sm font-semibold text-white">
              {{ item.value }}
            </span>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import PageHeader from '@/components/ui/PageHeader.vue'

const cards = [
  {
    title: 'Total Balance',
    value: '$12,500',
    trend: '+8.2%'
  },
  {
    title: 'Health Score',
    value: '82%',
    trend: '+4%'
  },
  {
    title: 'Active Projects',
    value: '7',
    trend: '2 due'
  },
  {
    title: 'Productivity',
    value: '91%',
    trend: '+12%'
  }
]

const summary = [
  {
    label: 'Tasks Completed',
    value: '12'
  },
  {
    label: 'Water Intake',
    value: '1.8L'
  },
  {
    label: 'Expenses Today',
    value: '$42'
  },
  {
    label: 'Steps',
    value: '7,450'
  }
]
</script>
