const CACHE_NAME = 'nix-life-os-cache-v20260529-01'

const OFFLINE_URL = '/pwa/offline.html'

const STATIC_ASSETS = [
  '/',
  '/manifest.webmanifest',
  '/pwa/offline.html'
]

self.addEventListener('install', (event) => {
  self.skipWaiting()

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS).catch(() => Promise.resolve())
    })
  )
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => cacheName !== CACHE_NAME)
          .map((cacheName) => caches.delete(cacheName))
      )
    }).then(() => self.clients.claim())
  )
})

self.addEventListener('fetch', (event) => {
  const request = event.request
  const url = new URL(request.url)

  if (request.method !== 'GET') {
    return
  }

  if (url.pathname.startsWith('/api/')) {
    return
  }

  if (url.origin !== self.location.origin) {
    return
  }

  event.respondWith(
    fetch(request)
      .then((networkResponse) => {
        if (
          networkResponse &&
          networkResponse.status === 200 &&
          networkResponse.type === 'basic'
        ) {
          const responseToCache = networkResponse.clone()

          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache).catch(() => {})
          })
        }

        return networkResponse
      })
      .catch(async () => {
        const cachedResponse = await caches.match(request)

        if (cachedResponse) {
          return cachedResponse
        }

        if (request.mode === 'navigate') {
          return caches.match(OFFLINE_URL)
        }

        return new Response('', {
          status: 503,
          statusText: 'Service Unavailable'
        })
      })
  )
})