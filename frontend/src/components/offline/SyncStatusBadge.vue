<template>
  <span
    class="sync-status-badge"
    :class="statusClass"
    :title="statusTitle"
  >
    <span class="sync-status-badge__dot"></span>
    {{ statusLabel }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { SyncStatus } from '@/services/offline/offline-db'

const props = defineProps<{
  status: SyncStatus
}>()

const statusLabel = computed(() => {
  switch (props.status) {
    case 'draft':
      return 'Draft'
    case 'pending':
      return 'Pending Sync'
    case 'processing':
      return 'Syncing'
    case 'synced':
      return 'Synced'
    case 'failed':
      return 'Failed'
    case 'conflict':
      return 'Conflict'
    case 'deleted_pending':
      return 'Delete Pending'
    default:
      return 'Unknown'
  }
})

const statusTitle = computed(() => {
  switch (props.status) {
    case 'draft':
      return 'This item is saved locally as a draft.'
    case 'pending':
      return 'This item is waiting to sync.'
    case 'processing':
      return 'This item is currently syncing.'
    case 'synced':
      return 'This item has been synced successfully.'
    case 'failed':
      return 'This item failed to sync.'
    case 'conflict':
      return 'This item needs review before syncing.'
    case 'deleted_pending':
      return 'This item will be deleted when sync completes.'
    default:
      return 'Unknown sync status.'
  }
})

const statusClass = computed(() => {
  return `sync-status-badge--${props.status}`
})
</script>

<style scoped>
.sync-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  width: fit-content;
  padding: 5px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  line-height: 1;
  white-space: nowrap;
  border: 1px solid transparent;
}

.sync-status-badge__dot {
  width: 7px;
  height: 7px;
  border-radius: 999px;
  background: currentColor;
}

.sync-status-badge--draft {
  color: #475569;
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.sync-status-badge--pending {
  color: #92400e;
  background: #fffbeb;
  border-color: #fcd34d;
}

.sync-status-badge--processing {
  color: #075985;
  background: #e0f2fe;
  border-color: #7dd3fc;
}

.sync-status-badge--synced {
  color: #166534;
  background: #dcfce7;
  border-color: #86efac;
}

.sync-status-badge--failed {
  color: #991b1b;
  background: #fee2e2;
  border-color: #fca5a5;
}

.sync-status-badge--conflict {
  color: #7c2d12;
  background: #ffedd5;
  border-color: #fdba74;
}

.sync-status-badge--deleted_pending {
  color: #581c87;
  background: #f3e8ff;
  border-color: #d8b4fe;
}
</style>
