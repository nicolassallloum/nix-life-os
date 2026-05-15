import api from './api'

const aiRecommendationService = {
  async generateRecommendations(payload = {}) {
    const response = await api.post('/ai/recommendations/generate', {
      store_daily_score: payload.store_daily_score ?? true,
      date: payload.date ?? null,
    })

    return response.data
  },

  async getRecommendations(params = {}) {
    const response = await api.get('/ai/recommendations', {
      params: {
        module: params.module || undefined,
        status: params.status || undefined,
        severity: params.severity || undefined,
        type: params.type || undefined,
        active_only: params.active_only ?? undefined,
        limit: params.limit || 50,
      },
    })

    return response.data
  },

  async getDailyScores(params = {}) {
    const response = await api.get('/ai/scores/daily', {
      params: {
        from_date: params.from_date || undefined,
        to_date: params.to_date || undefined,
        limit: params.limit || 30,
        generate_today: params.generate_today ?? false,
      },
    })

    return response.data
  },

  async markViewed(recommendationId) {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/viewed`)
    return response.data
  },

  async acceptRecommendation(recommendationId) {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/accept`)
    return response.data
  },

  async dismissRecommendation(recommendationId, reason = null) {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/dismiss`, {
      reason,
    })

    return response.data
  },

  async completeRecommendation(recommendationId) {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/complete`)
    return response.data
  },

  async submitFeedback(recommendationId, payload) {
    const response = await api.post(`/ai/recommendations/${recommendationId}/feedback`, {
      feedback_type: payload.feedback_type,
      feedback_value: payload.feedback_value ?? null,
      feedback_comment: payload.feedback_comment ?? null,
    })

    return response.data
  },
}

export default aiRecommendationService