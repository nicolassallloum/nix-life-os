import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

import './assets/main.css'
import { registerSW } from 'virtual:pwa-register'

const app = createApp(App)

app.use(router)

app.mount('#app')

registerSW({
  immediate: true,

  onNeedRefresh() {
    console.log('[PWA] New version available.')
  },

  onOfflineReady() {
    console.log('[PWA] App ready to work offline.')
  },

  onRegistered(registration) {
    console.log('[PWA] Service Worker registered:', registration)
  },

  onRegisterError(error) {
    console.error('[PWA] Service Worker registration failed:', error)
  }
})

window.__NIX_PWA_UPDATE__ = updateSW
