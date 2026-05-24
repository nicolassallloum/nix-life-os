import { getOfflineDB } from './offline-db'
import { offlineSubmitService } from './offline-submit.service'
import { syncQueueService } from './sync-queue.service'
import { syncEngineService } from './sync-engine.service'

const TEST_USER_ID = 'dev-user-001'

async function createTestHealthSteps() {
  return offlineSubmitService.submitHealthSteps({
    user_id: TEST_USER_ID,
    date: new Date().toISOString().slice(0, 10),
    steps: 4500,
    notes: 'Offline dev test - health steps',
  })
}

async function createTestHealthWeight() {
  return offlineSubmitService.submitHealthWeight({
    user_id: TEST_USER_ID,
    date: new Date().toISOString().slice(0, 10),
    weight_kg: 72.5,
    notes: 'Offline dev test - health weight',
  })
}

async function createTestHealthHydration() {
  return offlineSubmitService.submitHealthHydration({
    user_id: TEST_USER_ID,
    date: new Date().toISOString().slice(0, 10),
    amount_ml: 500,
    source: 'Offline dev test',
  })
}

async function createTestFinanceTransaction() {
  return offlineSubmitService.submitFinanceTransaction({
    user_id: TEST_USER_ID,
    account_id: 'dev-account-001',
    category_id: null,
    type: 'expense',
    amount: 12.5,
    currency: 'USD',
    transaction_date: new Date().toISOString().slice(0, 10),
    description: 'Offline dev test - finance transaction',
  })
}

async function listAllOfflineData() {
  const db = await getOfflineDB()

  return {
    health_steps: await db.getAll('health_steps'),
    health_weight: await db.getAll('health_weight'),
    health_hydration: await db.getAll('health_hydration'),
    health_nutrition: await db.getAll('health_nutrition'),
    finance_transactions: await db.getAll('finance_transactions'),
    sync_queue: await db.getAll('sync_queue'),
    sync_logs: await db.getAll('sync_logs'),
    cached_api_responses: await db.getAll('cached_api_responses'),
  }
}

async function listPendingQueue() {
  return syncQueueService.listPending(TEST_USER_ID)
}

async function runFullOfflineTest() {
  const steps = await createTestHealthSteps()
  const weight = await createTestHealthWeight()
  const hydration = await createTestHealthHydration()
  const transaction = await createTestFinanceTransaction()
  const pendingQueue = await listPendingQueue()

  return {
    message: 'Offline dev test completed successfully.',
    created_records: {
      steps,
      weight,
      hydration,
      transaction,
    },
    pending_queue_count: pendingQueue.length,
    pending_queue: pendingQueue,
  }
}

async function clearOfflineDatabase() {
  const db = await getOfflineDB()

  await db.clear('health_steps')
  await db.clear('health_weight')
  await db.clear('health_hydration')
  await db.clear('health_nutrition')
  await db.clear('finance_transactions')
  await db.clear('sync_queue')
  await db.clear('sync_logs')
  await db.clear('cached_api_responses')

  return {
    message: 'Offline database cleared successfully.',
  }
}

export const offlineDevtoolsService = {
  TEST_USER_ID,
  createTestHealthSteps,
  createTestHealthWeight,
  createTestHealthHydration,
  createTestFinanceTransaction,
  listAllOfflineData,
  listPendingQueue,
  runFullOfflineTest,
  clearOfflineDatabase,
  syncPending: syncEngineService.syncPending,
}
