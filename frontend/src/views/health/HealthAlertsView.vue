<template>
  <main class="health-alerts-page">
    <HealthAlertsPanel />
  </main>
</template>

<script setup>
import HealthAlertsPanel from "@/components/health/HealthAlertsPanel.vue";
</script>

<style scoped>
.health-alerts-page {
  padding: 24px;
  color: #0f172a;
}

/*
  Production readability fix:
  The alerts panel is rendered inside this route component. Some global/dark-theme
  styles can make light buttons display white text on white backgrounds.
  These deep selectors keep light/secondary alert actions readable without changing
  the backend or the panel logic.
*/
.health-alerts-page :deep(button),
.health-alerts-page :deep(a),
.health-alerts-page :deep([role="button"]) {
  text-decoration: none;
}

.health-alerts-page :deep(.secondary-btn),
.health-alerts-page :deep(.ghost-btn),
.health-alerts-page :deep(.outline-btn),
.health-alerts-page :deep(.filter-btn),
.health-alerts-page :deep(.refresh-btn),
.health-alerts-page :deep(.small-btn),
.health-alerts-page :deep(.action-btn),
.health-alerts-page :deep(button.secondary),
.health-alerts-page :deep(button.ghost),
.health-alerts-page :deep(button.outline) {
  background-color: #ffffff !important;
  border-color: #cbd5e1 !important;
  color: #0f172a !important;
  -webkit-text-fill-color: #0f172a !important;
}

.health-alerts-page :deep(.secondary-btn:hover),
.health-alerts-page :deep(.ghost-btn:hover),
.health-alerts-page :deep(.outline-btn:hover),
.health-alerts-page :deep(.filter-btn:hover),
.health-alerts-page :deep(.refresh-btn:hover),
.health-alerts-page :deep(.small-btn:hover),
.health-alerts-page :deep(.action-btn:hover),
.health-alerts-page :deep(button.secondary:hover),
.health-alerts-page :deep(button.ghost:hover),
.health-alerts-page :deep(button.outline:hover) {
  background-color: #f8fafc !important;
  color: #0f172a !important;
  -webkit-text-fill-color: #0f172a !important;
}

.health-alerts-page :deep(.primary-btn),
.health-alerts-page :deep(.run-btn),
.health-alerts-page :deep(.run-alerts-btn),
.health-alerts-page :deep(.resolve-btn),
.health-alerts-page :deep(button.primary) {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
}

.health-alerts-page :deep(.dismiss-btn),
.health-alerts-page :deep(.danger-btn),
.health-alerts-page :deep(.delete-btn) {
  color: #991b1b !important;
  -webkit-text-fill-color: #991b1b !important;
}

.health-alerts-page :deep(button:disabled),
.health-alerts-page :deep([role="button"][aria-disabled="true"]) {
  opacity: 0.65;
}
</style>

