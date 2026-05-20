import axios, { type AxiosError, type AxiosResponse } from 'axios'
import {
  clearAuthSession,
  getAuthToken,
  saveAuthSession,
  AUTH_TOKEN_KEYS,
  AUTH_USER_KEYS,
} from '@/utils/auth'

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'
export const API_TIMEOUT_MS = Number(import.meta.env.VITE_API_TIMEOUT_MS || 15000)

type ValidationErrors = Record<string, string[] | string>

type ErrorPayload = {
  message?: string
  error?: {
    code?: string
    message?: string
  }
  code?: string
  errors?: ValidationErrors
  request_id?: string
}

export type NormalizedApiError = Error & {
  status: number
  code: string | null
  errors: ValidationErrors
  data: ErrorPayload
  isTimeout: boolean
  isNetworkError: boolean
  requestId: string | null
  originalError: unknown
}

function firstValidationError(errors?: ValidationErrors): string | null {
  if (!errors || typeof errors !== 'object') return null

  const firstKey = Object.keys(errors)[0]
  const firstValue = firstKey ? errors[firstKey] : null

  if (Array.isArray(firstValue)) return firstValue[0] || null
  if (typeof firstValue === 'string') return firstValue

  return null
}

function hasAxiosShape(error: unknown): error is AxiosError<ErrorPayload> {
  return Boolean(error && typeof error === 'object' && ('response' in error || 'request' in error || 'code' in error))
}

export function normalizeApiError(
  error: unknown,
  fallbackMessage = 'Something went wrong. Please try again.',
): NormalizedApiError {
  const axiosError = hasAxiosShape(error) ? error : null
  const response = axiosError?.response as AxiosResponse<ErrorPayload> | undefined
  const status = response?.status || (error as { status?: number })?.status || 0
  const data = response?.data || (error as { data?: ErrorPayload })?.data || {}
  const code = data?.error?.code || data?.code || null
  const validationMessage = firstValidationError(data?.errors || (error as { errors?: ValidationErrors })?.errors)

  let message =
    validationMessage ||
    data?.message ||
    data?.error?.message ||
    (error as { message?: string })?.message ||
    fallbackMessage

  if (axiosError?.code === 'ECONNABORTED') {
    message = 'Request timed out. Please try again.'
  } else if (!response && axiosError?.request) {
    message = 'Unable to connect to the server. Please check your connection and try again.'
  } else if (status === 401) {
    message = 'Your session expired. Please login again.'
  } else if (status === 403) {
    message = 'You do not have permission to access this page.'
  } else if (status === 404) {
    message = 'The requested resource was not found.'
  } else if (status === 422) {
    message = message || 'Please fix the validation errors.'
  } else if (status === 500) {
    message = 'Server error. Please try again later.'
  } else if (status === 503 || status === 504) {
    message = 'Service is temporarily unavailable. Please try again shortly.'
  }

  const normalized = new Error(message) as NormalizedApiError
  normalized.name = 'NixApiError'
  normalized.status = status
  normalized.code = code
  normalized.errors = data?.errors || (error as { errors?: ValidationErrors })?.errors || {}
  normalized.data = data
  normalized.isTimeout = axiosError?.code === 'ECONNABORTED'
  normalized.isNetworkError = !response && Boolean(axiosError?.request)
  normalized.requestId = data?.request_id || String(response?.headers?.['x-request-id'] || '') || null
  normalized.originalError = error

  return normalized
}

export function getApiErrorMessage(
  error: unknown,
  fallbackMessage = 'Something went wrong. Please try again.',
): string {
  return normalizeApiError(error, fallbackMessage).message
}

function handleAuthRedirect(status: number): void {
  const currentPath = window.location.pathname + window.location.search

  if (status === 401) {
    clearAuthSession()

    if (window.location.pathname !== '/login') {
      window.location.href = `/login?redirect=${encodeURIComponent(currentPath)}`
    }
  }

  if (status === 403 && window.location.pathname !== '/unauthorized') {
    window.location.href = '/unauthorized'
  }
}

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT_MS,
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

    config.headers['X-Requested-With'] = 'XMLHttpRequest'

    return config
  },
  (error) => Promise.reject(normalizeApiError(error)),
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const normalizedError = normalizeApiError(error)
    handleAuthRedirect(normalizedError.status)

    return Promise.reject(normalizedError)
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
