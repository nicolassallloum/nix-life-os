import api from "./api";
// NIX WAS HERE - DO NOT SUGGEST CHANGES TO THIS FILE UNLESS IT'S TO ADD NEW FUNCTIONS FOR NEW FEATURES. DO NOT DELETE ANY EXISTING FUNCTIONS.
export async function getProjectDashboard() {
  const response = await api.get("/projects/dashboard");
  return response.data;
}

export async function getProjects(params = {}) {
  const response = await api.get("/projects", { params });
  return response.data;
}

export async function getProject(projectId) {
  const response = await api.get(`/projects/${projectId}`);
  return response.data;
}

export async function createProject(payload) {
  const response = await api.post("/projects", payload);
  return response.data;
}

export async function updateProject(projectId, payload) {
  const response = await api.put(`/projects/${projectId}`, payload);
  return response.data;
}

export async function patchProject(projectId, payload) {
  const response = await api.patch(`/projects/${projectId}`, payload);
  return response.data;
}

export async function deleteProject(projectId) {
  const response = await api.delete(`/projects/${projectId}`);
  return response.data;
}

export async function getProjectTasks(projectId, params = {}) {
  const response = await api.get(`/projects/${projectId}/tasks`, { params });
  return response.data;
}

export async function createProjectTask(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/tasks`, payload);
  return response.data;
}

export async function updateProjectTask(projectId, taskId, payload) {
  const response = await api.put(`/projects/${projectId}/tasks/${taskId}`, payload);
  return response.data;
}

export async function patchProjectTask(projectId, taskId, payload) {
  const response = await api.patch(`/projects/${projectId}/tasks/${taskId}`, payload);
  return response.data;
}

export async function deleteProjectTask(projectId, taskId) {
  const response = await api.delete(`/projects/${projectId}/tasks/${taskId}`);
  return response.data;
}

export async function updateProjectTaskProgress(projectId, taskId, payload) {
  const response = await api.patch(`/projects/${projectId}/tasks/${taskId}/progress`, payload);
  return response.data;
}

export async function getProjectProgress(projectId) {
  const response = await api.get(`/projects/${projectId}/progress`);
  return response.data;
}

export async function recalculateProjectProgress(projectId) {
  const response = await api.post(`/projects/${projectId}/progress/recalculate`);
  return response.data;
}

export async function getProjectMilestones(projectId) {
  const response = await api.get(`/projects/${projectId}/milestones`);
  return response.data;
}

export async function createProjectMilestone(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/milestones`, payload);
  return response.data;
}

export async function updateProjectMilestone(projectId, milestoneId, payload) {
  const response = await api.put(`/projects/${projectId}/milestones/${milestoneId}`, payload);
  return response.data;
}

export async function deleteProjectMilestone(projectId, milestoneId) {
  const response = await api.delete(`/projects/${projectId}/milestones/${milestoneId}`);
  return response.data;
}

export async function getProjectStatusUpdates(projectId, params = {}) {
  const response = await api.get(`/projects/${projectId}/status-updates`, { params });
  return response.data;
}

export async function createProjectStatusUpdate(projectId, payload) {
  const response = await api.post(`/projects/${projectId}/status-updates`, payload);
  return response.data;
}

export async function updateProjectStatus(projectId, status) {
  const response = await api.patch(`/projects/${projectId}`, { status });
  return response.data;
}
