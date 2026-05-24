<template>
  <transition name="offline-banner">
    <div
      v-if="offlineStore.shouldShowOfflineBanner"
      class="offline-banner"
      role="status"
      aria-live="polite"
    >
      <div class="offline-banner__content">
        <div class="offline-banner__icon">
          ⚠️
        </div>

        <div class="offline-banner__message">
          <strong>You are offline.</strong>
          <span>
            Selected features are still available. New health and finance entries will sync when internet returns.
          </span>
        </div>
      </div>

      <button
        type="button"
        class="offline-banner__close"
        aria-label="Dismiss offline banner"
        @click="offlineStore.dismissOfflineBanner"
      >
        ×
      </button>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useOfflineStore } from '@/stores/offline.store'

const offlineStore = useOfflineStore()

onMounted(() => {
  offlineStore.initialize()
})
</script>

<style scoped>
.offline-banner {
  position: sticky;
  top: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  width: 100%;
  padding: 12px 20px;
  background: linear-gradient(135deg, #92400e, #b45309);
  color: #fff7ed;
  border-bottom: 1px solid rgba(255, 255, 255, 0.16);
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.18);
}

.offline-banner__content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.offline-banner__icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.18);
  font-size: 16px;
  flex-shrink: 0;
}

.offline-banner__message {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 14px;
  line-height: 1.4;
}

.offline-banner__message strong {
  font-size: 14px;
  font-weight: 700;
}

.offline-banner__message span {
  opacity: 0.94;
}

.offline-banner__close {
  border: none;
  background: rgba(255, 255, 255, 0.16);
  color: #ffffff;
  width: 30px;
  height: 30px;
  border-radius: 999px;
  cursor: pointer;
  font-size: 22px;
  line-height: 1;
  transition:
    background 0.2s ease,
    transform 0.2s ease;
}

.offline-banner__close:hover {
  background: rgba(255, 255, 255, 0.26);
  transform: scale(1.04);
}

.offline-banner-enter-active,
.offline-banner-leave-active {
  transition:
    opacity 0.2s ease,
    transform 0.2s ease;
}

.offline-banner-enter-from,
.offline-banner-leave-to {
  opacity: 0;
  transform: translateY(-12px);
}

@media (max-width: 640px) {
  .offline-banner {
    align-items: flex-start;
    padding: 12px 14px;
  }

  .offline-banner__message {
    font-size: 13px;
  }
}
</style>
