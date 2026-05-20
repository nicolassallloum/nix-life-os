import api from './api'

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
