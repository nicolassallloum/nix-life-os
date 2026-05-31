<template>
  <div class="error-image-page">
    <img
      :src="imageSrc"
      :alt="alt"
      class="error-image"
    />

    <div v-if="showButtons" class="error-actions">
      <button class="primary-btn" @click="$emit('retry')">
        Retry
      </button>

      <button class="secondary-btn" @click="$router.push('/dashboard')">
        Back to Dashboard
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  imageSrc: {
    type: String,
    required: true,
  },
  alt: {
    type: String,
    default: 'Nix Life OS error screen',
  },
  showButtons: {
    type: Boolean,
    default: false,
  },
})

defineEmits(['retry'])
</script>

<style scoped>
.error-image-page {
  width: 100%;
  min-height: 100vh;
  background: #020617;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  overflow: hidden;
}

.error-image {
  width: 100%;
  max-width: 430px;
  height: auto;
  object-fit: contain;
  border-radius: 24px;
  box-shadow: 0 25px 70px rgba(37, 99, 235, 0.25);
}

.error-actions {
  position: fixed;
  bottom: 24px;
  left: 16px;
  right: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.primary-btn,
.secondary-btn {
  width: 100%;
  border: none;
  border-radius: 16px;
  padding: 15px 18px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
}

.primary-btn {
  color: white;
  background: linear-gradient(135deg, #06b6d4, #2563eb, #7c3aed);
}

.secondary-btn {
  color: #dbeafe;
  background: rgba(15, 23, 42, 0.85);
  border: 1px solid rgba(148, 163, 184, 0.25);
}

@media (min-width: 768px) {
  .error-image {
    max-width: 520px;
  }

  .error-actions {
    max-width: 430px;
    margin: 0 auto;
  }
}
</style>