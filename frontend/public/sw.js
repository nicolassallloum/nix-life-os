
/* 
|--------------------------------------------------------------------------
| Nix Life OS Service Worker
|--------------------------------------------------------------------------
| Purpose:
| - Cache core frontend assets
| - Provide offline fallback
| - Use safe API caching
| - Clear old caches on deployment
|--------------------------------------------------------------------------
*/

const APP_VERSION = 'nix-life-os-v101-20260524';

const STATIC_CACHE = `${APP_VERSION}-static`;
const RUNTIME_CACHE = `${APP_VERSION}-runtime`;
const API_CACHE = `${APP_VERSION}-api`;

const OFFLINE_URL = '/pwa/offline.html';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.webmanifest',
  OFFLINE_URL
];

/**
 * Install Event
 * Pre-cache required static assets.
 */
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

/**
 * Activate Event
 * Remove old cache versions.
 */
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return Promise.all(
          cacheNames
            .filter(cacheName => {
              return (
                cacheName.startsWith('nix-life-os-') &&
                ![
                  STATIC_CACHE,
                  RUNTIME_CACHE,
                  API_CACHE
                ].includes(cacheName)
              );
            })
            .map(cacheName => caches.delete(cacheName))
        );
      })
      .then(() => self.clients.claim())
  );
});

/**
 * Fetch Event
 * Route requests by type.
 */
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);

  /**
   * Ignore non-GET requests.
   * Never cache POST, PUT, PATCH, DELETE.
   */
  if (request.method !== 'GET') {
    return;
  }

  /**
   * Ignore browser extensions and unsupported schemes.
   */
  if (!url.protocol.startsWith('http')) {
    return;
  }

  /**
   * API requests.
   */
  if (url.pathname.startsWith('/api/') || url.hostname.startsWith('api.')) {
    event.respondWith(handleApiRequest(request));
    return;
  }

  /**
   * Navigation requests.
   * Used when opening pages directly or refreshing Vue routes.
   */
  if (request.mode === 'navigate') {
    event.respondWith(handleNavigationRequest(request));
    return;
  }

  /**
   * Static assets.
   */
  if (isStaticAsset(request)) {
    event.respondWith(handleStaticAssetRequest(request));
    return;
  }

  /**
   * Default runtime strategy.
   */
  event.respondWith(handleRuntimeRequest(request));
});

/**
 * API Strategy:
 * Network first, fallback to cache only for safe public GET APIs.
 *
 * Important:
 * Do not blindly cache authenticated user data.
 */
async function handleApiRequest(request) {
  const url = new URL(request.url);

  const isCacheableApi =
    url.pathname.includes('/dashboard/summary') ||
    url.pathname.includes('/life-balance/summary');

  const hasAuthorization =
    request.headers.has('Authorization') ||
    request.headers.has('authorization');

  try {
    const networkResponse = await fetch(request);

    /**
     * Only cache successful GET API responses.
     * Avoid caching authenticated sensitive data unless explicitly allowed.
     */
    if (
      networkResponse &&
      networkResponse.ok &&
      isCacheableApi &&
      !hasAuthorization
    ) {
      const cache = await caches.open(API_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    if (isCacheableApi && !hasAuthorization) {
      const cachedResponse = await caches.match(request);

      if (cachedResponse) {
        return cachedResponse;
      }
    }

    return new Response(
      JSON.stringify({
        success: false,
        message: 'You are offline. API data is not available.',
        offline: true
      }),
      {
        status: 503,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
  }
}

/**
 * Navigation Strategy:
 * Network first, fallback to cached app shell, then offline page.
 */
async function handleNavigationRequest(request) {
  try {
    const networkResponse = await fetch(request);

    const cache = await caches.open(RUNTIME_CACHE);
    cache.put(request, networkResponse.clone());

    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
      return cachedResponse;
    }

    const cachedIndex = await caches.match('/index.html');

    if (cachedIndex) {
      return cachedIndex;
    }

    return caches.match(OFFLINE_URL);
  }
}

/**
 * Static Asset Strategy:
 * Cache first, update in background.
 */
async function handleStaticAssetRequest(request) {
  const cachedResponse = await caches.match(request);

  const fetchPromise = fetch(request)
    .then(networkResponse => {
      if (networkResponse && networkResponse.ok) {
        const cache = caches.open(STATIC_CACHE);
        cache.then(openCache => {
          openCache.put(request, networkResponse.clone());
        });
      }

      return networkResponse;
    })
    .catch(() => null);

  return cachedResponse || fetchPromise || caches.match(OFFLINE_URL);
}

/**
 * Runtime Strategy:
 * Network first, fallback to runtime cache.
 */
async function handleRuntimeRequest(request) {
  try {
    const networkResponse = await fetch(request);

    if (networkResponse && networkResponse.ok) {
      const cache = await caches.open(RUNTIME_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
      return cachedResponse;
    }

    return caches.match(OFFLINE_URL);
  }
}

/**
 * Detect static frontend assets.
 */
function isStaticAsset(request) {
  const destination = request.destination;

  return [
    'style',
    'script',
    'image',
    'font',
    'manifest'
  ].includes(destination);
}

/**
 * Receive messages from frontend.
 */
self.addEventListener('message', event => {
  if (!event.data) {
    return;
  }

  if (event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(clearAllCaches());
  }
});

/**
 * Clear all Nix Life OS caches.
 */
async function clearAllCaches() {
  const cacheNames = await caches.keys();

  await Promise.all(
    cacheNames
      .filter(cacheName => cacheName.startsWith('nix-life-os-'))
      .map(cacheName => caches.delete(cacheName))
  );
}
self.addEventListener('push', (event) => {
  if (!event.data) {
    return
  }

  const data = event.data.json()

  const title = data.title || 'Nix Life OS'
  const options = {
    body: data.body || '',
    icon: data.icon || '/icons/icon-192x192.png',
    badge: data.badge || '/icons/badge-72x72.png',
    data: {
      url: data.action_url || '/',
      notification_id: data.notification_id || null,
      payload: data.payload || {},
    },
    vibrate: [100, 50, 100],
  }

  event.waitUntil(
    self.registration.showNotification(title, options)
  )
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()

  const targetUrl = event.notification.data?.url || '/'

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.navigate(targetUrl)
          return client.focus()
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl)
      }

      return null
    })
  )
})
