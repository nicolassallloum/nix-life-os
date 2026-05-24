import { ref, computed } from 'vue'

const isOnline = ref<boolean>(
  typeof navigator !== 'undefined' ? navigator.onLine : true,
)

const lastChangedAt = ref<string | null>(null)

const listenersInitialized = ref(false)

function nowIso(): string {
  return new Date().toISOString()
}

function setOnlineStatus(status: boolean): void {
  isOnline.value = status
  lastChangedAt.value = nowIso()
}

export const networkStatusService = {
  isOnline,

  isOffline: computed(() => !isOnline.value),

  lastChangedAt,

  initialize(): void {
    if (listenersInitialized.value) {
      return
    }

    if (typeof window === 'undefined') {
      return
    }

    setOnlineStatus(navigator.onLine)

    window.addEventListener('online', () => {
      setOnlineStatus(true)
    })

    window.addEventListener('offline', () => {
      setOnlineStatus(false)
    })

    listenersInitialized.value = true
  },

  getCurrentStatus(): boolean {
    if (typeof navigator === 'undefined') {
      return true
    }

    return navigator.onLine
  },

  refreshStatus(): boolean {
    const currentStatus = this.getCurrentStatus()
    setOnlineStatus(currentStatus)
    return currentStatus
  },

  canUseOnlineFeatures(): boolean {
    return isOnline.value
  },

  canUseOfflineFeatures(): boolean {
    return true
  },
}
