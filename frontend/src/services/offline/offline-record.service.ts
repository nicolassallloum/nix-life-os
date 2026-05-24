import {
  getOfflineDB,
  type OfflineFinanceTransaction,
  type OfflineHealthHydration,
  type OfflineHealthNutrition,
  type OfflineHealthSteps,
  type OfflineHealthWeight,
  type SyncStatus,
} from './offline-db'

function generateId(prefix = 'local'): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return `${prefix}-${crypto.randomUUID()}`
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

function nowIso(): string {
  return new Date().toISOString()
}

export interface CreateHealthStepsInput {
  user_id: string
  date: string
  steps: number
  notes?: string | null
}

export interface CreateHealthWeightInput {
  user_id: string
  date: string
  weight_kg: number
  notes?: string | null
}

export interface CreateHealthHydrationInput {
  user_id: string
  date: string
  amount_ml: number
  source?: string | null
}

export interface CreateHealthNutritionInput {
  user_id: string
  date: string
  meal_type?: string | null
  food_name: string
  calories?: number | null
  notes?: string | null
}

export interface CreateFinanceTransactionInput {
  user_id: string
  account_id: string
  category_id?: string | null
  type: 'income' | 'expense'
  amount: number
  currency: string
  transaction_date: string
  description?: string | null
}

export const offlineRecordService = {
  async createHealthSteps(input: CreateHealthStepsInput): Promise<OfflineHealthSteps> {
    const db = await getOfflineDB()
    const timestamp = nowIso()

    const record: OfflineHealthSteps = {
      local_id: generateId('health-steps'),
      server_id: null,
      user_id: input.user_id,
      date: input.date,
      steps: input.steps,
      notes: input.notes ?? null,
      sync_status: 'pending',
      created_offline: true,
      created_at: timestamp,
      updated_at: timestamp,
      last_error: null,
    }

    await db.put('health_steps', record)

    return record
  },

  async createHealthWeight(input: CreateHealthWeightInput): Promise<OfflineHealthWeight> {
    const db = await getOfflineDB()
    const timestamp = nowIso()

    const record: OfflineHealthWeight = {
      local_id: generateId('health-weight'),
      server_id: null,
      user_id: input.user_id,
      date: input.date,
      weight_kg: input.weight_kg,
      notes: input.notes ?? null,
      sync_status: 'pending',
      created_offline: true,
      created_at: timestamp,
      updated_at: timestamp,
      last_error: null,
    }

    await db.put('health_weight', record)

    return record
  },

  async createHealthHydration(input: CreateHealthHydrationInput): Promise<OfflineHealthHydration> {
    const db = await getOfflineDB()
    const timestamp = nowIso()

    const record: OfflineHealthHydration = {
      local_id: generateId('health-hydration'),
      server_id: null,
      user_id: input.user_id,
      date: input.date,
      amount_ml: input.amount_ml,
      source: input.source ?? null,
      sync_status: 'pending',
      created_offline: true,
      created_at: timestamp,
      updated_at: timestamp,
      last_error: null,
    }

    await db.put('health_hydration', record)

    return record
  },

  async createHealthNutrition(input: CreateHealthNutritionInput): Promise<OfflineHealthNutrition> {
    const db = await getOfflineDB()
    const timestamp = nowIso()

    const record: OfflineHealthNutrition = {
      local_id: generateId('health-nutrition'),
      server_id: null,
      user_id: input.user_id,
      date: input.date,
      meal_type: input.meal_type ?? null,
      food_name: input.food_name,
      calories: input.calories ?? null,
      notes: input.notes ?? null,
      sync_status: 'pending',
      created_offline: true,
      created_at: timestamp,
      updated_at: timestamp,
      last_error: null,
    }

    await db.put('health_nutrition', record)

    return record
  },

  async createFinanceTransaction(
    input: CreateFinanceTransactionInput,
  ): Promise<OfflineFinanceTransaction> {
    const db = await getOfflineDB()
    const timestamp = nowIso()

    const record: OfflineFinanceTransaction = {
      local_id: generateId('finance-transaction'),
      server_id: null,
      user_id: input.user_id,
      account_id: input.account_id,
      category_id: input.category_id ?? null,
      type: input.type,
      amount: input.amount,
      currency: input.currency,
      transaction_date: input.transaction_date,
      description: input.description ?? null,
      sync_status: 'pending',
      created_offline: true,
      created_at: timestamp,
      updated_at: timestamp,
      last_error: null,
    }

    await db.put('finance_transactions', record)

    return record
  },

  async updateHealthStepsStatus(
    localId: string,
    status: SyncStatus,
    serverId?: string | null,
    errorMessage?: string | null,
  ): Promise<void> {
    const db = await getOfflineDB()
    const record = await db.get('health_steps', localId)

    if (!record) return

    await db.put('health_steps', {
      ...record,
      server_id: serverId ?? record.server_id,
      sync_status: status,
      last_error: errorMessage ?? null,
      updated_at: nowIso(),
    })
  },

  async updateHealthWeightStatus(
    localId: string,
    status: SyncStatus,
    serverId?: string | null,
    errorMessage?: string | null,
  ): Promise<void> {
    const db = await getOfflineDB()
    const record = await db.get('health_weight', localId)

    if (!record) return

    await db.put('health_weight', {
      ...record,
      server_id: serverId ?? record.server_id,
      sync_status: status,
      last_error: errorMessage ?? null,
      updated_at: nowIso(),
    })
  },

  async updateHealthHydrationStatus(
    localId: string,
    status: SyncStatus,
    serverId?: string | null,
    errorMessage?: string | null,
  ): Promise<void> {
    const db = await getOfflineDB()
    const record = await db.get('health_hydration', localId)

    if (!record) return

    await db.put('health_hydration', {
      ...record,
      server_id: serverId ?? record.server_id,
      sync_status: status,
      last_error: errorMessage ?? null,
      updated_at: nowIso(),
    })
  },

  async updateHealthNutritionStatus(
    localId: string,
    status: SyncStatus,
    serverId?: string | null,
    errorMessage?: string | null,
  ): Promise<void> {
    const db = await getOfflineDB()
    const record = await db.get('health_nutrition', localId)

    if (!record) return

    await db.put('health_nutrition', {
      ...record,
      server_id: serverId ?? record.server_id,
      sync_status: status,
      last_error: errorMessage ?? null,
      updated_at: nowIso(),
    })
  },

  async updateFinanceTransactionStatus(
    localId: string,
    status: SyncStatus,
    serverId?: string | null,
    errorMessage?: string | null,
  ): Promise<void> {
    const db = await getOfflineDB()
    const record = await db.get('finance_transactions', localId)

    if (!record) return

    await db.put('finance_transactions', {
      ...record,
      server_id: serverId ?? record.server_id,
      sync_status: status,
      last_error: errorMessage ?? null,
      updated_at: nowIso(),
    })
  },

  async listPendingHealthSteps(userId?: string): Promise<OfflineHealthSteps[]> {
    const db = await getOfflineDB()
    const records = await db.getAllFromIndex('health_steps', 'by-sync-status', 'pending')

    return userId ? records.filter((record) => record.user_id === userId) : records
  },

  async listPendingHealthWeight(userId?: string): Promise<OfflineHealthWeight[]> {
    const db = await getOfflineDB()
    const records = await db.getAllFromIndex('health_weight', 'by-sync-status', 'pending')

    return userId ? records.filter((record) => record.user_id === userId) : records
  },

  async listPendingHealthHydration(userId?: string): Promise<OfflineHealthHydration[]> {
    const db = await getOfflineDB()
    const records = await db.getAllFromIndex('health_hydration', 'by-sync-status', 'pending')

    return userId ? records.filter((record) => record.user_id === userId) : records
  },

  async listPendingHealthNutrition(userId?: string): Promise<OfflineHealthNutrition[]> {
    const db = await getOfflineDB()
    const records = await db.getAllFromIndex('health_nutrition', 'by-sync-status', 'pending')

    return userId ? records.filter((record) => record.user_id === userId) : records
  },

  async listPendingFinanceTransactions(
    userId?: string,
  ): Promise<OfflineFinanceTransaction[]> {
    const db = await getOfflineDB()
    const records = await db.getAllFromIndex(
      'finance_transactions',
      'by-sync-status',
      'pending',
    )

    return userId ? records.filter((record) => record.user_id === userId) : records
  },

  async clearUserOfflineRecords(userId: string): Promise<void> {
    const db = await getOfflineDB()

    const stores = [
      'health_steps',
      'health_weight',
      'health_hydration',
      'health_nutrition',
      'finance_transactions',
    ] as const

    for (const storeName of stores) {
      const tx = db.transaction(storeName, 'readwrite')
      const index = tx.store.index('by-user')

      for await (const cursor of index.iterate(userId)) {
        await cursor.delete()
      }

      await tx.done
    }
  },
}
