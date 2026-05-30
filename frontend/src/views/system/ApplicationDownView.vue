<template>
  <main class="system-page">
    <img
      class="system-image"
      src="/images/system/application-down.png"
      alt="Nix Life OS Application Temporarily Down"
    />

    <div class="actions">
      <button type="button" class="retry-btn" @click="retryPage">
        Retry
      </button>

      <RouterLink to="/" class="home-btn">
        Back to Home
      </RouterLink>
    </div>
  </main>
</template>

<script setup lang="ts">
const retryPage = () => {
  window.location.reload()
}
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

.actions {
  position: absolute;
  left: 34%;
  bottom: 13%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  gap: 18px;
  width: 360px;
}

.retry-btn,
.home-btn {
  height: 58px;
  border-radius: 16px;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.retry-btn {
  border: 1px solid rgba(0, 217, 255, 0.7);
  background: linear-gradient(135deg, #00d9ff, #7c3aed);
  color: #ffffff;
  box-shadow: 0 0 28px rgba(0, 217, 255, 0.45);
}

.home-btn {
  border: 1px solid rgba(0, 217, 255, 0.45);
  background: rgba(2, 6, 23, 0.55);
  color: #bfdbfe;
  backdrop-filter: blur(10px);
}

.retry-btn:hover,
.home-btn:hover {
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .system-image {
    object-fit: contain;
    background: #020617;
  }

  .actions {
    left: 50%;
    bottom: 7%;
    width: 260px;
    gap: 12px;
  }

  .retry-btn,
  .home-btn {
    height: 50px;
    font-size: 15px;
  }
}
</style>