import {
  getOfflineDB,
  type SyncQueueItem,
  type SyncStatus,
} from './offline-db'

export type QueueEntityType =
  | 'health_steps'
  | 'health_weight'
  | 'health_hydration'
  | 'health_nutrition'
  | 'finance_transactions'

export interface CreateQueueItemInput {
  user_id: string
  entity_type: QueueEntityType
  entity_local_id: string
  method: 'POST' | 'PUT' | 'DELETE'
  endpoint: string
  payload: Record<string, unknown>
  priority?: number
  max_retries?: number
}

function generateId(prefix = 'queue'): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return `${prefix}-${crypto.randomUUID()}`
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

function nowIso(): string {
  return new Date().toISOString()
}

export const syncQueueService = {
  async add(input: CreateQueueItemInput): Promise<SyncQueueItem> {
    const db = await getOfflineDB()

    const item: SyncQueueItem = {
      id: generateId(),
      user_id: input.user_id,
      entity_type: input.entity_type,
      entity_local_id: input.entity_local_id,
      method: input.method,
      endpoint: input.endpoint,
      payload: input.payload,
      status: 'pending',
      retry_count: 0,
      max_retries: input.max_retries ?? 3,
      priority: input.priority ?? 5,
      created_at: nowIso(),
      processed_at: null,
      last_error: null,
    }

    await db.put('sync_queue', item)

    return item
  },

  async getById(id: string): Promise<SyncQueueItem | undefined> {
    const db = await getOfflineDB()
    return db.get('sync_queue', id)
  },

  async listByUser(userId: string): Promise<SyncQueueItem[]> {
    const db = await getOfflineDB()
    return db.getAllFromIndex('sync_queue', 'by-user', userId)
  },

  async listByStatus(status: SyncStatus): Promise<SyncQueueItem[]> {
    const db = await getOfflineDB()
    return db.getAllFromIndex('sync_queue', 'by-status', status)
  },

  async listPending(userId?: string): Promise<SyncQueueItem[]> {
    const db = await getOfflineDB()
    const pendingItems = await db.getAllFromIndex('sync_queue', 'by-status', 'pending')

    const filteredItems = userId
      ? pendingItems.filter((item) => item.user_id === userId)
      : pendingItems

    return filteredItems.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority - b.priority
      }

      return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    })
  },

  async listFailed(userId?: string): Promise<SyncQueueItem[]> {
    const db = await getOfflineDB()
    const failedItems = await db.getAllFromIndex('sync_queue', 'by-status', 'failed')

    return userId
      ? failedItems.filter((item) => item.user_id === userId)
      : failedItems
  },

  async listConflicts(userId?: string): Promise<SyncQueueItem[]> {
    const db = await getOfflineDB()
    const conflictItems = await db.getAllFromIndex('sync_queue', 'by-status', 'conflict')

    return userId
      ? conflictItems.filter((item) => item.user_id === userId)
      : conflictItems
  },

  async markProcessing(id: string): Promise<void> {
    await this.updateStatus(id, 'processing')
  },

  async markSynced(id: string): Promise<void> {
    await this.updateStatus(id, 'synced', null, true)
  },

  async markFailed(id: string, errorMessage: string): Promise<void> {
    const db = await getOfflineDB()
    const item = await db.get('sync_queue', id)

    if (!item) {
      return
    }

    const updatedItem: SyncQueueItem = {
      ...item,
      status: 'failed',
      retry_count: item.retry_count + 1,
      last_error: errorMessage,
      processed_at: nowIso(),
    }

    await db.put('sync_queue', updatedItem)
  },

  async markConflict(id: string, errorMessage: string): Promise<void> {
    await this.updateStatus(id, 'conflict', errorMessage, true)
  },

  async resetForRetry(id: string): Promise<void> {
    const db = await getOfflineDB()
    const item = await db.get('sync_queue', id)

    if (!item) {
      return
    }

    const updatedItem: SyncQueueItem = {
      ...item,
      status: 'pending',
      processed_at: null,
      last_error: null,
    }

    await db.put('sync_queue', updatedItem)
  },

  async remove(id: string): Promise<void> {
    const db = await getOfflineDB()
    await db.delete('sync_queue', id)
  },

  async clearSynced(userId?: string): Promise<void> {
    const db = await getOfflineDB()
    const syncedItems = await db.getAllFromIndex('sync_queue', 'by-status', 'synced')

    const itemsToDelete = userId
      ? syncedItems.filter((item) => item.user_id === userId)
      : syncedItems

    const tx = db.transaction('sync_queue', 'readwrite')

    for (const item of itemsToDelete) {
      await tx.store.delete(item.id)
    }

    await tx.done
  },

  async clearByUser(userId: string): Promise<void> {
    const db = await getOfflineDB()
    const tx = db.transaction('sync_queue', 'readwrite')
    const index = tx.store.index('by-user')

    for await (const cursor of index.iterate(userId)) {
      await cursor.delete()
    }

    await tx.done
  },

  async countPending(userId?: string): Promise<number> {
    const items = await this.listPending(userId)
    return items.length
  },

  async hasPending(userId?: string): Promise<boolean> {
    const count = await this.countPending(userId)
    return count > 0
  },

  async canRetry(item: SyncQueueItem): Promise<boolean> {
    return item.retry_count < item.max_retries
  },

  async updateStatus(
    id: string,
    status: SyncStatus,
    errorMessage: string | null = null,
    setProcessedAt = false,
  ): Promise<void> {
    const db = await getOfflineDB()
    const item = await db.get('sync_queue', id)

    if (!item) {
      return
    }

    const updatedItem: SyncQueueItem = {
      ...item,
      status,
      last_error: errorMessage,
      processed_at: setProcessedAt ? nowIso() : item.processed_at,
    }

    await db.put('sync_queue', updatedItem)
  },
}
