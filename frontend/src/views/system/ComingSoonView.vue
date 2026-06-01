<template>
  <main class="coming-soon-page">
    <img
      src="/images/system/coming-soon-nix-life-os.png"
      alt="Nix Life OS Coming Soon"
      class="coming-soon-image"
    />
  </main>
</template>

<script setup lang="ts">
</script>

<style scoped>
.coming-soon-page {
  min-height: 100vh;
  width: 100%;
  background: #020617;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}

.coming-soon-image {
  width: 100%;
  max-width: 430px;
  min-height: 100vh;
  object-fit: cover;
  display: block;
}

@media (min-width: 768px) {
  .coming-soon-image {
    max-width: 430px;
    border-left: 1px solid rgba(56, 189, 248, 0.25);
    border-right: 1px solid rgba(168, 85, 247, 0.25);
    box-shadow: 0 0 60px rgba(59, 130, 246, 0.25);
  }
}
</style>