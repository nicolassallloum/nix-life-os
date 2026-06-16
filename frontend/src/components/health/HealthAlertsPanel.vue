<template>
  <section class="alerts-panel">
    <div class="alerts-header">
      <div>
        <h2>Health Alerts</h2>
        <p>Important warnings and health trends detected by Nix Life OS.</p>
      </div>

      <button class="run-btn" @click="runAlertsEngine" :disabled="loading">
        {{ loading ? "Checking..." : "Run Check" }}
      </button>
    </div>

    <div v-if="summary" class="alert-summary">
      <div class="summary-card critical">
        <strong>{{ summary.critical_count }}</strong>
        <span>Critical</span>
      </div>

      <div class="summary-card warning">
        <strong>{{ summary.warning_count }}</strong>
        <span>Warnings</span>
      </div>

      <div class="summary-card active">
        <strong>{{ summary.active_count }}</strong>
        <span>Active</span>
      </div>

      <div class="summary-card unread">
        <strong>{{ summary.unread_count }}</strong>
        <span>Unread</span>
      </div>
    </div>

    <div class="filters">
      <select v-model="filters.status" @change="loadAlerts">
        <option value="">All Status</option>
        <option value="active">Active</option>
        <option value="read">Read</option>
        <option value="resolved">Resolved</option>
        <option value="dismissed">Dismissed</option>
      </select>

      <select v-model="filters.severity" @change="loadAlerts">
        <option value="">All Severity</option>
        <option value="critical">Critical</option>
        <option value="warning">Warning</option>
        <option value="info">Info</option>
      </select>

      <select v-model="filters.category" @change="loadAlerts">
        <option value="">All Categories</option>
        <option value="nutrition">Nutrition</option>
        <option value="hydration">Hydration</option>
        <option value="weight">Weight</option>
        <option value="medication">Medication</option>
        <option value="lab_test">Lab Test</option>
        <option value="activity">Activity</option>
        <option value="sleep">Sleep</option>
        <option value="pattern">Pattern</option>
      </select>
    </div>

    <div v-if="loading" class="state-box">
      Loading health alerts...
    </div>

    <div v-else-if="error" class="state-box error">
      {{ error }}
    </div>

    <div v-else-if="alerts.length === 0" class="state-box empty">
      No health alerts found.
    </div>

    <div v-else class="alerts-list">
      <article
        v-for="alert in alerts"
        :key="alert.id"
        class="alert-card"
        :class="alert.severity"
      >
        <div class="alert-top">
          <div>
            <span class="badge" :class="alert.severity">
              {{ alert.severity }}
            </span>

            <span class="category">
              {{ formatCategory(alert.category) }}
            </span>
          </div>

          <span class="date">
            {{ formatDate(alert.alert_date || alert.created_at) }}
          </span>
        </div>

        <h3>{{ alert.title }}</h3>
        <p>{{ alert.message }}</p>

        <div class="alert-actions">
          <button @click="markAsRead(alert.id)">Read</button>
          <button @click="resolveAlert(alert.id)">Resolve</button>
          <button @click="dismissAlert(alert.id)">Dismiss</button>
        </div>
      </article>
    </div>
  </section>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { healthAlertService } from "@/services/healthAlertService";

const loading = ref(false);
const error = ref("");
const alerts = ref([]);
const summary = ref(null);

const filters = ref({
  status: "active",
  severity: "",
  category: "",
});

const loadSummary = async () => {
  const response = await healthAlertService.getSummary();
  summary.value = response.data;
};

const loadAlerts = async () => {
  loading.value = true;
  error.value = "";

  try {
    const response = await healthAlertService.getAlerts(filters.value);
    alerts.value = response.data.data || response.data || [];
  } catch (err) {
    error.value = "Failed to load health alerts.";
  } finally {
    loading.value = false;
  }
};

const runAlertsEngine = async () => {
  loading.value = true;
  error.value = "";

  try {
    await healthAlertService.runEngine();
    await loadSummary();
    await loadAlerts();
  } catch (err) {
    error.value = "Failed to run health alerts engine.";
  } finally {
    loading.value = false;
  }
};

const markAsRead = async (id) => {
  await healthAlertService.markAsRead(id);
  await loadSummary();
  await loadAlerts();
};

const resolveAlert = async (id) => {
  await healthAlertService.resolve(id);
  await loadSummary();
  await loadAlerts();
};

const dismissAlert = async (id) => {
  await healthAlertService.dismiss(id);
  await loadSummary();
  await loadAlerts();
};

const formatCategory = (category) => {
  return String(category || "")
    .replace("_", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
};

const formatDate = (value) => {
  if (!value) return "-";
  return new Date(value).toLocaleDateString();
};

onMounted(async () => {
  await loadSummary();
  await loadAlerts();
});
</script>

<style scoped>
.alerts-panel {
  background: #ffffff;
  border-radius: 18px;
  padding: 24px;
  border: 1px solid #e5e7eb;
}

.alerts-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 20px;
}

.alerts-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
}

.alerts-header p {
  color: #6b7280;
  margin-top: 4px;
}

.run-btn {
  background: #2563eb;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 10px;
  cursor: pointer;
}

.run-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.alert-summary {
  display: grid;
  grid-template-columns: repeat(4, minmax(120px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}

.summary-card {
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
}

.summary-card strong {
  display: block;
  font-size: 26px;
  color: #111827;
}

.summary-card span {
  color: #6b7280;
}

.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filters select {
  padding: 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
}

.state-box {
  padding: 18px;
  border-radius: 12px;
  background: #f3f4f6;
  color: #374151;
}

.state-box.error {
  background: #fee2e2;
  color: #991b1b;
}

.state-box.empty {
  background: #ecfdf5;
  color: #065f46;
}

.alerts-list {
  display: grid;
  gap: 14px;
}

.alert-card {
  padding: 18px;
  border-radius: 16px;
  border: 1px solid #e5e7eb;
  background: #ffffff;
}

.alert-card.critical {
  border-left: 6px solid #dc2626;
}

.alert-card.warning {
  border-left: 6px solid #f59e0b;
}

.alert-card.info {
  border-left: 6px solid #2563eb;
}

.alert-top {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.badge {
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  text-transform: uppercase;
  font-weight: 700;
}

.badge.critical {
  background: #fee2e2;
  color: #991b1b;
}

.badge.warning {
  background: #fef3c7;
  color: #92400e;
}

.badge.info {
  background: #dbeafe;
  color: #1d4ed8;
}

.category {
  margin-left: 8px;
  color: #6b7280;
  font-size: 13px;
}

.date {
  color: #6b7280;
  font-size: 13px;
}

.alert-card h3 {
  font-size: 18px;
  color: #111827;
  margin-bottom: 6px;
}

.alert-card p {
  color: #4b5563;
}

.alert-actions {
  display: flex;
  gap: 8px;
  margin-top: 14px;
}

.alert-actions button {
  border: 1px solid #d1d5db;
  background: #ffffff;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
}

/* Step 37: force readable Health Alerts buttons */
.health-alerts-panel button,
.alerts-panel button,
.alert-actions button,
.actions button,
button {
  color: #0f172a;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  font-weight: 700;
}

.health-alerts-panel button:hover,
.alerts-panel button:hover,
.alert-actions button:hover,
.actions button:hover,
button:hover {
  background: #f8fafc;
  color: #0f172a;
}

.health-alerts-panel button:disabled,
.alerts-panel button:disabled,
.alert-actions button:disabled,
.actions button:disabled,
button:disabled {
  color: #64748b;
  background: #e2e8f0;
  cursor: not-allowed;
  opacity: 0.75;
}

.health-alerts-panel .primary-btn,
.health-alerts-panel .run-btn,
.health-alerts-panel .refresh-btn,
.alerts-panel .primary-btn,
.alerts-panel .run-btn,
.alerts-panel .refresh-btn,
button.primary-btn,
button.run-btn,
button.refresh-btn {
  color: #ffffff;
  background: #0f172a;
  border-color: #0f172a;
}

.health-alerts-panel .primary-btn:hover,
.health-alerts-panel .run-btn:hover,
.health-alerts-panel .refresh-btn:hover,
.alerts-panel .primary-btn:hover,
.alerts-panel .run-btn:hover,
.alerts-panel .refresh-btn:hover,
button.primary-btn:hover,
button.run-btn:hover,
button.refresh-btn:hover {
  color: #ffffff;
  background: #1e293b;
}

.health-alerts-panel .read-btn,
.health-alerts-panel .resolve-btn,
.health-alerts-panel .dismiss-btn,
.health-alerts-panel .delete-btn,
.alerts-panel .read-btn,
.alerts-panel .resolve-btn,
.alerts-panel .dismiss-btn,
.alerts-panel .delete-btn,
button.read-btn,
button.resolve-btn,
button.dismiss-btn,
button.delete-btn {
  color: #0f172a;
  background: #ffffff;
  border-color: #cbd5e1;
}

.health-alerts-panel .resolve-btn,
.alerts-panel .resolve-btn,
button.resolve-btn {
  color: #166534;
  background: #dcfce7;
  border-color: #86efac;
}

.health-alerts-panel .dismiss-btn,
.alerts-panel .dismiss-btn,
button.dismiss-btn {
  color: #92400e;
  background: #fef3c7;
  border-color: #fde68a;
}

.health-alerts-panel .delete-btn,
.alerts-panel .delete-btn,
button.delete-btn {
  color: #991b1b;
  background: #fee2e2;
  border-color: #fecaca;
}

</style>
