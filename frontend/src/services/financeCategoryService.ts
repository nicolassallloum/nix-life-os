import apiClient from './api'

export interface FinanceCategoryPayload {
  name: string
  type: 'income' | 'expense'
  icon?: string | null
  color?: string | null
  status?: 'active' | 'inactive'
}

export const financeCategoryService = {
  list(params = {}) {
    return apiClient.get('/finance/categories', { params })
  },

  create(payload: FinanceCategoryPayload) {
    return apiClient.post('/finance/categories', payload)
  },

  update(id: number, payload: Partial<FinanceCategoryPayload>) {
    return apiClient.put(`/finance/categories/${id}`, payload)
  },

  delete(id: number) {
    return apiClient.delete(`/finance/categories/${id}`)
  },
}
