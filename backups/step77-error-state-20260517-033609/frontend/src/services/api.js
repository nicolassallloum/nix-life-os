import axios from 'axios'
import {
  clearAuthSession,
  getAuthToken,
  saveAuthSession,
  AUTH_TOKEN_KEYS,
  AUTH_USER_KEYS,
} from '@/utils/auth'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1'

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
        window.location.href = `/login?redirect=${encodeURIComponent(
          window.location.pathname + window.location.search,
        )}`
      }
    }

    if (status === 403 && window.location.pathname !== '/unauthorized') {
      window.location.href = '/unauthorized'
    }

    return Promise.reject(error)
  },
)

export {
  AUTH_TOKEN_KEYS,
  AUTH_USER_KEYS,
  clearAuthSession,
  getAuthToken,
  saveAuthSession,
}

export default api
