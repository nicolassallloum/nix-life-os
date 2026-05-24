<template>
  <main class="sync-center-page">
    <section class="sync-center-hero">
      <div>
        <p class="sync-center-eyebrow">Offline Mode</p>
        <h1>Sync Center</h1>
        <p>
          Review pending, failed, and conflicted offline changes before they are synchronized with Nix Life OS.
        </p>
      </div>

      <button
        type="button"
        class="sync-center-refresh"
        @click="loadData"
      >
        Refresh
      </button>
    </section>

    <section class="sync-center-summary">
      <div class="summary-card pending">
        <span>Pending</span>
        <strong>{{ pendingItems.length }}</strong>
      </div>

      <div class="summary-card failed">
        <span>Failed</span>
        <strong>{{ failedItems.length }}</strong>
      </div>

      <div class="summary-card conflict">
        <span>Conflicts</span>
        <strong>{{ conflictItems.length }}</strong>
      </div>
    </section>

    <section class="sync-center-section">
      <div class="section-header">
        <h2>Pending Sync</h2>
        <p>These items are waiting for connection or sync processing.</p>
      </div>

      <div
        v-if="pendingItems.length === 0"
        class="empty-card"
      >
        No pending sync items.
      </div>

      <div
        v-else
        class="sync-list"
      >
        <article
          v-for="item in pendingItems"
          :key="item.id"
          class="sync-item"
        >
          <div>
            <div class="sync-item-title">
              {{ formatEntityType(item.entity_type) }}
              <SyncStatusBadge :status="item.status" />
            </div>

            <p>
              {{ item.method }} {{ item.endpoint }}
            </p>

            <small>
              Created: {{ formatDate(item.created_at) }}
            </small>
          </div>

          <button
            type="button"
            class="secondary-button"
            @click="retryItem(item.id)"
          >
            Retry
          </button>
        </article>
      </div>
    </section>

    <section class="sync-center-section">
      <div class="section-header">
        <h2>Failed Sync</h2>
        <p>These items failed and can be retried after review.</p>
      </div>

      <div
        v-if="failedItems.length === 0"
        class="empty-card"
      >
        No failed sync items.
      </div>

      <div
        v-else
        class="sync-list"
      >
        <article
          v-for="item in failedItems"
          :key="item.id"
          class="sync-item"
        >
          <div>
            <div class="sync-item-title">
              {{ formatEntityType(item.entity_type) }}
              <SyncStatusBadge :status="item.status" />
            </div>

            <p>
              {{ item.last_error || 'Unknown sync error.' }}
            </p>

            <small>
              Retries: {{ item.retry_count }} / {{ item.max_retries }}
            </small>
          </div>

          <button
            type="button"
            class="secondary-button"
            @click="retryItem(item.id)"
          >
            Retry
          </button>
        </article>
      </div>
    </section>

    <section class="sync-center-section">
      <div class="section-header">
        <h2>Conflicts</h2>
        <p>These items need manual review before syncing.</p>
      </div>

      <div
        v-if="conflictItems.length === 0"
        class="empty-card"
      >
        No sync conflicts.
      </div>

      <div
        v-else
        class="sync-list"
      >
        <article
          v-for="item in conflictItems"
          :key="item.id"
          class="sync-item conflict-item"
        >
          <div>
            <div class="sync-item-title">
              {{ formatEntityType(item.entity_type) }}
              <SyncStatusBadge :status="item.status" />
            </div>

            <p>
              {{ item.last_error || 'This item requires manual review.' }}
            </p>

            <small>
              Local ID: {{ item.entity_local_id }}
            </small>
          </div>

          <button
            type="button"
            class="danger-button"
            @click="discardItem(item.id)"
          >
            Discard
          </button>
        </article>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import SyncStatusBadge from '@/components/offline/SyncStatusBadge.vue'
import {
  syncQueueService,
  type QueueEntityType,
} from '@/services/offline/sync-queue.service'
import type { SyncQueueItem } from '@/services/offline/offline-db'
import { useOfflineStore } from '@/stores/offline.store'

const offlineStore = useOfflineStore()

const pendingItems = ref<SyncQueueItem[]>([])
const failedItems = ref<SyncQueueItem[]>([])
const conflictItems = ref<SyncQueueItem[]>([])

onMounted(async () => {
  await loadData()
})

async function loadData() {
  const userId = offlineStore.currentUserId ?? undefined

  pendingItems.value = await syncQueueService.listPending(userId)
  failedItems.value = await syncQueueService.listFailed(userId)
  conflictItems.value = await syncQueueService.listConflicts(userId)

  await offlineStore.refreshSyncCounts()
}

async function retryItem(id: string) {
  await syncQueueService.resetForRetry(id)
  await loadData()
}

async function discardItem(id: string) {
  await syncQueueService.remove(id)
  await loadData()
}

function formatDate(value: string): string {
  return new Date(value).toLocaleString()
}

function formatEntityType(entityType: QueueEntityType): string {
  const labels: Record<QueueEntityType, string> = {
    health_steps: 'Health Steps',
    health_weight: 'Health Weight',
    health_hydration: 'Health Hydration',
    health_nutrition: 'Health Nutrition',
    finance_transactions: 'Finance Transaction',
  }

  return labels[entityType] ?? entityType
}
</script>

<style scoped>
.sync-center-page {
  min-height: 100vh;
  padding: 32px;
  background: #f8fafc;
}

.sync-center-hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 24px;
  padding: 28px;
  border-radius: 28px;
  background:
    radial-gradient(circle at top right, rgba(34, 211, 238, 0.18), transparent 32%),
    linear-gradient(135deg, #0f172a, #1e1b4b);
  color: #f8fafc;
  box-shadow: 0 24px 70px rgba(15, 23, 42, 0.25);
}

.sync-center-eyebrow {
  margin: 0 0 8px;
  color: #67e8f9;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.sync-center-hero h1 {
  margin: 0;
  font-size: 34px;
  font-weight: 900;
}

.sync-center-hero p {
  max-width: 720px;
  margin: 10px 0 0;
  color: #cbd5e1;
  line-height: 1.7;
}

.sync-center-refresh,
.secondary-button,
.danger-button {
  border: 0;
  border-radius: 999px;
  padding: 10px 16px;
  font-weight: 800;
  cursor: pointer;
}

.sync-center-refresh {
  color: #0f172a;
  background: linear-gradient(135deg, #22d3ee, #a78bfa);
}

.sync-center-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin: 24px 0;
}

.summary-card {
  padding: 20px;
  border-radius: 22px;
  border: 1px solid transparent;
  background: #ffffff;
  box-shadow: 0 16px 38px rgba(15, 23, 42, 0.08);
}

.summary-card span {
  display: block;
  font-size: 13px;
  font-weight: 800;
}

.summary-card strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 34px;
  font-weight: 900;
}

.summary-card.pending {
  color: #92400e;
  border-color: #fcd34d;
  background: #fffbeb;
}

.summary-card.failed {
  color: #991b1b;
  border-color: #fca5a5;
  background: #fee2e2;
}

.summary-card.conflict {
  color: #7c2d12;
  border-color: #fdba74;
  background: #ffedd5;
}

.sync-center-section {
  margin-top: 22px;
  padding: 22px;
  border-radius: 24px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  box-shadow: 0 16px 38px rgba(15, 23, 42, 0.06);
}

.section-header h2 {
  margin: 0;
  color: #0f172a;
  font-size: 22px;
  font-weight: 900;
}

.section-header p {
  margin: 6px 0 16px;
  color: #64748b;
}

.empty-card {
  padding: 18px;
  border-radius: 18px;
  background: #f8fafc;
  color: #64748b;
  border: 1px dashed #cbd5e1;
}

.sync-list {
  display: grid;
  gap: 12px;
}

.sync-item {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  padding: 16px;
  border-radius: 18px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.sync-item-title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  color: #0f172a;
  font-weight: 900;
}

.sync-item p {
  margin: 8px 0;
  color: #475569;
  word-break: break-word;
}

.sync-item small {
  color: #64748b;
}

.secondary-button {
  color: #ffffff;
  background: linear-gradient(135deg, #0891b2, #7c3aed);
  align-self: center;
}

.danger-button {
  color: #ffffff;
  background: linear-gradient(135deg, #dc2626, #991b1b);
  align-self: center;
}

.conflict-item {
  border-color: #fdba74;
}

@media (max-width: 760px) {
  .sync-center-page {
    padding: 18px;
  }

  .sync-center-hero,
  .sync-item {
    flex-direction: column;
  }

  .sync-center-summary {
    grid-template-columns: 1fr;
  }

  .sync-center-refresh,
  .secondary-button,
  .danger-button {
    width: 100%;
  }
}
</style>
