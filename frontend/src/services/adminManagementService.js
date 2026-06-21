import api from './api'

export default {
  async getDashboardSummary() {
    const response = await api.get('/admin/dashboard/summary')
    return response.data
  },

  async getUsers(params = {}) {
    const response = await api.get('/admin/users', { params })
    return response.data
  },

  async createUser(payload) {
    const response = await api.post('/admin/users', payload)
    return response.data
  },

  async updateUser(id, payload) {
    const response = await api.put(`/admin/users/${id}`, payload)
    return response.data
  },

  async changePassword(id, payload) {
    const response = await api.post(`/admin/users/${id}/change-password`, payload)
    return response.data
  },

  async activateUser(id) {
    const response = await api.post(`/admin/users/${id}/activate`)
    return response.data
  },

  async deactivateUser(id) {
    const response = await api.post(`/admin/users/${id}/deactivate`)
    return response.data
  },

  async getUsageSummary() {
    const response = await api.get('/admin/usage/summary')
    return response.data
  },

  async getApplicationDataSummary() {
    const response = await api.get('/admin/application-data/summary')
    return response.data
  },

  async getAuditLogs(params = {}) {
    const response = await api.get('/admin/audit-logs', { params })
    return response.data
  },

  async getPointLevels() {
    const response = await api.get('/admin/point-levels')
    return response.data
  },

  async getPointSummary() {
    const response = await api.get('/admin/point-summary')
    return response.data
  },

  async getPointIdeas(params = {}) {
    const response = await api.get('/admin/point-ideas', { params })
    return response.data
  },

  async createPointIdea(payload) {
    const response = await api.post('/admin/point-ideas', payload)
    return response.data
  },

  async updatePointIdea(id, payload) {
    const response = await api.put(`/admin/point-ideas/${id}`, payload)
    return response.data
  },

  async deletePointIdea(id) {
    const response = await api.delete(`/admin/point-ideas/${id}`)
    return response.data
  },
}
