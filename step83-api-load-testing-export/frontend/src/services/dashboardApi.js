import api from './api'

const inflight = new Map()
const cache = new Map()
const DEFAULT_CACHE_MS = 15000

function nowMs() {
  return typeof performance !== 'undefined' ? performance.now() : Date.now()
}

function logPerf(label, start, payload) {
  const duration = Math.round((nowMs() - start) * 100) / 100

  if (import.meta.env.DEV) {
    console.info(`[STEP82] ${label} loaded in ${duration} ms`, {
      bytesApprox: JSON.stringify(payload || {}).length,
    })
  }
}

async function cachedGet(endpoint, label, ttlMs = DEFAULT_CACHE_MS) {
  const cacheKey = `${endpoint}`
  const cached = cache.get(cacheKey)

  if (cached && Date.now() - cached.createdAt < ttlMs) {
    return cached.value
  }

  if (inflight.has(cacheKey)) {
    return inflight.get(cacheKey)
  }

  const start = nowMs()
  const request = api.get(endpoint)
    .then((response) => {
      logPerf(label, start, response?.data)
      cache.set(cacheKey, {
        createdAt: Date.now(),
        value: response,
      })
      return response
    })
    .finally(() => {
      inflight.delete(cacheKey)
    })

  inflight.set(cacheKey, request)
  return request
}

function normalizeDashboardSummary(response) {
  const payload = response?.data || {}
  const data = payload.data || payload

  return {
    success: payload.success ?? payload.status ?? true,
    status: payload.status ?? payload.success ?? true,
    message: payload.message || 'Dashboard summary loaded successfully.',
    data,
  }
}

function emptyActivityResponse() {
  return {
    success: true,
    status: true,
    message: 'Recent activity fallback loaded successfully.',
    data: [],
  }
}

export async function getDashboardSummary() {
  const response = await cachedGet('/dashboard/summary', 'Dashboard summary')
  return normalizeDashboardSummary(response)
}

export async function getDashboardKpis() {
  return getDashboardSummary()
}

export async function getDashboardRecentActivity() {
  return emptyActivityResponse()
}

export async function getDashboardCharts() {
  return getDashboardSummary()
}

export async function getHealthDashboardSummary() {
  const response = await cachedGet('/health/dashboard', 'Health dashboard')
  return response?.data || response
}

export async function getProjectsDashboardSummary() {
  const response = await cachedGet('/projects/dashboard', 'Projects dashboard')
  return response?.data || response
}

export async function getProductivityDashboardSummary() {
  const response = await cachedGet('/productivity/dashboard', 'Productivity dashboard')
  return response?.data || response
}

export async function getUnifiedDashboardSummary() {
  return getDashboardSummary()
}

export async function getUnifiedDashboardKpis() {
  return getDashboardSummary()
}

export async function getUnifiedDashboardActivity() {
  return emptyActivityResponse()
}

export function clearDashboardApiCache() {
  cache.clear()
  inflight.clear()
}

export default {
  getDashboardSummary,
  getDashboardKpis,
  getDashboardRecentActivity,
  getDashboardCharts,
  getHealthDashboardSummary,
  getProjectsDashboardSummary,
  getProductivityDashboardSummary,
  getUnifiedDashboardSummary,
  getUnifiedDashboardKpis,
  getUnifiedDashboardActivity,
  clearDashboardApiCache,
}
