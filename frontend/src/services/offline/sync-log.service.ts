import {
  getOfflineDB,
  type SyncLog,
  type SyncStatus,
} from './offline-db'

export interface CreateSyncLogInput {
  user_id: string
  queue_id?: string | null
  entity_type?: string | null
  entity_local_id?: string | null
  status: SyncStatus
  message: string
}

function generateId(prefix = 'sync-log'): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return `${prefix}-${crypto.randomUUID()}`
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

function nowIso(): string {
  return new Date().toISOString()
}

export const syncLogService = {
  async add(input: CreateSyncLogInput): Promise<SyncLog> {
    const db = await getOfflineDB()

    const log: SyncLog = {
      id: generateId(),
      user_id: input.user_id,
      queue_id: input.queue_id ?? null,
      entity_type: input.entity_type ?? null,
      entity_local_id: input.entity_local_id ?? null,
      status: input.status,
      message: input.message,
      created_at: nowIso(),
    }

    await db.put('sync_logs', log)

    return log
  },

  async listByUser(userId: string): Promise<SyncLog[]> {
    const db = await getOfflineDB()
    const logs = await db.getAllFromIndex('sync_logs', 'by-user', userId)

    return logs.sort((a, b) => {
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    })
  },

  async listByStatus(status: SyncStatus): Promise<SyncLog[]> {
    const db = await getOfflineDB()
    const logs = await db.getAllFromIndex('sync_logs', 'by-status', status)

    return logs.sort((a, b) => {
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    })
  },

  async getLatestByUser(userId: string, limit = 20): Promise<SyncLog[]> {
    const logs = await this.listByUser(userId)
    return logs.slice(0, limit)
  },

  async clearByUser(userId: string): Promise<void> {
    const db = await getOfflineDB()
    const tx = db.transaction('sync_logs', 'readwrite')
    const index = tx.store.index('by-user')

    for await (const cursor of index.iterate(userId)) {
      await cursor.delete()
    }

    await tx.done
  },

  async clearOldLogs(userId: string, keepLatest = 100): Promise<void> {
    const logs = await this.listByUser(userId)

    if (logs.length <= keepLatest) {
      return
    }

    const logsToDelete = logs.slice(keepLatest)
    const db = await getOfflineDB()
    const tx = db.transaction('sync_logs', 'readwrite')

    for (const log of logsToDelete) {
      await tx.store.delete(log.id)
    }

    await tx.done
  },
}
