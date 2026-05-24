<template>
  <div
    v-if="offlineStore.shouldShowSyncWarning"
    class="pending-sync-panel"
  >
    <div class="pending-sync-panel__header">
      <div>
        <h3>Offline Sync Status</h3>
        <p>
          Some local changes are waiting for synchronization.
        </p>
      </div>

      <button
        type="button"
        class="pending-sync-panel__refresh"
        @click="refreshCounts"
      >
        Refresh
      </button>
    </div>

    <div class="pending-sync-panel__grid">
      <div class="pending-sync-panel__item pending">
        <span class="pending-sync-panel__label">Pending</span>
        <strong>{{ offlineStore.pendingSyncCount }}</strong>
      </div>

      <div class="pending-sync-panel__item failed">
        <span class="pending-sync-panel__label">Failed</span>
        <strong>{{ offlineStore.failedSyncCount }}</strong>
      </div>

      <div class="pending-sync-panel__item conflict">
        <span class="pending-sync-panel__label">Conflicts</span>
        <strong>{{ offlineStore.conflictSyncCount }}</strong>
      </div>
    </div>

    <div class="pending-sync-panel__footer">
      <span v-if="offlineStore.lastSyncCheckAt">
        Last checked: {{ formattedLastChecked }}
      </span>

      <RouterLink
        to="/offline/sync-center"
        class="pending-sync-panel__link"
      >
        Open Sync Center
      </RouterLink>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { useOfflineStore } from '@/stores/offline.store'

const offlineStore = useOfflineStore()

const formattedLastChecked = computed(() => {
  if (!offlineStore.lastSyncCheckAt) {
    return 'Not checked yet'
  }

  return new Date(offlineStore.lastSyncCheckAt).toLocaleString()
})

onMounted(async () => {
  await offlineStore.refreshSyncCounts()
})

async function refreshCounts() {
  await offlineStore.refreshSyncCounts()
}
</script>

<style scoped>
.pending-sync-panel {
  margin: 16px 0;
  padding: 18px;
  border-radius: 20px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  box-shadow: 0 16px 40px rgba(15, 23, 42, 0.08);
}

.pending-sync-panel__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.pending-sync-panel__header h3 {
  margin: 0;
  color: #0f172a;
  font-size: 18px;
  font-weight: 800;
}

.pending-sync-panel__header p {
  margin: 4px 0 0;
  color: #64748b;
  font-size: 14px;
}

.pending-sync-panel__refresh {
  border: 0;
  border-radius: 999px;
  padding: 9px 14px;
  font-weight: 700;
  color: white;
  cursor: pointer;
  background: linear-gradient(135deg, #0891b2, #7c3aed);
}

.pending-sync-panel__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.pending-sync-panel__item {
  padding: 14px;
  border-radius: 16px;
  border: 1px solid transparent;
}

.pending-sync-panel__item strong {
  display: block;
  margin-top: 6px;
  font-size: 24px;
  color: #0f172a;
}

.pending-sync-panel__label {
  font-size: 13px;
  font-weight: 700;
}

.pending-sync-panel__item.pending {
  background: #fffbeb;
  border-color: #fcd34d;
  color: #92400e;
}

.pending-sync-panel__item.failed {
  background: #fee2e2;
  border-color: #fca5a5;
  color: #991b1b;
}

.pending-sync-panel__item.conflict {
  background: #ffedd5;
  border-color: #fdba74;
  color: #7c2d12;
}

.pending-sync-panel__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-top: 14px;
  color: #64748b;
  font-size: 13px;
}

.pending-sync-panel__link {
  color: #2563eb;
  font-weight: 800;
  text-decoration: none;
}

.pending-sync-panel__link:hover {
  text-decoration: underline;
}

@media (max-width: 720px) {
  .pending-sync-panel__header,
  .pending-sync-panel__footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .pending-sync-panel__grid {
    grid-template-columns: 1fr;
  }

  .pending-sync-panel__refresh {
    width: 100%;
  }
}
</style>
