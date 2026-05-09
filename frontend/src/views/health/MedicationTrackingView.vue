<template>
  <div class="medication-page">
    <div class="page-header">
      <h1>Medication Tracking</h1>
      <p>Track your medications, dosage, frequency, dates, status, and notes.</p>
    </div>

    <div class="card">
      <h2>Medication Page Loaded Successfully</h2>
      <p>If you can see this page, the Vue route is working correctly.</p>
    </div>
  </div>
</template>

<script setup>
</script>

<style scoped>
.medication-page {
  padding: 24px;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 8px;
}

.page-header p {
  color: #6b7280;
  font-size: 15px;
}

.card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
}

.card h2 {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 8px;
}

.card p {
  color: #4b5563;
}
</style>
