import apiClient from './apiClient'

export const healthService = {
  dashboard() {
    return apiClient.get('/health/dashboard')
  },

  addSteps(payload: any) {
    return apiClient.post('/health/steps', payload)
  },

  addWeight(payload: any) {
    return apiClient.post('/health/weight', payload)
  },

  addWater(payload: any) {
    return apiClient.post('/health/water', payload)
  },

  addSleep(payload: any) {
    return apiClient.post('/health/sleep', payload)
  },

  addMood(payload: any) {
    return apiClient.post('/health/mood', payload)
  },

  addMedication(payload: any) {
    return apiClient.post('/health/medications', payload)
  },

  listSteps() {
    return apiClient.get('/health/steps')
  },

  listWeight() {
    return apiClient.get('/health/weight')
  },

  listWater() {
    return apiClient.get('/health/water')
  },

  listSleep() {
    return apiClient.get('/health/sleep')
  },

  listMood() {
    return apiClient.get('/health/mood')
  },

  listMedications() {
    return apiClient.get('/health/medications')
  },
}
