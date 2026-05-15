import api from './api'

const cleanParams = (params = {}) => {
  const cleaned = {}

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      cleaned[key] = value
    }
  })

  return cleaned
}

const aiRecommendationService = {
  async generateRecommendations(payload = {}) {
    const body = {
      store_daily_score: payload.store_daily_score ?? true,
    }

    if (payload.date) {
      body.date = payload.date
    }

    const response = await api.post('/ai/recommendations/generate', body)

    return response.data
  },

  async getRecommendations(params = {}) {
    const queryParams = cleanParams({
      module: params.module || undefined,
      status: params.status || undefined,
      severity: params.severity || undefined,
      type: params.type || undefined,
      limit: params.limit || 50,

      // IMPORTANT:
      // Send active_only only when true.
      // Do not send active_only=false because Laravel validates it as string "false".
      active_only: params.active_only === true ? 1 : undefined,
    })

    const response = await api.get('/ai/recommendations', {
      params: queryParams,
    })

    return response.data
  },

  async getDailyScores(params = {}) {
    const queryParams = cleanParams({
      from_date: params.from_date || undefined,
      to_date: params.to_date || undefined,
      limit: params.limit || 30,

      // IMPORTANT:
      // Send generate_today only when true.
      // Do not send generate_today=false because Laravel validates it as string "false".
      generate_today: params.generate_today === true ? 1 : undefined,
    })

    const response = await api.get('/ai/scores/daily', {
      params: queryParams,
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