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