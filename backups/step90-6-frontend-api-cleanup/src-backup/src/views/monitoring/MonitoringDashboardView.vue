<script setup>
import { ref, onMounted } from "vue";

const API_BASE_URL = "/api/v1";

const token = localStorage.getItem("token");

const summary = ref(null);
const health = ref(null);
const auditLogs = ref([]);
const errorLogs = ref([]);

const loading = ref(false);
const error = ref(null);

async function apiGet(endpoint) {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: "GET",
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
    },
  });

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(data?.message || `API request failed with status ${response.status}`);
  }

  return data;
}

async function loadMonitoringData() {
  loading.value = true;
  error.value = null;

  try {
    health.value = await apiGet("/monitoring/health-check");
    summary.value = await apiGet("/monitoring/summary");

    const auditResponse = await apiGet("/monitoring/audit-logs");
    auditLogs.value = auditResponse?.data || [];

    const errorResponse = await apiGet("/monitoring/error-logs");
    errorLogs.value = errorResponse?.data || [];
  } catch (err) {
    error.value = err.message || "Failed to load monitoring data.";
  } finally {
    loading.value = false;
  }
}

function formatDate(value) {
  if (!value) {
    return "-";
  }

  try {
    return new Date(value).toLocaleString();
  } catch {
    return value;
  }
}

onMounted(() => {
  loadMonitoringData();
});
</script>

<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Logging & Monitoring
        </h1>

        <p class="text-gray-500 mt-1">
          Audit logs, error tracking, and system health monitoring.
        </p>
      </div>

      <button
        type="button"
        @click="loadMonitoringData"
        class="px-5 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-700 transition"
      >
        Refresh
      </button>
    </div>

    <!-- Token Warning -->
    <div
      v-if="!token"
      class="p-4 rounded-xl bg-yellow-50 text-yellow-800 border border-yellow-200"
    >
      No authentication token found in localStorage. Please login first or save your token as
      <strong>token</strong>.
    </div>

    <!-- Loading -->
    <div
      v-if="loading"
      class="p-5 rounded-2xl bg-white border shadow text-gray-500"
    >
      Loading monitoring data...
    </div>

    <!-- Error -->
    <div
      v-if="error"
      class="p-5 rounded-2xl bg-red-50 text-red-700 border border-red-200"
    >
      <strong>Error:</strong> {{ error }}
    </div>

    <!-- Main Dashboard -->
    <div v-if="!loading" class="space-y-8">
      <!-- KPI Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
        <div class="bg-white rounded-2xl shadow p-5 border border-gray-200">
          <p class="text-sm text-gray-500">
            System Status
          </p>

          <h2
            class="text-2xl font-bold mt-2 capitalize"
            :class="health?.status === 'healthy' ? 'text-green-600' : 'text-red-600'"
          >
            {{ health?.status || "Unknown" }}
          </h2>

          <p class="text-xs text-gray-400 mt-2">
            {{ health?.message || "No health check result yet." }}
          </p>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border border-gray-200">
          <p class="text-sm text-gray-500">
            Response Time
          </p>

          <h2 class="text-2xl font-bold mt-2 text-gray-900">
            {{ health?.response_time_ms ?? "-" }} ms
          </h2>

          <p class="text-xs text-gray-400 mt-2">
            Latest API health check response time.
          </p>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border border-gray-200">
          <p class="text-sm text-gray-500">
            Audit Logs Today
          </p>

          <h2 class="text-2xl font-bold mt-2 text-gray-900">
            {{ summary?.audit_logs_today ?? 0 }}
          </h2>

          <p class="text-xs text-gray-400 mt-2">
            User and API activities recorded today.
          </p>
        </div>

        <div class="bg-white rounded-2xl shadow p-5 border border-gray-200">
          <p class="text-sm text-gray-500">
            Errors Today
          </p>

          <h2 class="text-2xl font-bold mt-2 text-red-600">
            {{ summary?.errors_today ?? 0 }}
          </h2>

          <p class="text-xs text-gray-400 mt-2">
            Backend exceptions tracked today.
          </p>
        </div>
      </div>

      <!-- Health Details -->
      <div class="bg-white rounded-2xl shadow border border-gray-200">
        <div class="p-5 border-b border-gray-200">
          <h2 class="text-xl font-bold text-gray-900">
            System Health
          </h2>
        </div>

        <div class="p-5 grid grid-cols-1 md:grid-cols-3 gap-5 text-sm">
          <div>
            <p class="text-gray-500">
              Service
            </p>

            <p class="font-semibold text-gray-900 mt-1">
              {{ health?.service || "nix-life-os-api" }}
            </p>
          </div>

          <div>
            <p class="text-gray-500">
              Database
            </p>

            <p
              class="font-semibold mt-1 capitalize"
              :class="health?.database === 'healthy' ? 'text-green-600' : 'text-red-600'"
            >
              {{ health?.database || "Unknown" }}
            </p>
          </div>

          <div>
            <p class="text-gray-500">
              Checked At
            </p>

            <p class="font-semibold text-gray-900 mt-1">
              {{ formatDate(health?.checked_at) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Latest Error Logs -->
      <div class="bg-white rounded-2xl shadow border border-gray-200">
        <div class="p-5 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">
              Latest Error Logs
            </h2>

            <p class="text-sm text-gray-500 mt-1">
              Recent backend errors captured by the monitoring system.
            </p>
          </div>

          <span class="text-sm text-gray-500">
            {{ errorLogs.length }} records
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-gray-600">
              <tr>
                <th class="text-left p-4 font-semibold">Date</th>
                <th class="text-left p-4 font-semibold">Level</th>
                <th class="text-left p-4 font-semibold">Module</th>
                <th class="text-left p-4 font-semibold">Exception</th>
                <th class="text-left p-4 font-semibold">Message</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in errorLogs"
                :key="log.id"
                class="border-t border-gray-100 hover:bg-gray-50"
              >
                <td class="p-4 whitespace-nowrap">
                  {{ formatDate(log.created_at) }}
                </td>

                <td class="p-4">
                  <span class="px-3 py-1 rounded-full bg-red-50 text-red-700 text-xs font-semibold">
                    {{ log.level || "error" }}
                  </span>
                </td>

                <td class="p-4">
                  {{ log.module || "-" }}
                </td>

                <td class="p-4">
                  {{ log.exception_class || "-" }}
                </td>

                <td class="p-4 text-red-600 max-w-xl truncate">
                  {{ log.message }}
                </td>
              </tr>

              <tr v-if="errorLogs.length === 0">
                <td colspan="5" class="p-6 text-center text-gray-500">
                  No error logs found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Latest Audit Logs -->
      <div class="bg-white rounded-2xl shadow border border-gray-200">
        <div class="p-5 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-gray-900">
              Latest Audit Logs
            </h2>

            <p class="text-sm text-gray-500 mt-1">
              Recent user and API activity records.
            </p>
          </div>

          <span class="text-sm text-gray-500">
            {{ auditLogs.length }} records
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-gray-600">
              <tr>
                <th class="text-left p-4 font-semibold">Date</th>
                <th class="text-left p-4 font-semibold">User</th>
                <th class="text-left p-4 font-semibold">Module</th>
                <th class="text-left p-4 font-semibold">Action</th>
                <th class="text-left p-4 font-semibold">Entity</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="log in auditLogs"
                :key="log.id"
                class="border-t border-gray-100 hover:bg-gray-50"
              >
                <td class="p-4 whitespace-nowrap">
                  {{ formatDate(log.created_at) }}
                </td>

                <td class="p-4">
                  {{ log.user_id || "-" }}
                </td>

                <td class="p-4">
                  <span class="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-xs font-semibold">
                    {{ log.module || "system" }}
                  </span>
                </td>

                <td class="p-4 font-medium text-gray-900">
                  {{ log.action }}
                </td>

                <td class="p-4">
                  {{ log.entity_type || "-" }}
                </td>
              </tr>

              <tr v-if="auditLogs.length === 0">
                <td colspan="5" class="p-6 text-center text-gray-500">
                  No audit logs found.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>