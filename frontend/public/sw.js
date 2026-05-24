const CACHE_NAME = 'nixlifeos-cache-v1'

const APP_SHELL = [
  '/',
  '/index.html',
  '/manifest.webmanifest',
  '/pwa/offline.html',
  '/favicon.ico'
]

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL))
  )

  self.skipWaiting()
})

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key => key !== CACHE_NAME)
          .map(key => caches.delete(key))
      )
    )
  )

  self.clients.claim()
})

self.addEventListener('fetch', event => {
  const request = event.request
  const url = new URL(request.url)

  if (request.method !== 'GET') {
    return
  }

  if (url.pathname.startsWith('/api/') || url.hostname === 'api.nixlifeos.com') {
    return
  }

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(() => caches.match('/pwa/offline.html'))
    )
    return
  }

  event.respondWith(
    caches.match(request).then(cachedResponse => {
      return (
        cachedResponse ||
        fetch(request).then(networkResponse => {
          return caches.open(CACHE_NAME).then(cache => {
            cache.put(request, networkResponse.clone())
            return networkResponse
          })
        })
      )
    })
  )
})
