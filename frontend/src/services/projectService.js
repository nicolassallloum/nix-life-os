import api from "./api";

export async function getProjectDashboard() {
  const response = await api.get("/projects/dashboard");
  return response.data;
}

export async function getProjects(params = {}) {
  const response = await api.get("/projects", {
    params,
  });

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
  const response = await api.patch(`/projects/${projectId}`, payload);
  return response.data;
}

export async function deleteProject(projectId) {
  const response = await api.delete(`/projects/${projectId}`);
  return response.data;
}

export async function getProjectProgress(projectId) {
  const response = await api.get(`/projects/${projectId}/progress`);
  return response.data;
}

export async function getProjectMilestones(projectId) {
  const response = await api.get(`/projects/${projectId}/milestones`);
  return response.data;
}

export async function getProjectStatusUpdates(projectId) {
  const response = await api.get(`/projects/${projectId}/status-updates`);
  return response.data;
}

export async function recalculateProjectProgress(projectId) {
  const response = await api.post(`/projects/${projectId}/progress/recalculate`);
  return response.data;
}

export async function updateProjectStatus(projectId, status) {
  const response = await api.patch(`/projects/${projectId}`, {
    status,
  });

  return response.data;
}