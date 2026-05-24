import { openDB, type DBSchema, type IDBPDatabase } from 'idb'

export type SyncStatus =
  | 'draft'
  | 'pending'
  | 'processing'
  | 'synced'
  | 'failed'
  | 'conflict'
  | 'deleted_pending'

export interface CachedApiResponse {
  key: string
  endpoint: string
  data: unknown
  fetched_at: string
  expires_at?: string | null
  user_id: string
}

export interface OfflineHealthSteps {
  local_id: string
  server_id?: string | null
  user_id: string
  date: string
  steps: number
  notes?: string | null
  sync_status: SyncStatus
  created_offline: boolean
  created_at: string
  updated_at: string
  last_error?: string | null
}

export interface OfflineHealthWeight {
  local_id: string
  server_id?: string | null
  user_id: string
  date: string
  weight_kg: number
  notes?: string | null
  sync_status: SyncStatus
  created_offline: boolean
  created_at: string
  updated_at: string
  last_error?: string | null
}

export interface OfflineHealthHydration {
  local_id: string
  server_id?: string | null
  user_id: string
  date: string
  amount_ml: number
  source?: string | null
  sync_status: SyncStatus
  created_offline: boolean
  created_at: string
  updated_at: string
  last_error?: string | null
}

export interface OfflineHealthNutrition {
  local_id: string
  server_id?: string | null
  user_id: string
  date: string
  meal_type?: string | null
  food_name: string
  calories?: number | null
  notes?: string | null
  sync_status: SyncStatus
  created_offline: boolean
  created_at: string
  updated_at: string
  last_error?: string | null
}

export interface OfflineFinanceTransaction {
  local_id: string
  server_id?: string | null
  user_id: string
  account_id: string
  category_id?: string | null
  type: 'income' | 'expense'
  amount: number
  currency: string
  transaction_date: string
  description?: string | null
  sync_status: SyncStatus
  created_offline: boolean
  created_at: string
  updated_at: string
  last_error?: string | null
}

export interface SyncQueueItem {
  id: string
  user_id: string
  entity_type:
    | 'health_steps'
    | 'health_weight'
    | 'health_hydration'
    | 'health_nutrition'
    | 'finance_transactions'
  entity_local_id: string
  method: 'POST' | 'PUT' | 'DELETE'
  endpoint: string
  payload: Record<string, unknown>
  status: SyncStatus
  retry_count: number
  max_retries: number
  priority: number
  created_at: string
  processed_at?: string | null
  last_error?: string | null
}

export interface SyncLog {
  id: string
  user_id: string
  queue_id?: string | null
  entity_type?: string | null
  entity_local_id?: string | null
  status: SyncStatus
  message: string
  created_at: string
}

interface NixLifeOfflineDB extends DBSchema {
  cached_api_responses: {
    key: string
    value: CachedApiResponse
    indexes: {
      'by-user': string
      'by-endpoint': string
    }
  }

  health_steps: {
    key: string
    value: OfflineHealthSteps
    indexes: {
      'by-user': string
      'by-sync-status': SyncStatus
      'by-date': string
    }
  }

  health_weight: {
    key: string
    value: OfflineHealthWeight
    indexes: {
      'by-user': string
      'by-sync-status': SyncStatus
      'by-date': string
    }
  }

  health_hydration: {
    key: string
    value: OfflineHealthHydration
    indexes: {
      'by-user': string
      'by-sync-status': SyncStatus
      'by-date': string
    }
  }

  health_nutrition: {
    key: string
    value: OfflineHealthNutrition
    indexes: {
      'by-user': string
      'by-sync-status': SyncStatus
      'by-date': string
    }
  }

  finance_transactions: {
    key: string
    value: OfflineFinanceTransaction
    indexes: {
      'by-user': string
      'by-sync-status': SyncStatus
      'by-date': string
      'by-account': string
    }
  }

  sync_queue: {
    key: string
    value: SyncQueueItem
    indexes: {
      'by-user': string
      'by-status': SyncStatus
      'by-entity': string
      'by-priority': number
    }
  }

  sync_logs: {
    key: string
    value: SyncLog
    indexes: {
      'by-user': string
      'by-status': SyncStatus
      'by-created-at': string
    }
  }
}

const DB_NAME = 'nixlifeos_offline_db'
const DB_VERSION = 1

let dbPromise: Promise<IDBPDatabase<NixLifeOfflineDB>> | null = null

export function getOfflineDB(): Promise<IDBPDatabase<NixLifeOfflineDB>> {
  if (!dbPromise) {
    dbPromise = openDB<NixLifeOfflineDB>(DB_NAME, DB_VERSION, {
      upgrade(db) {
        if (!db.objectStoreNames.contains('cached_api_responses')) {
          const store = db.createObjectStore('cached_api_responses', {
            keyPath: 'key',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-endpoint', 'endpoint')
        }

        if (!db.objectStoreNames.contains('health_steps')) {
          const store = db.createObjectStore('health_steps', {
            keyPath: 'local_id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-sync-status', 'sync_status')
          store.createIndex('by-date', 'date')
        }

        if (!db.objectStoreNames.contains('health_weight')) {
          const store = db.createObjectStore('health_weight', {
            keyPath: 'local_id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-sync-status', 'sync_status')
          store.createIndex('by-date', 'date')
        }

        if (!db.objectStoreNames.contains('health_hydration')) {
          const store = db.createObjectStore('health_hydration', {
            keyPath: 'local_id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-sync-status', 'sync_status')
          store.createIndex('by-date', 'date')
        }

        if (!db.objectStoreNames.contains('health_nutrition')) {
          const store = db.createObjectStore('health_nutrition', {
            keyPath: 'local_id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-sync-status', 'sync_status')
          store.createIndex('by-date', 'date')
        }

        if (!db.objectStoreNames.contains('finance_transactions')) {
          const store = db.createObjectStore('finance_transactions', {
            keyPath: 'local_id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-sync-status', 'sync_status')
          store.createIndex('by-date', 'transaction_date')
          store.createIndex('by-account', 'account_id')
        }

        if (!db.objectStoreNames.contains('sync_queue')) {
          const store = db.createObjectStore('sync_queue', {
            keyPath: 'id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-status', 'status')
          store.createIndex('by-entity', 'entity_type')
          store.createIndex('by-priority', 'priority')
        }

        if (!db.objectStoreNames.contains('sync_logs')) {
          const store = db.createObjectStore('sync_logs', {
            keyPath: 'id',
          })
          store.createIndex('by-user', 'user_id')
          store.createIndex('by-status', 'status')
          store.createIndex('by-created-at', 'created_at')
        }
      },
    })
  }

  return dbPromise
}

export async function clearOfflineDatabase(): Promise<void> {
  const db = await getOfflineDB()

  await Promise.all([
    db.clear('cached_api_responses'),
    db.clear('health_steps'),
    db.clear('health_weight'),
    db.clear('health_hydration'),
    db.clear('health_nutrition'),
    db.clear('finance_transactions'),
    db.clear('sync_queue'),
    db.clear('sync_logs'),
  ])
}
