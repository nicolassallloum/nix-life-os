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