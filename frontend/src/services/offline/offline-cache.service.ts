import { getOfflineDB, type CachedApiResponse } from './offline-db'

export interface CacheOptions {
  expiresInMinutes?: number
}

function nowIso(): string {
  return new Date().toISOString()
}

function addMinutes(minutes: number): string {
  const date = new Date()
  date.setMinutes(date.getMinutes() + minutes)
  return date.toISOString()
}

export const offlineCacheService = {
  async saveCache(
    key: string,
    endpoint: string,
    data: unknown,
    userId: string,
    options: CacheOptions = {},
  ): Promise<void> {
    const db = await getOfflineDB()

    const cacheRecord: CachedApiResponse = {
      key,
      endpoint,
      data,
      user_id: userId,
      fetched_at: nowIso(),
      expires_at: options.expiresInMinutes
        ? addMinutes(options.expiresInMinutes)
        : null,
    }

    await db.put('cached_api_responses', cacheRecord)
  },

  async getCache<T = unknown>(key: string): Promise<T | null> {
    const db = await getOfflineDB()
    const record = await db.get('cached_api_responses', key)

    if (!record) {
      return null
    }

    if (record.expires_at && new Date(record.expires_at) < new Date()) {
      await db.delete('cached_api_responses', key)
      return null
    }

    return record.data as T
  },

  async getCacheRecord(key: string): Promise<CachedApiResponse | null> {
    const db = await getOfflineDB()
    const record = await db.get('cached_api_responses', key)

    if (!record) {
      return null
    }

    return record
  },

  async deleteCache(key: string): Promise<void> {
    const db = await getOfflineDB()
    await db.delete('cached_api_responses', key)
  },

  async clearUserCache(userId: string): Promise<void> {
    const db = await getOfflineDB()
    const tx = db.transaction('cached_api_responses', 'readwrite')
    const index = tx.store.index('by-user')

    for await (const cursor of index.iterate(userId)) {
      await cursor.delete()
    }

    await tx.done
  },

  async listUserCache(userId: string): Promise<CachedApiResponse[]> {
    const db = await getOfflineDB()
    return db.getAllFromIndex('cached_api_responses', 'by-user', userId)
  },

  async hasCache(key: string): Promise<boolean> {
    const db = await getOfflineDB()
    const record = await db.getKey('cached_api_responses', key)
    return Boolean(record)
  },
}
