declare const adminManagementService: {
  getDashboardSummary(): Promise<any>
  getUsers(params?: Record<string, any>): Promise<any>
  createUser(payload: Record<string, any>): Promise<any>
  updateUser(id: string, payload: Record<string, any>): Promise<any>
  changePassword(id: string, payload: Record<string, any>): Promise<any>
  activateUser(id: string): Promise<any>
  deactivateUser(id: string): Promise<any>
  getUsageSummary(): Promise<any>
  getApplicationDataSummary(): Promise<any>
  getAuditLogs(params?: Record<string, any>): Promise<any>

  getPointLevels(): Promise<any>
  getPointIdeas(params?: Record<string, any>): Promise<any>
  createPointIdea(payload: Record<string, any>): Promise<any>
  updatePointIdea(id: string, payload: Record<string, any>): Promise<any>
  deletePointIdea(id: string): Promise<any>
}

export default adminManagementService
