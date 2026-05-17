import api from './api'

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
  const response = await api.get('/dashboard/summary')
  return normalizeDashboardSummary(response)
}

export async function getDashboardKpis() {
  const response = await api.get('/dashboard/summary')
  return normalizeDashboardSummary(response)
}

export async function getDashboardRecentActivity() {
  return emptyActivityResponse()
}

export async function getDashboardCharts() {
  const response = await api.get('/dashboard/summary')
  return normalizeDashboardSummary(response)
}

/**
 * Unified dashboard aliases used by UnifiedDashboardView.vue
 */
export async function getUnifiedDashboardSummary() {
  const response = await api.get('/dashboard/summary')
  return normalizeDashboardSummary(response)
}

export async function getUnifiedDashboardKpis() {
  const response = await api.get('/dashboard/summary')
  return normalizeDashboardSummary(response)
}

export async function getUnifiedDashboardActivity() {
  return emptyActivityResponse()
}

export default {
  getDashboardSummary,
  getDashboardKpis,
  getDashboardRecentActivity,
  getDashboardCharts,
  getUnifiedDashboardSummary,
  getUnifiedDashboardKpis,
  getUnifiedDashboardActivity,
}
