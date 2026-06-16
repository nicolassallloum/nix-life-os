import api from './api'

const nutritionService = {
  searchFoods(query) {
    return api.get('/nutrition/foods/search', {
      params: { q: query, query }
    })
  },

  getFood(id) {
    return api.get(`/nutrition/foods/${id}`)
  },

  getFoodServings(id) {
    return api.get(`/nutrition/foods/${id}/servings`)
  },

  getNutritionLogs(date) {
    return api.get('/health/nutrition', {
      params: { date }
    })
  },

  getNutritionSummary(date) {
    return api.get('/health/nutrition/summary', {
      params: { date }
    })
  },

  createNutritionLog(payload) {
    return api.post('/health/nutrition', payload)
  },

  updateNutritionLog(id, payload) {
    return api.put(`/health/nutrition/${id}`, payload)
  },

  deleteNutritionLog(id) {
    return api.delete(`/health/nutrition/${id}`)
  }
}

export default nutritionService
