import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/main.css'
// import { registerServiceWorker } from './registerServiceWorker'
// import { registerSW } from 'virtual:pwa-register'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')

// registerServiceWorker()

// registerSW({
//   immediate: true,
//
//   onNeedRefresh() {
//     console.log('[PWA] New version available.')
//   },
//
//   onOfflineReady() {
//     console.log('[PWA] App ready to work offline.')
//   },
//
//   onRegistered(registration) {
//     console.log('[PWA] Service Worker registered:', registration)
//   },
//
//   onRegisterError(error) {
//     console.error('[PWA] Service Worker registration failed:', error)
//   },
// })

if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', async () => {
    try {
      const registration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/',
      })

      console.log('[PWA] Service Worker registered successfully:', registration)
    } catch (error) {
      console.error('[PWA] Service Worker registration failed:', error)
    }
  })
}