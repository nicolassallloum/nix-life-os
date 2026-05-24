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