import api from './api'

function boolParam(value) {
  return value ? 1 : 0
}

export default {
  getRecommendations(params = {}) {
    return api.get('/ai/recommendations', {
      params: {
        ...params,
        active_only:
          typeof params.active_only === 'boolean'
            ? boolParam(params.active_only)
            : params.active_only,
      },
    })
  },

  getDailyScores(params = {}) {
    return api.get('/ai/scores/daily', {
      params: {
        ...params,
        generate_today:
          typeof params.generate_today === 'boolean'
            ? boolParam(params.generate_today)
            : params.generate_today,
      },
    })
  },

  generateRecommendations() {
    return api.post('/ai/recommendations/generate')
  },

  markViewed(id) {
    return api.patch(`/ai/recommendations/${id}/viewed`)
  },

  accept(id) {
    return api.patch(`/ai/recommendations/${id}/accept`)
  },

  dismiss(id) {
    return api.patch(`/ai/recommendations/${id}/dismiss`)
  },

  complete(id) {
    return api.patch(`/ai/recommendations/${id}/complete`)
  },

  feedback(id, payload) {
    return api.post(`/ai/recommendations/${id}/feedback`, payload)
  },
}