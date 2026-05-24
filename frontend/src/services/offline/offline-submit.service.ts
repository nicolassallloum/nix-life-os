import { offlineRecordService } from './offline-record.service'
import { syncQueueService } from './sync-queue.service'
import type {
  CreateFinanceTransactionInput,
  CreateHealthHydrationInput,
  CreateHealthNutritionInput,
  CreateHealthStepsInput,
  CreateHealthWeightInput,
} from './offline-record.service'

export const offlineSubmitService = {
  async submitHealthSteps(input: CreateHealthStepsInput) {
    const record = await offlineRecordService.createHealthSteps(input)

    await syncQueueService.add({
      user_id: input.user_id,
      entity_type: 'health_steps',
      entity_local_id: record.local_id,
      method: 'POST',
      endpoint: '/api/v1/health/steps',
      payload: {
        date: input.date,
        steps: input.steps,
        notes: input.notes ?? null,
      },
    })

    return record
  },

  async submitHealthWeight(input: CreateHealthWeightInput) {
    const record = await offlineRecordService.createHealthWeight(input)

    await syncQueueService.add({
      user_id: input.user_id,
      entity_type: 'health_weight',
      entity_local_id: record.local_id,
      method: 'POST',
      endpoint: '/api/v1/health/weight',
      payload: {
        date: input.date,
        weight_kg: input.weight_kg,
        notes: input.notes ?? null,
      },
    })

    return record
  },

  async submitHealthHydration(input: CreateHealthHydrationInput) {
    const record = await offlineRecordService.createHealthHydration(input)

    await syncQueueService.add({
      user_id: input.user_id,
      entity_type: 'health_hydration',
      entity_local_id: record.local_id,
      method: 'POST',
      endpoint: '/api/v1/health/hydration',
      payload: {
        date: input.date,
        amount_ml: input.amount_ml,
        source: input.source ?? null,
      },
    })

    return record
  },

  async submitHealthNutrition(input: CreateHealthNutritionInput) {
    const record = await offlineRecordService.createHealthNutrition(input)

    await syncQueueService.add({
      user_id: input.user_id,
      entity_type: 'health_nutrition',
      entity_local_id: record.local_id,
      method: 'POST',
      endpoint: '/api/v1/health/nutrition',
      payload: {
        date: input.date,
        meal_type: input.meal_type ?? null,
        food_name: input.food_name,
        calories: input.calories ?? null,
        notes: input.notes ?? null,
      },
    })

    return record
  },

  async submitFinanceTransaction(input: CreateFinanceTransactionInput) {
    const record = await offlineRecordService.createFinanceTransaction(input)

    await syncQueueService.add({
      user_id: input.user_id,
      entity_type: 'finance_transactions',
      entity_local_id: record.local_id,
      method: 'POST',
      endpoint: '/api/v1/finance/transactions',
      payload: {
        account_id: input.account_id,
        category_id: input.category_id ?? null,
        type: input.type,
        amount: input.amount,
        currency: input.currency,
        transaction_date: input.transaction_date,
        description: input.description ?? null,
      },
    })

    return record
  },
}
