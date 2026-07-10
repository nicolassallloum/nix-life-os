export type TodoTone = 'neutral' | 'info' | 'success' | 'warning' | 'danger'

export type TodoTaskLike = {
  id: number | string
  title: string
  description?: string
  task_type?: string
  type?: string
  status?: string
  priority?: string
  points?: number
  due_date?: string | null
  dueDate?: string | null
  project_id?: number | string | null
  projectId?: number | string | null
  project_name?: string
  projectName?: string
  project?: {
    id?: number | string
    name?: string
  } | null
}

export type TodoProjectLike = {
  id: number | string
  name: string
  description?: string
  status?: string
  start_date?: string | null
  startDate?: string | null
  end_date?: string | null
  endDate?: string | null
  total_tasks?: number
  totalTasks?: number
  finished_tasks?: number
  finishedTasks?: number
  completed_tasks?: number
  completedTasks?: number
  completion_percentage?: number
  completionPercentage?: number
  total_project_points?: number
  totalProjectPoints?: number
  total_points?: number
  totalPoints?: number
  points?: number
  tasks?: TodoTaskLike[]
}

export const taskTypes = ['general', 'monthly', 'weekly', 'daily'] as const
export const taskStatuses = ['pending', 'in_progress', 'finished'] as const
export const taskPriorities = ['low', 'medium', 'high'] as const
export const projectStatuses = ['active', 'completed', 'paused'] as const

export type TaskType = (typeof taskTypes)[number]
export type TaskStatus = (typeof taskStatuses)[number]
export type TaskPriority = (typeof taskPriorities)[number]
export type ProjectStatus = (typeof projectStatuses)[number]

export function numberValue(value: unknown): number {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

export function clampPercentage(value: unknown): number {
  return Math.min(100, Math.max(0, Math.round(numberValue(value))))
}

export function formatTodoLabel(value: unknown): string {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}

export function formatDate(value: unknown): string {
  return value ? String(value).slice(0, 10) : 'No date'
}

export function dateInputValue(value: unknown): string {
  return value ? String(value).slice(0, 10) : ''
}

export function isCompletedTask(status: unknown): boolean {
  return ['finished', 'completed', 'done'].includes(String(status || '').toLowerCase())
}

export function taskTypeLabel(value: unknown): string {
  const normalized = String(value || 'general').toLowerCase()

  if (normalized === 'monthly') return 'Monthly'
  if (normalized === 'weekly') return 'Weekly'
  if (normalized === 'daily') return 'Daily'

  return 'General'
}

export function taskStatusLabel(value: unknown): string {
  const normalized = String(value || 'pending').toLowerCase()

  if (normalized === 'in_progress') return 'In Progress'
  if (isCompletedTask(normalized)) return 'Finished'

  return 'Pending'
}

export function priorityLabel(value: unknown): string {
  const normalized = String(value || 'medium').toLowerCase()

  if (normalized === 'low') return 'Low Priority'
  if (normalized === 'high') return 'High Priority'

  return 'Medium Priority'
}

export function projectStatusLabel(value: unknown): string {
  const normalized = String(value || 'active').toLowerCase()

  if (normalized === 'completed') return 'Completed'
  if (normalized === 'paused') return 'Paused'

  return 'Active'
}

export function normalizeTaskType(value: unknown): TaskType {
  const normalized = String(value || 'general').toLowerCase()

  return taskTypes.includes(normalized as TaskType) ? (normalized as TaskType) : 'general'
}

export function normalizeTaskStatus(value: unknown): TaskStatus {
  const normalized = String(value || 'pending').toLowerCase()

  if (normalized === 'completed' || normalized === 'done') return 'finished'

  return taskStatuses.includes(normalized as TaskStatus) ? (normalized as TaskStatus) : 'pending'
}

export function normalizeTaskPriority(value: unknown): TaskPriority {
  const normalized = String(value || 'medium').toLowerCase()

  if (normalized === 'normal') return 'medium'

  return taskPriorities.includes(normalized as TaskPriority) ? (normalized as TaskPriority) : 'medium'
}

export function normalizeProjectStatus(value: unknown): ProjectStatus {
  const normalized = String(value || 'active').toLowerCase()

  return projectStatuses.includes(normalized as ProjectStatus) ? (normalized as ProjectStatus) : 'active'
}

export function taskBadgeTone(kind: 'type' | 'status' | 'priority' | 'project', value: unknown): TodoTone {
  const normalized = String(value || '').toLowerCase()

  if (kind === 'status') {
    if (isCompletedTask(normalized)) return 'success'
    if (normalized === 'in_progress') return 'info'
    return 'warning'
  }

  if (kind === 'priority') {
    if (normalized === 'high') return 'danger'
    if (normalized === 'low') return 'neutral'
    return 'warning'
  }

  if (kind === 'project') {
    if (normalized === 'completed') return 'success'
    if (normalized === 'paused') return 'warning'
    return 'info'
  }

  if (normalized === 'daily') return 'success'
  if (normalized === 'weekly') return 'info'
  if (normalized === 'monthly') return 'warning'

  return 'neutral'
}

export function taskBadgeLabel(kind: 'type' | 'status' | 'priority' | 'project', value: unknown): string {
  if (kind === 'type') return taskTypeLabel(value)
  if (kind === 'status') return taskStatusLabel(value)
  if (kind === 'priority') return priorityLabel(value)

  return projectStatusLabel(value)
}

export function extractList<T = unknown>(payload: any, key: string): T[] {
  const source =
    payload?.data?.data ||
    payload?.data?.[key] ||
    payload?.data ||
    payload?.[key] ||
    payload

  return Array.isArray(source) ? source : []
}

export function getApiMessage(error: any, fallback: string): string {
  if (error?.errors && typeof error.errors === 'object') {
    const firstKey = Object.keys(error.errors)[0]
    const firstValue = firstKey ? error.errors[firstKey] : null

    if (Array.isArray(firstValue) && firstValue[0]) return firstValue[0]
    if (typeof firstValue === 'string') return firstValue
  }

  if (error?.isNetworkError) {
    return 'Network error. Please check your connection and try again.'
  }

  return error?.response?.data?.message ||
    error?.response?.data?.error ||
    error?.message ||
    fallback
}

export function mapValidationErrors(error: any): Record<string, string> {
  const errors = error?.errors || error?.response?.data?.errors || {}
  const mapped: Record<string, string> = {}

  Object.entries(errors).forEach(([key, value]) => {
    mapped[key] = Array.isArray(value) ? String(value[0] || '') : String(value || '')
  })

  return mapped
}
