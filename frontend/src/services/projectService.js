import axios from "axios";

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

function getToken() {
  return localStorage.getItem("token");
}

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
});

api.interceptors.request.use((config) => {
  const token = getToken();

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

export async function getProjects() {
  const response = await api.get("/projects");
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
