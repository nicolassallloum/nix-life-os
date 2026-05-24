import { ref, onMounted } from 'vue'

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{
    outcome: 'accepted' | 'dismissed'
    platform: string
  }>
}

export function usePwaInstall() {
  const deferredPrompt = ref<BeforeInstallPromptEvent | null>(null)
  const canInstall = ref(false)
  const isInstalled = ref(false)

  onMounted(() => {
    isInstalled.value =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true

    window.addEventListener('beforeinstallprompt', event => {
      event.preventDefault()

      deferredPrompt.value = event as BeforeInstallPromptEvent
      canInstall.value = true
    })

    window.addEventListener('appinstalled', () => {
      isInstalled.value = true
      canInstall.value = false
      deferredPrompt.value = null
    })
  })

  async function installApp() {
    if (!deferredPrompt.value) return

    await deferredPrompt.value.prompt()

    const choice = await deferredPrompt.value.userChoice

    if (choice.outcome === 'accepted') {
      canInstall.value = false
    }

    deferredPrompt.value = null
  }

  return {
    canInstall,
    isInstalled,
    installApp
  }
}