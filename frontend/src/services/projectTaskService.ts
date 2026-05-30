import apiClient from './apiClient'

export interface ProjectTaskPayload {
  project_id: number
  title: string
  description?: string | null
  priority?: 'low' | 'medium' | 'high' | 'critical'
  status?: 'todo' | 'in_progress' | 'done' | 'blocked'
  start_date?: string | null
  due_date?: string | null
  assigned_to?: string | null
  notes?: string | null
}

export const projectTaskService = {
  list(params = {}) {
    return apiClient.get('/projects/tasks', { params })
  },

  listByProject(projectId: number) {
    return apiClient.get(`/projects/${projectId}/tasks`)
  },

  create(payload: ProjectTaskPayload) {
    return apiClient.post('/projects/tasks', payload)
  },

  update(id: number, payload: Partial<ProjectTaskPayload>) {
    return apiClient.put(`/projects/tasks/${id}`, payload)
  },

  delete(id: number) {
    return apiClient.delete(`/projects/tasks/${id}`)
  },
}
