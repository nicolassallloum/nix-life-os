<template>
  <main class="system-page">
    <img
      class="system-image"
      src="/images/system/page-under-construction.png"
      alt="Nix Life OS Under Construction"
    />

    <RouterLink to="/" class="dashboard-btn">
      Back to Dashboard
    </RouterLink>
  </main>
</template>

<script setup lang="ts">
</script>

<style scoped>
.system-page {
  min-height: 100vh;
  width: 100%;
  background: #020617;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.system-image {
  width: 100%;
  height: 100vh;
  object-fit: cover;
  display: block;
}

.dashboard-btn {
  position: absolute;
  left: 50%;
  bottom: 11%;
  transform: translateX(-50%);
  min-width: 260px;
  height: 58px;
  padding: 0 28px;
  border-radius: 16px;
  background: linear-gradient(135deg, #00d9ff, #7c3aed);
  color: #ffffff;
  font-size: 18px;
  font-weight: 700;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 28px rgba(0, 217, 255, 0.45);
}

.dashboard-btn:hover {
  transform: translateX(-50%) translateY(-2px);
  box-shadow: 0 0 38px rgba(124, 58, 237, 0.65);
}

@media (max-width: 768px) {
  .system-image {
    object-fit: contain;
    background: #020617;
  }

  .dashboard-btn {
    bottom: 7%;
    min-width: 220px;
    height: 52px;
    font-size: 15px;
  }
}
</style>