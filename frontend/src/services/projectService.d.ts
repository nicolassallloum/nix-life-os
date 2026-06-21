declare module '@/services/projectService' {
  export function normalizeList(payload: any): any[]

  export function getProjectDashboard(): Promise<any>
  export function getProjects(params?: Record<string, any>): Promise<any>
  export function getProject(id: string): Promise<any>
  export function createProject(payload: Record<string, any>): Promise<any>
  export function updateProject(id: string, payload: Record<string, any>): Promise<any>
  export function deleteProject(id: string): Promise<any>

  export function getProjectTasks(projectId: string): Promise<any>
  export function getAllProjectTasks(params?: Record<string, any>): Promise<any>
  export function createProjectTask(projectId: string, payload: Record<string, any>): Promise<any>
  export function updateProjectTask(projectId: string, taskId: string, payload: Record<string, any>): Promise<any>
  export function deleteProjectTask(projectId: string, taskId: string): Promise<any>

  export function getProjectGoals(projectId: string): Promise<any>
  export function createProjectGoal(projectId: string, payload: Record<string, any>): Promise<any>
  export function updateProjectGoal(projectId: string, goalId: string, payload: Record<string, any>): Promise<any>
  export function deleteProjectGoal(projectId: string, goalId: string): Promise<any>
  export function recalculateProjectGoal(projectId: string, goalId: string): Promise<any>

  export function getProjectTaskSteps(projectId: string, taskId: string): Promise<any>
  export function createProjectTaskStep(projectId: string, taskId: string, payload: Record<string, any>): Promise<any>
  export function updateProjectTaskStep(projectId: string, taskId: string, stepId: string, payload: Record<string, any>): Promise<any>
  export function deleteProjectTaskStep(projectId: string, taskId: string, stepId: string): Promise<any>

  export function recalculateProjectProgress(projectId: string): Promise<any>

  const projectService: Record<string, any>
  export default projectService
}
export function completeProjectTask(projectId: string, taskId: string | number): Promise<any>
export function reopenProjectTask(projectId: string, taskId: string | number): Promise<any>
