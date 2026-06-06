<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1>Profile</h1>
        <p>View and manage your personal profile information.</p>
      </div>
      <button class="primary-btn">Edit Profile</button>
    </div>

    <div class="profile-layout">
      <div class="profile-card">
        <div class="avatar">N</div>
        <h2>Nix</h2>
        <p>Nix Life OS User</p>

        <div class="profile-meta">
          <div>
            <span>Status</span>
            <strong>Active</strong>
          </div>
          <div>
            <span>Plan</span>
            <strong>Personal OS</strong>
          </div>
        </div>
      </div>

      <div class="content-card">
        <h2>Profile Details</h2>

        <div class="info-row">
          <span>Name</span>
          <strong>Nix</strong>
        </div>

        <div class="info-row">
          <span>Email</span>
          <strong>Connected User</strong>
        </div>

        <div class="info-row">
          <span>Role</span>
          <strong>Application Owner / User</strong>
        </div>

        <div class="info-row">
          <span>Modules</span>
          <strong>Finance, Health, Projects, Productivity</strong>
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

.profile-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 18px;
}

.profile-card,
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 24px;
  box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06);
}

.profile-card {
  text-align: center;
}

.avatar {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  background: #2563eb;
  color: white;
  display: grid;
  place-items: center;
  font-size: 36px;
  font-weight: 800;
  margin: 0 auto 16px;
}

.profile-card h2 {
  margin: 0;
}

.profile-card p {
  color: #6b7280;
}

.profile-meta {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 20px;
}

.profile-meta div {
  background: #f8fafc;
  border-radius: 14px;
  padding: 14px;
}

.profile-meta span,
.info-row span {
  display: block;
  color: #6b7280;
  font-size: 13px;
}

.profile-meta strong,
.info-row strong {
  display: block;
  margin-top: 5px;
  color: #111827;
}

.info-row {
  padding: 16px 0;
  border-bottom: 1px solid #f1f5f9;
}

.info-row:last-child {
  border-bottom: none;
}

@media (max-width: 900px) {
  .profile-layout {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
