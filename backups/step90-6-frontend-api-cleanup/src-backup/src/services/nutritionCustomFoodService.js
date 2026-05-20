import api from './api'

export const nutritionCustomFoodService = {
  async getFoods(params = {}) {
    const response = await api.get('/v1/nutrition/custom-foods', { params })
    return response.data
  },

  async getFood(id) {
    const response = await api.get(`/v1/nutrition/custom-foods/${id}`)
    return response.data
  },

  async createFood(payload) {
    const response = await api.post('/v1/nutrition/custom-foods', payload)
    return response.data
  },

  async updateFood(id, payload) {
    const response = await api.put(`/v1/nutrition/custom-foods/${id}`, payload)
    return response.data
  },

  async deleteFood(id) {
    const response = await api.delete(`/v1/nutrition/custom-foods/${id}`)
    return response.data
  }
}
