export function registerServiceWorker(): void {
  if (!('serviceWorker' in navigator)) {
    console.warn('[PWA] Service workers are not supported.');
    return;
  }

  window.addEventListener('load', async () => {
    try {
      const registration: ServiceWorkerRegistration =
        await navigator.serviceWorker.register('/sw.js', {
          scope: '/'
        });

      console.log('[PWA] Service worker registered:', registration.scope);

      registration.addEventListener('updatefound', () => {
        const newWorker = registration.installing;

        if (!newWorker) {
          return;
        }

        newWorker.addEventListener('statechange', () => {
          if (
            newWorker.state === 'installed' &&
            navigator.serviceWorker.controller
          ) {
            window.dispatchEvent(
              new CustomEvent<ServiceWorkerRegistration>('pwa-update-available', {
                detail: registration
              })
            );
          }
        });
      });
    } catch (error) {
      console.error('[PWA] Service worker registration failed:', error);
    }
  });
}

export function updateServiceWorker(
  registration: ServiceWorkerRegistration | null
): void {
  if (!registration || !registration.waiting) {
    return;
  }

  registration.waiting.postMessage({
    type: 'SKIP_WAITING'
  });
}

export async function clearPwaCaches(): Promise<void> {
  if (!('serviceWorker' in navigator)) {
    return;
  }

  const registration = await navigator.serviceWorker.getRegistration();

  if (registration?.active) {
    registration.active.postMessage({
      type: 'CLEAR_CACHE'
    });
  }
}
