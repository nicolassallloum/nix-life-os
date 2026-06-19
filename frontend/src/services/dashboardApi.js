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
  const finance = data.finance || {}
  const health = data.health || {}
  const projects = data.projects || {}

  const flattened = {
    ...data,
    total_balance: data.total_balance ?? finance.total_balance ?? 0,
    income: data.income ?? finance.income ?? finance.monthly_income ?? finance.total_income ?? 0,
    monthly_expense:
      data.monthly_expense ??
      finance.monthly_expense ??
      finance.monthly_expenses ??
      finance.total_expenses ??
      0,
    savings_rate: data.savings_rate ?? finance.savings_rate ?? 0,
    today_steps: data.today_steps ?? health.today_steps ?? 0,
    today_calories: data.today_calories ?? health.today_calories ?? 0,
    water_intake_ml: data.water_intake_ml ?? health.today_water_ml ?? health.water_intake_ml ?? 0,
    current_weight_kg: data.current_weight_kg ?? health.current_weight_kg ?? health.weight_kg ?? 0,
    active_projects: data.active_projects ?? projects.active_projects ?? 0,
    total_projects: data.total_projects ?? projects.total_projects ?? 0,
    completed_projects: data.completed_projects ?? projects.completed_projects ?? 0,
    average_progress: data.average_progress ?? projects.average_progress ?? 0,
  }

  return {
    success: payload.success ?? payload.status ?? true,
    status: payload.status ?? payload.success ?? true,
    message: payload.message || 'Dashboard summary loaded successfully.',
    data: flattened,
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
  const response = await cachedGet('/dashboard/recent-activity', 'Dashboard recent activity')
  return response?.data || emptyActivityResponse()
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
  return getDashboardRecentActivity()
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
