import api from './api'

function removeEmptyParams(params = {}) {
  return Object.fromEntries(
    Object.entries(params).filter(([, value]) => value !== '' && value !== null && value !== undefined)
  )
}

const aiRecommendationService = {
  async getRecommendations(params = {}) {
    const response = await api.get('/ai/recommendations', {
      params: removeEmptyParams(params),
    })

    return response.data
  },

  async generateRecommendations(payload = {}) {
    const response = await api.post('/ai/recommendations/generate', payload)
    return response.data
  },

  async getDailyScores(params = {}) {
    const response = await api.get('/ai/scores/daily', {
      params: removeEmptyParams(params),
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

  async dismissRecommendation(recommendationId, reason = '') {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/dismiss`, {
      reason,
    })

    return response.data
  },

  async completeRecommendation(recommendationId) {
    const response = await api.patch(`/ai/recommendations/${recommendationId}/complete`)
    return response.data
  },

  async submitFeedback(recommendationId, payload = {}) {
    const normalizedPayload = {
      feedback_type: payload.feedback_type || payload.feedback || 'useful',
      feedback_value: payload.feedback_value ?? payload.rating ?? null,
      feedback_comment: payload.feedback_comment ?? payload.notes ?? null,
    }

    const response = await api.post(
      `/ai/recommendations/${recommendationId}/feedback`,
      normalizedPayload
    )

    return response.data
  },
}

export default aiRecommendationService
