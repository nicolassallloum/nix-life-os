import api from './api'

export function normalizeList(payload) {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.data)) return payload.data
  if (Array.isArray(payload?.data?.data)) return payload.data.data
  if (Array.isArray(payload?.data?.data?.data)) return payload.data.data.data
  return []
}

export async function getProjectDashboard() {
  const response = await api.get('/projects/dashboard')
  return response.data
}

export async function getProjects(params = {}) {
  const response = await api.get('/projects', { params })
  return response.data
}

export async function getProject(id) {
  const response = await api.get(`/projects/${id}`)
  return response.data
}

export async function createProject(payload) {
  const response = await api.post('/projects', payload)
  return response.data
}

export async function updateProject(id, payload) {
  const response = await api.put(`/projects/${id}`, payload)
  return response.data
}

export async function deleteProject(id) {
  const response = await api.delete(`/projects/${id}`)
  return response.data
}

export async function getProjectTasks(projectId) {
  const response = await api.get(`/projects/${projectId}/tasks`)
  return response.data
}

export async function getAllProjectTasks(params = {}) {
  const response = await api.get('/projects/tasks', { params })
  return response.data
}

export async function createProjectTask(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/tasks`, payload)
  return response.data
}

export async function updateProjectTask(projectId, taskId, payload) {
  const response = await api.put(`/projects/${projectId}/tasks/${taskId}`, payload)
  return response.data
}

export async function deleteProjectTask(projectId, taskId) {
  const response = await api.delete(`/projects/${projectId}/tasks/${taskId}`)
  return response.data
}

export async function getProjectGoals(projectId) {
  const response = await api.get(`/projects/${projectId}/goals`)
  return response.data
}

export async function createProjectGoal(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/goals`, payload)
  return response.data
}

export async function updateProjectGoal(projectId, goalId, payload) {
  const response = await api.put(`/projects/${projectId}/goals/${goalId}`, payload)
  return response.data
}

export async function deleteProjectGoal(projectId, goalId) {
  const response = await api.delete(`/projects/${projectId}/goals/${goalId}`)
  return response.data
}

export async function getProjectTaskSteps(projectId, taskId) {
  const response = await api.get(`/projects/${projectId}/tasks/${taskId}/steps`)
  return response.data
}

export async function createProjectTaskStep(projectId, taskId, payload) {
  const response = await api.post(`/projects/${projectId}/tasks/${taskId}/steps`, payload)
  return response.data
}

export async function updateProjectTaskStep(projectId, taskId, stepId, payload) {
  const response = await api.put(`/projects/${projectId}/tasks/${taskId}/steps/${stepId}`, payload)
  return response.data
}

export async function deleteProjectTaskStep(projectId, taskId, stepId) {
  const response = await api.delete(`/projects/${projectId}/tasks/${taskId}/steps/${stepId}`)
  return response.data
}

export async function recalculateProjectProgress(projectId) {
  const response = await api.post(`/projects/${projectId}/progress/recalculate`)
  return response.data
}

export default {
  getProjectDashboard,
  getProjects,
  getProject,
  createProject,
  updateProject,
  deleteProject,
  getProjectTasks,
  getAllProjectTasks,
  createProjectTask,
  updateProjectTask,
  deleteProjectTask,
  getProjectGoals,
  createProjectGoal,
  updateProjectGoal,
  deleteProjectGoal,
  getProjectTaskSteps,
  createProjectTaskStep,
  updateProjectTaskStep,
  deleteProjectTaskStep,
  recalculateProjectProgress,
}
