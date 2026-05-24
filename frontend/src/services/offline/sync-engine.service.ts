import axios, { AxiosError } from 'axios'
import { networkStatusService } from './network-status.service'
import { syncQueueService } from './sync-queue.service'
import { syncLogService } from './sync-log.service'
import { offlineRecordService } from './offline-record.service'
import type { SyncQueueItem } from './offline-db'

let isSyncRunning = false

function extractErrorMessage(error: unknown): string {
  if (error instanceof AxiosError) {
    const responseData = error.response?.data as
      | {
          message?: string
          error?: {
            message?: string
            code?: string
          }
        }
      | undefined

    return (
      responseData?.message ||
      responseData?.error?.message ||
      responseData?.error?.code ||
      error.message ||
      'Sync request failed.'
    )
  }

  if (error instanceof Error) {
    return error.message
  }

  return 'Unknown sync error.'
}

function extractServerId(responseData: unknown): string | null {
  const data = responseData as
    | {
        data?: {
          id?: string | number
          uuid?: string
          server_id?: string
        }
        id?: string | number
        uuid?: string
      }
    | undefined

  const id =
    data?.data?.id ??
    data?.data?.uuid ??
    data?.data?.server_id ??
    data?.id ??
    data?.uuid ??
    null

  return id ? String(id) : null
}

async function updateLocalRecordAsSynced(
  item: SyncQueueItem,
  serverId: string | null,
): Promise<void> {
  switch (item.entity_type) {
    case 'health_steps':
      await offlineRecordService.updateHealthStepsStatus(
        item.entity_local_id,
        'synced',
        serverId,
      )
      break

    case 'health_weight':
      await offlineRecordService.updateHealthWeightStatus(
        item.entity_local_id,
        'synced',
        serverId,
      )
      break

    case 'health_hydration':
      await offlineRecordService.updateHealthHydrationStatus(
        item.entity_local_id,
        'synced',
        serverId,
      )
      break

    case 'health_nutrition':
      await offlineRecordService.updateHealthNutritionStatus(
        item.entity_local_id,
        'synced',
        serverId,
      )
      break

    case 'finance_transactions':
      await offlineRecordService.updateFinanceTransactionStatus(
        item.entity_local_id,
        'synced',
        serverId,
      )
      break
  }
}

async function updateLocalRecordAsFailed(
  item: SyncQueueItem,
  errorMessage: string,
): Promise<void> {
  switch (item.entity_type) {
    case 'health_steps':
      await offlineRecordService.updateHealthStepsStatus(
        item.entity_local_id,
        'failed',
        null,
        errorMessage,
      )
      break

    case 'health_weight':
      await offlineRecordService.updateHealthWeightStatus(
        item.entity_local_id,
        'failed',
        null,
        errorMessage,
      )
      break

    case 'health_hydration':
      await offlineRecordService.updateHealthHydrationStatus(
        item.entity_local_id,
        'failed',
        null,
        errorMessage,
      )
      break

    case 'health_nutrition':
      await offlineRecordService.updateHealthNutritionStatus(
        item.entity_local_id,
        'failed',
        null,
        errorMessage,
      )
      break

    case 'finance_transactions':
      await offlineRecordService.updateFinanceTransactionStatus(
        item.entity_local_id,
        'failed',
        null,
        errorMessage,
      )
      break
  }
}

async function updateLocalRecordAsConflict(
  item: SyncQueueItem,
  errorMessage: string,
): Promise<void> {
  switch (item.entity_type) {
    case 'health_steps':
      await offlineRecordService.updateHealthStepsStatus(
        item.entity_local_id,
        'conflict',
        null,
        errorMessage,
      )
      break

    case 'health_weight':
      await offlineRecordService.updateHealthWeightStatus(
        item.entity_local_id,
        'conflict',
        null,
        errorMessage,
      )
      break

    case 'health_hydration':
      await offlineRecordService.updateHealthHydrationStatus(
        item.entity_local_id,
        'conflict',
        null,
        errorMessage,
      )
      break

    case 'health_nutrition':
      await offlineRecordService.updateHealthNutritionStatus(
        item.entity_local_id,
        'conflict',
        null,
        errorMessage,
      )
      break

    case 'finance_transactions':
      await offlineRecordService.updateFinanceTransactionStatus(
        item.entity_local_id,
        'conflict',
        null,
        errorMessage,
      )
      break
  }
}

async function processQueueItem(item: SyncQueueItem): Promise<void> {
  await syncQueueService.markProcessing(item.id)

  try {
    const response = await axios.request({
      method: item.method,
      url: item.endpoint,
      data: item.payload,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-Idempotency-Key': item.entity_local_id,
        'X-Offline-Sync': 'true',
      },
    })

    const serverId = extractServerId(response.data)

    await updateLocalRecordAsSynced(item, serverId)
    await syncQueueService.markSynced(item.id)

    await syncLogService.add({
      user_id: item.user_id,
      queue_id: item.id,
      entity_type: item.entity_type,
      entity_local_id: item.entity_local_id,
      status: 'synced',
      message: 'Offline item synced successfully.',
    })
  } catch (error) {
    const errorMessage = extractErrorMessage(error)

    if (error instanceof AxiosError && error.response?.status === 409) {
      await updateLocalRecordAsConflict(item, errorMessage)
      await syncQueueService.markConflict(item.id, errorMessage)

      await syncLogService.add({
        user_id: item.user_id,
        queue_id: item.id,
        entity_type: item.entity_type,
        entity_local_id: item.entity_local_id,
        status: 'conflict',
        message: errorMessage,
      })

      return
    }

    await updateLocalRecordAsFailed(item, errorMessage)
    await syncQueueService.markFailed(item.id, errorMessage)

    await syncLogService.add({
      user_id: item.user_id,
      queue_id: item.id,
      entity_type: item.entity_type,
      entity_local_id: item.entity_local_id,
      status: 'failed',
      message: errorMessage,
    })
  }
}

export const syncEngineService = {
  async syncPending(userId?: string): Promise<void> {
    if (isSyncRunning) {
      return
    }

    if (!networkStatusService.getCurrentStatus()) {
      return
    }

    isSyncRunning = true

    try {
      const pendingItems = await syncQueueService.listPending(userId)

      for (const item of pendingItems) {
        const canRetry = await syncQueueService.canRetry(item)

        if (!canRetry) {
          await syncQueueService.markFailed(
            item.id,
            'Maximum retry attempts reached.',
          )
          continue
        }

        await processQueueItem(item)
      }
    } finally {
      isSyncRunning = false
    }
  },

  initializeAutoSync(userId?: string): void {
    networkStatusService.initialize()

    window.addEventListener('online', () => {
      void this.syncPending(userId)
    })
  },

  isRunning(): boolean {
    return isSyncRunning
  },
}
