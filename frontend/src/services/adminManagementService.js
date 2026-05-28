import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

export default {
  async getDashboardSummary() {
    const response = await axios.get(`${API_BASE_URL}/admin/dashboard/summary`)
    return response.data
  },

  async getUsers(params = {}) {
    const response = await axios.get(`${API_BASE_URL}/admin/users`, { params })
    return response.data
  },

  async createUser(payload) {
    const response = await axios.post(`${API_BASE_URL}/admin/users`, payload)
    return response.data
  },

  async updateUser(id, payload) {
    const response = await axios.put(`${API_BASE_URL}/admin/users/${id}`, payload)
    return response.data
  },

  async changePassword(id, payload) {
    const response = await axios.post(`${API_BASE_URL}/admin/users/${id}/change-password`, payload)
    return response.data
  },

  async activateUser(id) {
    const response = await axios.post(`${API_BASE_URL}/admin/users/${id}/activate`)
    return response.data
  },

  async deactivateUser(id) {
    const response = await axios.post(`${API_BASE_URL}/admin/users/${id}/deactivate`)
    return response.data
  },

  async getUsageSummary() {
    const response = await axios.get(`${API_BASE_URL}/admin/usage/summary`)
    return response.data
  },

  async getApplicationDataSummary() {
    const response = await axios.get(`${API_BASE_URL}/admin/application-data/summary`)
    return response.data
  },

  async getAuditLogs(params = {}) {
    const response = await axios.get(`${API_BASE_URL}/admin/audit-logs`, { params })
    return response.data
  },
}