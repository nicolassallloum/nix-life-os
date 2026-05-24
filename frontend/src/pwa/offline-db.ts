import { openDB } from 'idb'

const DB_NAME = 'nixlifeos-offline-db'
const DB_VERSION = 1

export async function getOfflineDb() {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains('dashboard_cache')) {
        db.createObjectStore('dashboard_cache', {
          keyPath: 'key'
        })
      }

      if (!db.objectStoreNames.contains('sync_queue')) {
        db.createObjectStore('sync_queue', {
          keyPath: 'id',
          autoIncrement: true
        })
      }
    }
  })
}

export async function saveDashboardCache(key: string, data: unknown) {
  const db = await getOfflineDb()

  await db.put('dashboard_cache', {
    key,
    data,
    savedAt: new Date().toISOString()
  })
}

export async function getDashboardCache(key: string) {
  const db = await getOfflineDb()

  return db.get('dashboard_cache', key)
}

export async function addToSyncQueue(entityType: string, operationType: string, payload: unknown) {
  const db = await getOfflineDb()

  return db.add('sync_queue', {
    entityType,
    operationType,
    payload,
    status: 'PENDING',
    retryCount: 0,
    createdAt: new Date().toISOString()
  })
}.env.production