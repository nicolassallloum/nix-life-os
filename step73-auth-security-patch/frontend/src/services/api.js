import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1'

export const AUTH_TOKEN_KEYS = ['token', 'auth_token', 'access_token', 'nix_token']
export const AUTH_USER_KEYS = ['user', 'nix_user']

export function getAuthToken() {
  for (const key of AUTH_TOKEN_KEYS) {
    const value = localStorage.getItem(key)
    if (value) return value
  }

  return null
}

export function saveAuthSession(token, user = null) {
  if (!token) return

  localStorage.setItem('token', token)
  localStorage.setItem('auth_token', token)
  localStorage.setItem('access_token', token)
  localStorage.setItem('nix_token', token)

  if (user) {
    const serializedUser = JSON.stringify(user)
    localStorage.setItem('user', serializedUser)
    localStorage.setItem('nix_user', serializedUser)
  }
}

export function clearAuthSession() {
  for (const key of AUTH_TOKEN_KEYS) {
    localStorage.removeItem(key)
  }

  for (const key of AUTH_USER_KEYS) {
    localStorage.removeItem(key)
  }
}

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use(
  (config) => {
    const token = getAuthToken()

    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    return config
  },
  (error) => Promise.reject(error),
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status

    if (status === 401) {
      clearAuthSession()

      if (window.location.pathname !== '/login') {
        window.location.href = `/login?redirect=${encodeURIComponent(window.location.pathname)}`
      }
    }

    return Promise.reject(error)
  },
)

export default api
