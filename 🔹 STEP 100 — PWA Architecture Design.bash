ChatGPT




🔹 STEP 100 — PWA Architecture Design
You are a Senior PWA Architect.

Design the PWA architecture for Nix Life OS.

Include service worker, manifest file, offline support, caching strategy, install prompt, app icons, splash screen, push notifications, mobile layout, and App Store / Play Store future packaging.

Output must be implementation-ready.

I’ll design this as a production-ready PWA layer for your current Laravel API + Vue frontend deployment, with exact files, code, caching rules, and validation steps.

Thought for 25s
🔹 STEP 100 — PWA Architecture Design
Nix Life OS — Production-Ready PWA Architecture
You are now ready to convert Nix Life OS from a normal responsive web app into a Progressive Web App that can be installed on mobile/desktop, load faster, work partially offline, support push notifications, and later be packaged for Google Play Store / Apple App Store.

This design assumes your current production structure:

Frontend: Vue / Vite
Backend: Laravel API
Domain:
  Frontend: https://app.nixlifeos.com
  API:      https://api.nixlifeos.com
Server:    Nginx + Docker production deployment
PWA requires three main foundations: a Web App Manifest, a Service Worker, and installable HTTPS delivery. The manifest gives browsers install metadata such as name, icons, display mode, and theme color; service workers provide offline capability, caching, and push notification handling. 

1. Target PWA Architecture
Nix Life OS PWA
│
├── Vue Frontend
│   ├── Mobile responsive layout
│   ├── Install prompt component
│   ├── Offline banner
│   ├── Push notification opt-in
│   └── Local offline fallback views
│
├── PWA Layer
│   ├── manifest.webmanifest
│   ├── Service Worker
│   ├── Runtime caching
│   ├── Offline fallback page
│   ├── App icons
│   ├── Splash screen icons
│   └── Push notification listener
│
├── Browser Storage
│   ├── Cache Storage
│   ├── IndexedDB
│   └── localStorage for lightweight settings only
│
├── Laravel API
│   ├── Auth APIs
│   ├── Dashboard APIs
│   ├── Finance APIs
│   ├── Health APIs
│   ├── Projects APIs
│   ├── Push subscription APIs
│   └── Notification dispatch
│
└── Future Native Packaging
    ├── Android: Trusted Web Activity / Bubblewrap
    └── iOS: Capacitor wrapper or App Store web container
Recommended implementation approach for your Vue/Vite app:

Use vite-plugin-pwa with injectManifest strategy
Reason: generateSW is simpler, but injectManifest is better for Nix Life OS because you need custom caching rules, API handling, offline fallbacks, and push notification logic. The Vite PWA plugin supports both strategies, and injectManifest lets you write a custom service worker while the plugin injects the build precache list. 

2. Install Required PWA Packages
Run inside your Vue frontend project folder.

cd /u01/nix-life-os/frontend

npm install vite-plugin-pwa workbox-window
Optional, for IndexedDB offline storage:

npm install idb
3. Recommended Folder Structure
Create this structure:

frontend/
│
├── public/
│   ├── pwa/
│   │   ├── icons/
│   │   │   ├── icon-72x72.png
│   │   │   ├── icon-96x96.png
│   │   │   ├── icon-128x128.png
│   │   │   ├── icon-144x144.png
│   │   │   ├── icon-152x152.png
│   │   │   ├── icon-192x192.png
│   │   │   ├── icon-384x384.png
│   │   │   ├── icon-512x512.png
│   │   │   └── maskable-icon-512x512.png
│   │   │
│   │   ├── screenshots/
│   │   │   ├── desktop-dashboard.png
│   │   │   └── mobile-dashboard.png
│   │   │
│   │   └── offline.html
│   │
│   └── robots.txt
│
├── src/
│   ├── components/
│   │   ├── pwa/
│   │   │   ├── InstallPrompt.vue
│   │   │   ├── OfflineBanner.vue
│   │   │   ├── UpdateAvailablePrompt.vue
│   │   │   └── PushNotificationPrompt.vue
│   │
│   ├── composables/
│   │   ├── usePwaInstall.ts
│   │   ├── useNetworkStatus.ts
│   │   ├── usePushNotifications.ts
│   │   └── useServiceWorkerUpdate.ts
│   │
│   ├── pwa/
│   │   ├── sw.ts
│   │   ├── push.ts
│   │   └── offline-db.ts
│   │
│   ├── main.ts
│   └── App.vue
│
├── vite.config.ts
└── package.json
4. Vite PWA Configuration
File: frontend/vite.config.ts
Add or update your Vite config like this:

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),

    VitePWA({
      strategies: 'injectManifest',

      srcDir: 'src/pwa',
      filename: 'sw.ts',

      registerType: 'prompt',

      injectManifest: {
        globPatterns: [
          '**/*.{js,css,html,ico,png,svg,webp,json,woff2}'
        ],
        maximumFileSizeToCacheInBytes: 5 * 1024 * 1024
      },

      manifest: {
        id: '/',

        name: 'Nix Life OS',
        short_name: 'NixLifeOS',

        description:
          'Your Personal AI-Powered Life Operating System for health, finance, productivity, projects, and AI insights.',

        start_url: '/',
        scope: '/',
        display: 'standalone',
        orientation: 'portrait-primary',

        background_color: '#020617',
        theme_color: '#06b6d4',

        categories: [
          'productivity',
          'health',
          'finance',
          'business'
        ],

        lang: 'en',
        dir: 'ltr',

        icons: [
          {
            src: '/pwa/icons/icon-72x72.png',
            sizes: '72x72',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-96x96.png',
            sizes: '96x96',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-128x128.png',
            sizes: '128x128',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-144x144.png',
            sizes: '144x144',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-152x152.png',
            sizes: '152x152',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-384x384.png',
            sizes: '384x384',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png'
          },
          {
            src: '/pwa/icons/maskable-icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable'
          }
        ],

        screenshots: [
          {
            src: '/pwa/screenshots/desktop-dashboard.png',
            sizes: '1440x900',
            type: 'image/png',
            form_factor: 'wide',
            label: 'Nix Life OS desktop dashboard'
          },
          {
            src: '/pwa/screenshots/mobile-dashboard.png',
            sizes: '390x844',
            type: 'image/png',
            form_factor: 'narrow',
            label: 'Nix Life OS mobile dashboard'
          }
        ]
      },

      devOptions: {
        enabled: false
      }
    })
  ],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})
5. Manifest Output
The plugin will generate the manifest from the Vite config. But conceptually, the manifest should represent this:

{
  "name": "Nix Life OS",
  "short_name": "NixLifeOS",
  "description": "Your Personal AI-Powered Life Operating System.",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "background_color": "#020617",
  "theme_color": "#06b6d4",
  "icons": [
    {
      "src": "/pwa/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/pwa/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "/pwa/icons/maskable-icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
The install prompt uses the manifest metadata such as name, icons, description, and screenshots where supported. Android browsers can also display screenshots and description in the install prompt. 

6. Service Worker Design
Caching Strategy Summary
Use different caching rules per resource type. A service worker can intercept requests and choose how to respond using the Cache Storage API, allowing fine-grained caching behavior beyond normal HTTP caching. 

Resource Type                         Strategy
------------------------------------------------------------
Vue app shell                         Precache
JS/CSS/assets                         Cache First
Images/icons                          Cache First
Fonts                                 Cache First
Dashboard APIs                        Network First
Authenticated sensitive APIs          Network Only
Static reference APIs                 Stale While Revalidate
Offline page                          Cache First
Failed navigation                     Offline fallback
Push notification events              Service Worker push handler
Important security rule:

Never cache sensitive authenticated API responses permanently.
For Nix Life OS, do not cache:

/api/v1/auth/*
/api/v1/user/*
/api/v1/profile/*
/api/v1/finance/transactions
/api/v1/finance/accounts
/api/v1/health/*
/api/v1/settings/*
/sanctum/*
Safe to cache temporarily:

/api/v1/dashboard/summary
/api/v1/life-balance/summary
/api/v1/reference/*
/api/v1/public/*
7. Custom Service Worker
File: frontend/src/pwa/sw.ts
/// <reference lib="webworker" />

import { clientsClaim } from 'workbox-core'
import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching'
import { registerRoute, NavigationRoute } from 'workbox-routing'
import {
  CacheFirst,
  NetworkFirst,
  StaleWhileRevalidate,
  NetworkOnly
} from 'workbox-strategies'
import { ExpirationPlugin } from 'workbox-expiration'
import { CacheableResponsePlugin } from 'workbox-cacheable-response'

declare const self: ServiceWorkerGlobalScope

clientsClaim()
self.skipWaiting()

cleanupOutdatedCaches()

precacheAndRoute(self.__WB_MANIFEST)

const API_ORIGIN = 'https://api.nixlifeos.com'

/**
 * Offline fallback for app navigation.
 */
const navigationHandler = async ({ request }: { request: Request }) => {
  try {
    return await fetch(request)
  } catch {
    const cache = await caches.open('nixlifeos-offline-v1')
    const offlineResponse = await cache.match('/pwa/offline.html')

    return (
      offlineResponse ||
      new Response('Nix Life OS is offline.', {
        status: 503,
        statusText: 'Offline'
      })
    )
  }
}

registerRoute(new NavigationRoute(navigationHandler))

/**
 * Cache static assets.
 */
registerRoute(
  ({ request }) =>
    request.destination === 'script' ||
    request.destination === 'style' ||
    request.destination === 'worker',
  new CacheFirst({
    cacheName: 'nixlifeos-static-assets-v1',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200]
      }),
      new ExpirationPlugin({
        maxEntries: 80,
        maxAgeSeconds: 30 * 24 * 60 * 60
      })
    ]
  })
)

/**
 * Cache images and icons.
 */
registerRoute(
  ({ request }) =>
    request.destination === 'image' ||
    request.destination === 'font',
  new CacheFirst({
    cacheName: 'nixlifeos-media-v1',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200]
      }),
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 60 * 24 * 60 * 60
      })
    ]
  })
)

/**
 * Public reference APIs.
 */
registerRoute(
  ({ url }) =>
    url.origin === API_ORIGIN &&
    url.pathname.startsWith('/api/v1/reference/'),
  new StaleWhileRevalidate({
    cacheName: 'nixlifeos-reference-api-v1',
    plugins: [
      new CacheableResponsePlugin({
        statuses: [200]
      }),
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 24 * 60 * 60
      })
    ]
  })
)

/**
 * Dashboard summaries.
 * Network first keeps dashboard fresh but allows fallback if offline.
 */
registerRoute(
  ({ url }) =>
    url.origin === API_ORIGIN &&
    (
      url.pathname === '/api/v1/dashboard/summary' ||
      url.pathname === '/api/v1/life-balance/summary'
    ),
  new NetworkFirst({
    cacheName: 'nixlifeos-dashboard-api-v1',
    networkTimeoutSeconds: 5,
    plugins: [
      new CacheableResponsePlugin({
        statuses: [200]
      }),
      new ExpirationPlugin({
        maxEntries: 20,
        maxAgeSeconds: 10 * 60
      })
    ]
  })
)

/**
 * Sensitive authenticated APIs must not be cached.
 */
registerRoute(
  ({ url }) =>
    url.origin === API_ORIGIN &&
    (
      url.pathname.startsWith('/api/v1/auth/') ||
      url.pathname.startsWith('/api/v1/user') ||
      url.pathname.startsWith('/api/v1/profile') ||
      url.pathname.startsWith('/api/v1/finance/') ||
      url.pathname.startsWith('/api/v1/health/') ||
      url.pathname.startsWith('/api/v1/settings') ||
      url.pathname.startsWith('/sanctum/')
    ),
  new NetworkOnly()
)

/**
 * Install event.
 */
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open('nixlifeos-offline-v1').then(cache => {
      return cache.addAll([
        '/pwa/offline.html',
        '/pwa/icons/icon-192x192.png',
        '/pwa/icons/icon-512x512.png'
      ])
    })
  )
})

/**
 * Push notification handler.
 */
self.addEventListener('push', event => {
  let payload = {
    title: 'Nix Life OS',
    body: 'You have a new update.',
    icon: '/pwa/icons/icon-192x192.png',
    badge: '/pwa/icons/icon-72x72.png',
    url: '/'
  }

  if (event.data) {
    try {
      payload = {
        ...payload,
        ...event.data.json()
      }
    } catch {
      payload.body = event.data.text()
    }
  }

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: payload.icon,
      badge: payload.badge,
      data: {
        url: payload.url
      },
      vibrate: [100, 50, 100],
      actions: [
        {
          action: 'open',
          title: 'Open Nix Life OS'
        }
      ]
    })
  )
})

/**
 * Notification click handler.
 */
self.addEventListener('notificationclick', event => {
  event.notification.close()

  const targetUrl = event.notification.data?.url || '/'

  event.waitUntil(
    self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(clientList => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.focus()
          client.navigate(targetUrl)
          return
        }
      }

      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl)
      }
    })
  )
})
8. Offline Page
File: frontend/public/pwa/offline.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <title>Nix Life OS — Offline</title>

  <style>
    body {
      margin: 0;
      min-height: 100vh;
      font-family: Inter, Arial, sans-serif;
      background: radial-gradient(circle at top, #0f172a, #020617);
      color: #e5e7eb;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }

    .card {
      max-width: 440px;
      width: 100%;
      background: rgba(15, 23, 42, 0.9);
      border: 1px solid rgba(6, 182, 212, 0.35);
      border-radius: 24px;
      padding: 32px;
      text-align: center;
      box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
    }

    .logo {
      width: 72px;
      height: 72px;
      margin: 0 auto 20px;
      border-radius: 22px;
      background: linear-gradient(135deg, #06b6d4, #7c3aed);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 32px;
      font-weight: 800;
      color: white;
    }

    h1 {
      margin: 0 0 12px;
      font-size: 26px;
    }

    p {
      color: #94a3b8;
      line-height: 1.6;
      margin-bottom: 24px;
    }

    button {
      border: 0;
      border-radius: 14px;
      background: linear-gradient(135deg, #06b6d4, #7c3aed);
      color: white;
      padding: 12px 20px;
      font-weight: 700;
      cursor: pointer;
    }
  </style>
</head>

<body>
  <div class="card">
    <div class="logo">N</div>

    <h1>You are offline</h1>

    <p>
      Nix Life OS cannot connect right now. Some cached dashboard data may still be available once you return to the app.
    </p>

    <button onclick="window.location.reload()">
      Try Again
    </button>
  </div>
</body>
</html>
9. Register Service Worker in Vue
File: frontend/src/main.ts
Add this near the bottom after app creation:

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

import './assets/main.css'
import { registerSW } from 'virtual:pwa-register'

const app = createApp(App)

app.use(router)

app.mount('#app')

const updateSW = registerSW({
  immediate: true,

  onNeedRefresh() {
    window.dispatchEvent(new CustomEvent('pwa-update-available'))
  },

  onOfflineReady() {
    window.dispatchEvent(new CustomEvent('pwa-offline-ready'))
  },

  onRegistered(registration) {
    console.log('[PWA] Service Worker registered:', registration)
  },

  onRegisterError(error) {
    console.error('[PWA] Service Worker registration failed:', error)
  }
})

window.__NIX_PWA_UPDATE__ = updateSW
Add global type support.

File: frontend/src/vite-env.d.ts
/// <reference types="vite/client" />

interface Window {
  __NIX_PWA_UPDATE__?: (reloadPage?: boolean) => Promise<void>
}
10. Install Prompt Component
Browsers do not allow you to show the install prompt whenever you want. You must capture the beforeinstallprompt event and trigger it later after user action.

File: frontend/src/composables/usePwaInstall.ts
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
File: frontend/src/components/pwa/InstallPrompt.vue
<script setup lang="ts">
import { usePwaInstall } from '@/composables/usePwaInstall'

const { canInstall, isInstalled, installApp } = usePwaInstall()
</script>

<template>
  <div
    v-if="canInstall && !isInstalled"
    class="pwa-install-card"
  >
    <div>
      <strong>Install Nix Life OS</strong>
      <p>Use it like a mobile app with faster access and offline support.</p>
    </div>

    <button @click="installApp">
      Install App
    </button>
  </div>
</template>

<style scoped>
.pwa-install-card {
  position: fixed;
  left: 16px;
  right: 16px;
  bottom: 20px;
  z-index: 9999;
  max-width: 520px;
  margin: 0 auto;
  padding: 16px;
  border-radius: 20px;
  background: linear-gradient(135deg, #020617, #0f172a);
  color: #fff;
  border: 1px solid rgba(6, 182, 212, 0.35);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  gap: 16px;
  justify-content: space-between;
}

p {
  margin: 4px 0 0;
  color: #94a3b8;
  font-size: 13px;
}

button {
  border: 0;
  border-radius: 14px;
  padding: 10px 16px;
  background: linear-gradient(135deg, #06b6d4, #7c3aed);
  color: white;
  font-weight: 700;
  cursor: pointer;
}
</style>
Add it to your main layout.

File: frontend/src/App.vue
<script setup lang="ts">
import InstallPrompt from '@/components/pwa/InstallPrompt.vue'
import OfflineBanner from '@/components/pwa/OfflineBanner.vue'
import UpdateAvailablePrompt from '@/components/pwa/UpdateAvailablePrompt.vue'
</script>

<template>
  <OfflineBanner />
  <UpdateAvailablePrompt />

  <RouterView />

  <InstallPrompt />
</template>
11. Offline Banner
File: frontend/src/composables/useNetworkStatus.ts
import { ref, onMounted, onUnmounted } from 'vue'

export function useNetworkStatus() {
  const isOnline = ref(navigator.onLine)

  function updateStatus() {
    isOnline.value = navigator.onLine
  }

  onMounted(() => {
    window.addEventListener('online', updateStatus)
    window.addEventListener('offline', updateStatus)
  })

  onUnmounted(() => {
    window.removeEventListener('online', updateStatus)
    window.removeEventListener('offline', updateStatus)
  })

  return {
    isOnline
  }
}
File: frontend/src/components/pwa/OfflineBanner.vue
<script setup lang="ts">
import { useNetworkStatus } from '@/composables/useNetworkStatus'

const { isOnline } = useNetworkStatus()
</script>

<template>
  <div
    v-if="!isOnline"
    class="offline-banner"
  >
    You are offline. Some Nix Life OS features may be limited.
  </div>
</template>

<style scoped>
.offline-banner {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  padding: 10px 16px;
  background: #f97316;
  color: white;
  text-align: center;
  font-weight: 700;
  z-index: 10000;
}
</style>
12. Update Available Prompt
File: frontend/src/components/pwa/UpdateAvailablePrompt.vue
<script setup lang="ts">
import { onMounted, ref } from 'vue'

const updateAvailable = ref(false)

onMounted(() => {
  window.addEventListener('pwa-update-available', () => {
    updateAvailable.value = true
  })
})

async function refreshApp() {
  if (window.__NIX_PWA_UPDATE__) {
    await window.__NIX_PWA_UPDATE__(true)
  } else {
    window.location.reload()
  }
}
</script>

<template>
  <div
    v-if="updateAvailable"
    class="update-card"
  >
    <span>A new version of Nix Life OS is available.</span>

    <button @click="refreshApp">
      Update
    </button>
  </div>
</template>

<style scoped>
.update-card {
  position: fixed;
  left: 16px;
  right: 16px;
  bottom: 100px;
  z-index: 9999;
  max-width: 520px;
  margin: 0 auto;
  padding: 14px 16px;
  border-radius: 18px;
  background: #0f172a;
  color: white;
  border: 1px solid rgba(124, 58, 237, 0.45);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

button {
  border: 0;
  border-radius: 12px;
  padding: 8px 14px;
  background: #7c3aed;
  color: white;
  font-weight: 700;
  cursor: pointer;
}
</style>
13. Offline Data Storage Strategy
For Nix Life OS, use three levels of offline support.

Level 1 — App Shell Offline
Available immediately:

- Login screen shell
- Dashboard layout shell
- Navigation
- Offline page
- Icons
- CSS/JS bundles
Level 2 — Read-Only Cached Summaries
Safe cached data:

- Last dashboard summary
- Last life balance summary
- Static reference lists
- User interface preferences
Do not cache sensitive transaction details unless encrypted and explicitly designed.

Level 3 — Future Offline Write Queue
Future enhancement:

User creates an offline entry:
  hydration log
  task
  note
  expense draft

Stored locally in IndexedDB:
  pending_sync_queue

When online:
  background sync sends queued data to Laravel API
Recommended future table:

offline_sync_queue
Fields:

id
user_id
entity_type
operation_type
payload_json
status
retry_count
last_error
created_at
synced_at
14. IndexedDB Helper
File: frontend/src/pwa/offline-db.ts
import { openDB } from 'idb'

const DB_NAME = 'nixlifeos-offline-db'
const DB_VERSION = 1

export async function getOfflineDb() {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains('dashboard_cache')) {
        db.createObjectStore('dashboard_cache', {
          keyPath: 'key'
        })
      }

      if (!db.objectStoreNames.contains('sync_queue')) {
        db.createObjectStore('sync_queue', {
          keyPath: 'id',
          autoIncrement: true
        })
      }
    }
  })
}

export async function saveDashboardCache(key: string, data: unknown) {
  const db = await getOfflineDb()

  await db.put('dashboard_cache', {
    key,
    data,
    savedAt: new Date().toISOString()
  })
}

export async function getDashboardCache(key: string) {
  const db = await getOfflineDb()

  return db.get('dashboard_cache', key)
}

export async function addToSyncQueue(entityType: string, operationType: string, payload: unknown) {
  const db = await getOfflineDb()

  return db.add('sync_queue', {
    entityType,
    operationType,
    payload,
    status: 'PENDING',
    retryCount: 0,
    createdAt: new Date().toISOString()
  })
}
15. Push Notifications Architecture
Push notification flow:

User clicks Enable Notifications
        ↓
Browser asks permission
        ↓
Browser creates push subscription
        ↓
Vue sends subscription to Laravel
        ↓
Laravel stores subscription
        ↓
System event occurs
        ↓
Laravel sends push notification
        ↓
Service Worker receives push
        ↓
Notification appears on mobile/desktop
Service workers can receive push events even when the app is closed, as long as the browser supports the feature and the user has granted permission. 

15.1 Frontend Environment Variable
File: frontend/.env.production
VITE_API_BASE_URL=https://api.nixlifeos.com
VITE_PUSH_PUBLIC_VAPID_KEY=REPLACE_WITH_PUBLIC_VAPID_KEY
15.2 Push Notification Composable
File: frontend/src/composables/usePushNotifications.ts
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL
const PUBLIC_VAPID_KEY = import.meta.env.VITE_PUSH_PUBLIC_VAPID_KEY

function urlBase64ToUint8Array(base64String: string) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4)
  const base64 = (base64String + padding)
    .replace(/-/g, '+')
    .replace(/_/g, '/')

  const rawData = window.atob(base64)
  const outputArray = new Uint8Array(rawData.length)

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i)
  }

  return outputArray
}

export function usePushNotifications() {
  async function enablePushNotifications() {
    if (!('serviceWorker' in navigator)) {
      throw new Error('Service workers are not supported.')
    }

    if (!('PushManager' in window)) {
      throw new Error('Push notifications are not supported.')
    }

    const permission = await Notification.requestPermission()

    if (permission !== 'granted') {
      throw new Error('Notification permission was not granted.')
    }

    const registration = await navigator.serviceWorker.ready

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(PUBLIC_VAPID_KEY)
    })

    await axios.post(
      `${API_BASE_URL}/api/v1/push/subscriptions`,
      subscription,
      {
        headers: {
          Accept: 'application/json',
          Authorization: `Bearer ${localStorage.getItem('auth_token')}`
        }
      }
    )

    return subscription
  }

  return {
    enablePushNotifications
  }
}
15.3 Push Notification Prompt Component
File: frontend/src/components/pwa/PushNotificationPrompt.vue
<script setup lang="ts">
import { ref } from 'vue'
import { usePushNotifications } from '@/composables/usePushNotifications'

const { enablePushNotifications } = usePushNotifications()

const loading = ref(false)
const enabled = ref(false)
const error = ref<string | null>(null)

async function enable() {
  loading.value = true
  error.value = null

  try {
    await enablePushNotifications()
    enabled.value = true
  } catch (e: any) {
    error.value = e.message || 'Unable to enable notifications.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="push-card">
    <div>
      <strong>Smart Reminders</strong>
      <p>Enable notifications for tasks, finance alerts, health reminders, and project updates.</p>

      <small v-if="error" class="error">
        {{ error }}
      </small>

      <small v-if="enabled" class="success">
        Notifications enabled.
      </small>
    </div>

    <button
      :disabled="loading || enabled"
      @click="enable"
    >
      {{ enabled ? 'Enabled' : loading ? 'Enabling...' : 'Enable' }}
    </button>
  </div>
</template>

<style scoped>
.push-card {
  padding: 18px;
  border-radius: 20px;
  background: #0f172a;
  color: white;
  border: 1px solid rgba(6, 182, 212, 0.25);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

p {
  margin: 4px 0 0;
  color: #94a3b8;
  font-size: 13px;
}

button {
  border: 0;
  border-radius: 12px;
  padding: 10px 16px;
  background: linear-gradient(135deg, #06b6d4, #7c3aed);
  color: white;
  font-weight: 700;
  cursor: pointer;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  display: block;
  margin-top: 8px;
  color: #f87171;
}

.success {
  display: block;
  margin-top: 8px;
  color: #34d399;
}
</style>
16. Laravel Push Notification Backend
Install web push package.

cd /u01/nix-life-os/backend

composer require minishlink/web-push
Generate VAPID keys:

php artisan tinker
Inside Tinker:

use Minishlink\WebPush\VAPID;

VAPID::createVapidKeys();
Add to Laravel .env:

PUSH_VAPID_PUBLIC_KEY=REPLACE_WITH_PUBLIC_KEY
PUSH_VAPID_PRIVATE_KEY=REPLACE_WITH_PRIVATE_KEY
PUSH_VAPID_SUBJECT=mailto:admin@nixlifeos.com
Also copy the public key to Vue:

VITE_PUSH_PUBLIC_VAPID_KEY=REPLACE_WITH_PUBLIC_KEY
16.1 Migration
php artisan make:migration create_push_subscriptions_table
File: backend/database/migrations/xxxx_xx_xx_create_push_subscriptions_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('push_subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->text('endpoint')->unique();
            $table->text('public_key');
            $table->text('auth_token');
            $table->string('content_encoding')->default('aes128gcm');

            $table->string('browser')->nullable();
            $table->string('platform')->nullable();

            $table->timestamp('last_used_at')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('push_subscriptions');
    }
};
Run:

php artisan migrate
16.2 Model
php artisan make:model PushSubscription
File: backend/app/Models/PushSubscription.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class PushSubscription extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'endpoint',
        'public_key',
        'auth_token',
        'content_encoding',
        'browser',
        'platform',
        'last_used_at',
    ];
}
16.3 Controller
php artisan make:controller Api/V1/PushSubscriptionController
File: backend/app/Http/Controllers/Api/V1/PushSubscriptionController.php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PushSubscription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PushSubscriptionController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'endpoint' => ['required', 'string'],
            'keys.p256dh' => ['required', 'string'],
            'keys.auth' => ['required', 'string'],
            'expirationTime' => ['nullable'],
        ]);

        $subscription = PushSubscription::updateOrCreate(
            [
                'endpoint' => $validated['endpoint'],
            ],
            [
                'user_id' => $request->user()->id,
                'public_key' => $validated['keys']['p256dh'],
                'auth_token' => $validated['keys']['auth'],
                'content_encoding' => 'aes128gcm',
                'browser' => $request->userAgent(),
                'platform' => $request->header('sec-ch-ua-platform'),
                'last_used_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Push subscription saved successfully.',
            'data' => [
                'id' => $subscription->id,
            ],
        ]);
    }
}
16.4 Routes
File: backend/routes/api.php
Add inside your authenticated API group:

use App\Http\Controllers\Api\V1\PushSubscriptionController;

Route::middleware('auth:sanctum')
    ->prefix('v1')
    ->group(function () {
        Route::post('/push/subscriptions', [PushSubscriptionController::class, 'store']);
    });
16.5 Push Sending Service
php artisan make:service PushNotificationService
If your Laravel version does not have make:service, create the file manually.

File: backend/app/Services/PushNotificationService.php
<?php

namespace App\Services;

use App\Models\PushSubscription;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;

class PushNotificationService
{
    public function sendToUser(string $userId, array $payload): void
    {
        $subscriptions = PushSubscription::query()
            ->where('user_id', $userId)
            ->get();

        if ($subscriptions->isEmpty()) {
            return;
        }

        $webPush = new WebPush([
            'VAPID' => [
                'subject' => config('services.push.subject'),
                'publicKey' => config('services.push.public_key'),
                'privateKey' => config('services.push.private_key'),
            ],
        ]);

        foreach ($subscriptions as $subscription) {
            $webPush->queueNotification(
                Subscription::create([
                    'endpoint' => $subscription->endpoint,
                    'publicKey' => $subscription->public_key,
                    'authToken' => $subscription->auth_token,
                    'contentEncoding' => $subscription->content_encoding,
                ]),
                json_encode($payload)
            );
        }

        foreach ($webPush->flush() as $report) {
            if (!$report->isSuccess()) {
                logger()->warning('Push notification failed', [
                    'reason' => $report->getReason(),
                    'endpoint' => $report->getRequest()->getUri()->__toString(),
                ]);
            }
        }
    }
}
16.6 Laravel Services Config
File: backend/config/services.php
Add:

'push' => [
    'subject' => env('PUSH_VAPID_SUBJECT'),
    'public_key' => env('PUSH_VAPID_PUBLIC_KEY'),
    'private_key' => env('PUSH_VAPID_PRIVATE_KEY'),
],
16.7 Test Push Notification Command
php artisan make:command SendTestPushNotification
File: backend/app/Console/Commands/SendTestPushNotification.php
<?php

namespace App\Console\Commands;

use App\Services\PushNotificationService;
use Illuminate\Console\Command;

class SendTestPushNotification extends Command
{
    protected $signature = 'push:test {user_id}';

    protected $description = 'Send a test push notification to a user.';

    public function handle(PushNotificationService $pushNotificationService): int
    {
        $userId = $this->argument('user_id');

        $pushNotificationService->sendToUser($userId, [
            'title' => 'Nix Life OS',
            'body' => 'Your PWA push notifications are working.',
            'url' => '/dashboard',
            'icon' => '/pwa/icons/icon-192x192.png',
        ]);

        $this->info('Push notification sent.');

        return self::SUCCESS;
    }
}
Test:

php artisan push:test USER_UUID_HERE
17. Mobile Layout Requirements
The PWA should feel like a real mobile app.

Global Mobile Rules
- Bottom navigation for main modules
- Hide heavy desktop sidebar on small screens
- Use large touch targets
- Minimum button height: 44px
- Avoid hover-only interactions
- Sticky top app bar
- Mobile-safe forms
- Responsive dashboard cards
- Avoid horizontal tables on mobile
Recommended Mobile Navigation
Bottom Tabs:
1. Home
2. Health
3. Finance
4. Projects
5. AI
Secondary screens should open as internal pages:

/settings
/notifications
/profile
/reports
18. Mobile CSS Foundation
File: frontend/src/assets/pwa-mobile.css
:root {
  --safe-top: env(safe-area-inset-top);
  --safe-bottom: env(safe-area-inset-bottom);
}

html,
body,
#app {
  min-height: 100%;
  overscroll-behavior-y: none;
}

body {
  -webkit-tap-highlight-color: transparent;
}

.mobile-app-shell {
  min-height: 100vh;
  padding-top: var(--safe-top);
  padding-bottom: calc(72px + var(--safe-bottom));
}

.mobile-bottom-nav {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  padding-bottom: var(--safe-bottom);
  height: calc(64px + var(--safe-bottom));
  background: rgba(2, 6, 23, 0.96);
  backdrop-filter: blur(18px);
  border-top: 1px solid rgba(148, 163, 184, 0.15);
  display: none;
  z-index: 9000;
}

@media (max-width: 768px) {
  .desktop-sidebar {
    display: none !important;
  }

  .mobile-bottom-nav {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
  }

  .dashboard-grid {
    grid-template-columns: 1fr !important;
  }

  .page-content {
    padding: 16px !important;
  }

  button,
  .btn,
  input,
  select,
  textarea {
    min-height: 44px;
  }

  table {
    display: block;
    overflow-x: auto;
    white-space: nowrap;
  }
}
Import in main.ts:

import './assets/pwa-mobile.css'
19. App Icons and Splash Screen
You need these icons:

72x72
96x96
128x128
144x144
152x152
192x192
384x384
512x512
512x512 maskable
Recommended visual:

Dark navy background
Cyan / purple gradient N symbol
Rounded square shape
No tiny text
Large symbol centered
Safe padding for maskable icon
For splash screens, modern browsers use:

manifest background_color
manifest theme_color
app icon
app name
For better iOS support, add Apple tags in index.html.

File: frontend/index.html
Inside <head>:

<meta name="theme-color" content="#06b6d4" />

<meta name="mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-title" content="Nix Life OS" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />

<link rel="apple-touch-icon" href="/pwa/icons/icon-192x192.png" />
<link rel="mask-icon" href="/pwa/icons/icon-512x512.png" color="#06b6d4" />
20. Nginx Production Configuration
PWA files must be served with correct headers.

In your frontend Nginx config, add:

location = /manifest.webmanifest {
    add_header Content-Type application/manifest+json;
    add_header Cache-Control "public, max-age=3600";
    try_files $uri =404;
}

location = /sw.js {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Service-Worker-Allowed "/";
    try_files $uri =404;
}

location /pwa/ {
    add_header Cache-Control "public, max-age=31536000, immutable";
    try_files $uri =404;
}

location / {
    try_files $uri $uri/ /index.html;
}
Important:

Service worker file must not be aggressively cached.
Icons and static PWA assets can be cached long-term.
21. Docker Production Build
Frontend Docker build should run:

npm ci
npm run build
Then the built app should include:

dist/
├── index.html
├── manifest.webmanifest
├── sw.js
├── workbox-*.js
├── assets/
└── pwa/
Validation command:

docker exec -it nixlifeos-frontend ls -la /usr/share/nginx/html
Expected:

index.html
manifest.webmanifest
sw.js
assets
pwa
22. Security Rules
PWA security checklist:

HTTPS only
No secrets in frontend env files
No private VAPID key in Vue app
No permanent caching for sensitive APIs
No caching auth tokens
Use HttpOnly cookies if possible
Use Authorization header carefully
Clear local caches on logout
Version service worker caches
Validate push subscriptions server-side
Rate-limit push subscription endpoint
Add logout cache cleanup.

File: frontend/src/services/authService.ts
When user logs out:

export async function clearPwaDataOnLogout() {
  if ('caches' in window) {
    const cacheNames = await caches.keys()

    await Promise.all(
      cacheNames
        .filter(name => name.startsWith('nixlifeos-'))
        .map(name => caches.delete(name))
    )
  }

  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations()

    await Promise.all(
      registrations.map(registration => registration.update())
    )
  }

  localStorage.removeItem('auth_token')
}
23. API Caching Policy
Use this policy for Nix Life OS.

API Endpoint                              PWA Cache Rule
---------------------------------------------------------------
/api/v1/auth/login                        Network Only
/api/v1/auth/register                     Network Only
/api/v1/auth/logout                       Network Only
/api/v1/auth/me                           Network Only

/api/v1/dashboard/summary                 Network First, 10 minutes
/api/v1/life-balance/summary              Network First, 10 minutes

/api/v1/finance/accounts                  Network Only
/api/v1/finance/transactions              Network Only
/api/v1/finance/budgets                   Network Only

/api/v1/health/*                          Network Only or IndexedDB encrypted future
/api/v1/projects/summary                  Network First, 10 minutes
/api/v1/tasks/today                       Network First, 5 minutes

/api/v1/reference/*                       Stale While Revalidate, 24 hours
/api/v1/public/*                          Stale While Revalidate, 24 hours
/api/v1/push/subscriptions                Network Only
24. Future App Store / Play Store Packaging
Android — Recommended Path
Use:

Trusted Web Activity
Bubblewrap CLI
Google Play Console
Architecture:

Nix Life OS PWA
        ↓
Trusted Web Activity Android wrapper
        ↓
Google Play Store
        ↓
User installs native-looking Android app
        ↓
App opens https://app.nixlifeos.com
Requirements:

Valid PWA manifest
Service worker
HTTPS
App icons
Digital Asset Links
Play Store developer account
Privacy policy
Production domain ownership
Future files:

public/.well-known/assetlinks.json
iOS — Recommended Path
For iOS App Store, use:

Capacitor wrapper
Architecture:

Nix Life OS Vue app
        ↓
Capacitor iOS project
        ↓
Xcode build
        ↓
Apple App Store
Requirements:

Apple Developer Account
App Store screenshots
Privacy labels
Push notification entitlement if native push is used
App icon set
iOS splash screen
25. PWA Testing Commands
Build Frontend
cd /u01/nix-life-os/frontend

npm run build
Preview Locally
npm run preview -- --host 0.0.0.0
Production Rebuild
cd /u01/nix-life-os

docker compose --env-file .env.docker -f docker-compose.prod.yml build frontend

docker compose --env-file .env.docker -f docker-compose.prod.yml up -d frontend
Validate Files
curl -I https://app.nixlifeos.com/manifest.webmanifest

curl -I https://app.nixlifeos.com/sw.js

curl -I https://app.nixlifeos.com/pwa/offline.html
Expected for manifest:

HTTP/2 200
content-type: application/manifest+json
Expected for service worker:

HTTP/2 200
cache-control: no-cache, no-store, must-revalidate
service-worker-allowed: /
26. Browser Validation Checklist
Open Chrome DevTools:

Application → Manifest
Application → Service Workers
Application → Cache Storage
Application → IndexedDB
Lighthouse → PWA audit
Validate:

Manifest detected
Icons detected
Service worker registered
Offline page loads
App is installable
Install prompt appears
Dashboard shell loads offline
Static files cached
Sensitive APIs not cached
Push notification permission works
Push subscription saved to Laravel
27. Production Acceptance Checklist
[ ] manifest.webmanifest generated successfully
[ ] sw.js generated successfully
[ ] Service worker registered in production
[ ] Offline fallback page working
[ ] App install prompt working on Android Chrome
[ ] App can be added to iPhone home screen
[ ] App icons appear correctly
[ ] Maskable icon tested
[ ] Dashboard loads quickly after first visit
[ ] Offline banner appears when network is disconnected
[ ] New version update prompt appears after deployment
[ ] Auth APIs are not cached
[ ] Finance APIs are not cached
[ ] Health APIs are not cached
[ ] Dashboard summary uses Network First cache
[ ] Reference APIs use Stale While Revalidate
[ ] Push subscription API created
[ ] Push notification test command works
[ ] Nginx headers configured
[ ] Lighthouse PWA score reviewed
[ ] Future Android TWA path documented
[ ] Future iOS Capacitor path documented
28. Final Recommended Implementation Order
1. Install vite-plugin-pwa and workbox-window
2. Add PWA config to vite.config.ts
3. Create PWA icons and screenshots
4. Add offline.html
5. Add custom service worker sw.ts
6. Register service worker in main.ts
7. Add InstallPrompt.vue
8. Add OfflineBanner.vue
9. Add UpdateAvailablePrompt.vue
10. Add mobile PWA CSS
11. Configure Nginx headers
12. Rebuild frontend Docker image
13. Validate manifest and service worker
14. Test install prompt
15. Test offline mode
16. Add Laravel push subscription table
17. Add push subscription endpoint
18. Add push notification service
19. Test push notifications
20. Prepare future Android / iOS packaging
Final Result
After this step, Nix Life OS will support:

Installable web app
Mobile app-like experience
Offline fallback
Cached app shell
Smart API caching
Update prompt
Offline banner
App icons
Splash screen behavior
Push notification foundation
Future Play Store packaging
Future App Store packaging
This gives Nix Life OS a strong production PWA foundation before moving into native mobile packaging.


