import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { networkStatusService } from '@/services/offline/network-status.service'
import { syncQueueService } from '@/services/offline/sync-queue.service'

export const useOfflineStore = defineStore('offline', () => {
  const initialized = ref(false)
  const currentUserId = ref<string | null>(null)
  const pendingSyncCount = ref(0)
  const failedSyncCount = ref(0)
  const conflictSyncCount = ref(0)
  const lastSyncCheckAt = ref<string | null>(null)
  const offlineBannerDismissed = ref(false)

  const isOnline = computed(() => networkStatusService.isOnline.value)
  const isOffline = computed(() => !networkStatusService.isOnline.value)

  const hasPendingSync = computed(() => pendingSyncCount.value > 0)
  const hasFailedSync = computed(() => failedSyncCount.value > 0)
  const hasConflicts = computed(() => conflictSyncCount.value > 0)

  const shouldShowOfflineBanner = computed(() => {
    return isOffline.value && !offlineBannerDismissed.value
  })

  const shouldShowSyncWarning = computed(() => {
    return pendingSyncCount.value > 0 || failedSyncCount.value > 0 || conflictSyncCount.value > 0
  })

  function nowIso(): string {
    return new Date().toISOString()
  }

  async function initialize(userId?: string | null): Promise<void> {
    networkStatusService.initialize()

    if (userId) {
      currentUserId.value = userId
    }

    await refreshSyncCounts()

    initialized.value = true
  }

  function setCurrentUser(userId: string | null): void {
    currentUserId.value = userId
  }

  async function refreshSyncCounts(): Promise<void> {
    const userId = currentUserId.value ?? undefined

    const pendingItems = await syncQueueService.listPending(userId)
    const failedItems = await syncQueueService.listFailed(userId)
    const conflictItems = await syncQueueService.listConflicts(userId)

    pendingSyncCount.value = pendingItems.length
    failedSyncCount.value = failedItems.length
    conflictSyncCount.value = conflictItems.length
    lastSyncCheckAt.value = nowIso()
  }

  function dismissOfflineBanner(): void {
    offlineBannerDismissed.value = true
  }

  function showOfflineBannerAgain(): void {
    offlineBannerDismissed.value = false
  }

  function resetOfflineBanner(): void {
    offlineBannerDismissed.value = false
  }

  function canUseOnlineFeatures(): boolean {
    return isOnline.value
  }

  function canUseOfflineFeatures(): boolean {
    return true
  }

  async function clearState(): Promise<void> {
    currentUserId.value = null
    pendingSyncCount.value = 0
    failedSyncCount.value = 0
    conflictSyncCount.value = 0
    lastSyncCheckAt.value = null
    offlineBannerDismissed.value = false
    initialized.value = false
  }

  return {
    initialized,
    currentUserId,
    pendingSyncCount,
    failedSyncCount,
    conflictSyncCount,
    lastSyncCheckAt,
    offlineBannerDismissed,

    isOnline,
    isOffline,
    hasPendingSync,
    hasFailedSync,
    hasConflicts,
    shouldShowOfflineBanner,
    shouldShowSyncWarning,

    initialize,
    setCurrentUser,
    refreshSyncCounts,
    dismissOfflineBanner,
    showOfflineBannerAgain,
    resetOfflineBanner,
    canUseOnlineFeatures,
    canUseOfflineFeatures,
    clearState,
  }
})
