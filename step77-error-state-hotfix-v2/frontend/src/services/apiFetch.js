import { API_BASE_URL, API_TIMEOUT_MS, clearAuthSession, getAuthToken, normalizeApiError } from './api'

function buildUrl(path) {
  if (/^https?:\/\//i.test(path)) return path
  return `${API_BASE_URL}${path.startsWith('/') ? path : `/${path}`}`
}

export async function apiFetch(path, options = {}) {
  const controller = new AbortController()
  const timeoutId = window.setTimeout(() => controller.abort(), options.timeout || API_TIMEOUT_MS)
  const token = getAuthToken()

  try {
    const response = await fetch(buildUrl(path), {
      ...options,
      signal: options.signal || controller.signal,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options.headers || {}),
      },
    })

    const data = await response.json().catch(() => null)

    if (!response.ok) {
      const error = new Error(data?.message || 'Request failed.')
      error.status = response.status
      error.data = data || {}
      error.errors = data?.errors || {}

      if (response.status === 401) {
        clearAuthSession()
        if (window.location.pathname !== '/login') {
          window.location.href = `/login?redirect=${encodeURIComponent(window.location.pathname + window.location.search)}`
        }
      }

      if (response.status === 403 && window.location.pathname !== '/unauthorized') {
        window.location.href = '/unauthorized'
      }

      throw normalizeApiError(error)
    }

    return data
  } catch (error) {
    if (error?.name === 'AbortError') {
      const timeoutError = new Error('Request timed out. Please try again.')
      timeoutError.code = 'ECONNABORTED'
      throw normalizeApiError(timeoutError)
    }

    throw normalizeApiError(error)
  } finally {
    window.clearTimeout(timeoutId)
  }
}

export default apiFetch
