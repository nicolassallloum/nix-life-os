<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1>Settings</h1>
        <p>Manage application preferences, notifications, privacy, and account options.</p>
      </div>
      <button class="primary-btn">Save Settings</button>
    </div>

    <div class="settings-grid">
      <div class="content-card">
        <h2>Application Settings</h2>

        <div class="setting-row">
          <div>
            <strong>Dark Mode</strong>
            <p>Enable dark appearance for the application.</p>
          </div>
          <input type="checkbox" />
        </div>

        <div class="setting-row">
          <div>
            <strong>Notifications</strong>
            <p>Receive reminders and important alerts.</p>
          </div>
          <input type="checkbox" checked />
        </div>

        <div class="setting-row">
          <div>
            <strong>Email Updates</strong>
            <p>Receive weekly summaries and progress reports.</p>
          </div>
          <input type="checkbox" />
        </div>
      </div>

      <div class="content-card">
        <h2>System Status</h2>

        <div class="status-item">
          <span>Frontend</span>
          <strong class="ok">Ready</strong>
        </div>

        <div class="status-item">
          <span>Backend API</span>
          <strong class="pending">Pending Integration</strong>
        </div>

        <div class="status-item">
          <span>User Preferences</span>
          <strong class="pending">Coming Soon</strong>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
</script>

<style scoped>
.page {
  padding: 24px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  color: #111827;
}

.page-header p {
  margin: 6px 0 0;
  color: #6b7280;
}

.primary-btn {
  border: none;
  background: #2563eb;
  color: white;
  padding: 11px 18px;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
}

.settings-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 18px;
}

.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 20px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.content-card h2 {
  margin-top: 0;
}

.setting-row,
.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 14px;
  padding: 16px 0;
  border-bottom: 1px solid #f1f5f9;
}

.setting-row:last-child,
.status-item:last-child {
  border-bottom: none;
}

.setting-row p {
  margin: 4px 0 0;
  color: #6b7280;
  font-size: 14px;
}

.ok {
  color: #16a34a;
}

.pending {
  color: #d97706;
}

@media (max-width: 900px) {
  .settings-grid {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
