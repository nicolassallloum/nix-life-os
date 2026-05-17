import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const token =
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token')

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

export const financeService = {
  async getAccounts() {
    const response = await api.get('/finance/accounts')
    return response.data
  },

  async getTransactions(params = {}) {
    const response = await api.get('/finance/transactions', { params })
    return response.data
  },

  async getBudgets(params = {}) {
    const response = await api.get('/finance/budgets', { params })
    return response.data
  },

  async getAIInsights(params: { type?: string } = {}) {
    const response = await api.get('/finance/ai-insights', { params })
    return response.data
  },
}

export default financeService
