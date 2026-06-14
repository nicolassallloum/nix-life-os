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
  color: #e5e7eb;
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
  color: #f8fafc;
}

.page-header p {
  margin: 6px 0 0;
  color: #94a3b8;
}

.primary-btn {
  border: none;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  color: #ffffff;
  padding: 11px 18px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 0 10px 24px rgba(37, 99, 235, 0.25);
}

.settings-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 18px;
}

.content-card {
  background: #0f172a;
  border: 1px solid rgba(148, 163, 184, 0.28);
  border-radius: 18px;
  padding: 24px;
  box-shadow: 0 18px 45px rgba(0, 0, 0, 0.28);
}

.content-card h2 {
  margin: 0 0 12px;
  color: #f8fafc;
  font-size: 20px;
  font-weight: 900;
}

.setting-row,
.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 18px;
  padding: 18px 0;
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
}

.setting-row:last-child,
.status-item:last-child {
  border-bottom: none;
}

.setting-row strong,
.status-item span {
  color: #e5e7eb;
  font-weight: 800;
}

.setting-row p {
  margin: 5px 0 0;
  color: #94a3b8;
  font-size: 14px;
  line-height: 1.55;
}

.setting-row input[type='checkbox'] {
  width: 46px;
  height: 24px;
  min-width: 46px;
  cursor: pointer;
  accent-color: #2563eb;
}

.ok {
  color: #22c55e;
}

.pending {
  color: #f59e0b;
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
