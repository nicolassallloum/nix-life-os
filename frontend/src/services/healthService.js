import axios from "axios";

const API_BASE_URL = "http://localhost:8000/api/v1";

function getAuthHeaders() {
  const token = localStorage.getItem("token");

  return {
    Accept: "application/json",
    Authorization: `Bearer ${token}`,
  };
}

export async function getHealthProfile() {
  const response = await axios.get(`${API_BASE_URL}/health/profile`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function updateHealthProfile(payload) {
  const response = await axios.put(`${API_BASE_URL}/health/profile`, payload, {
    headers: {
      ...getAuthHeaders(),
      "Content-Type": "application/json",
    },
  });

  return response.data;
}

export async function getStepsHistory(days = 30) {
  const response = await axios.get(`${API_BASE_URL}/health/steps`, {
    params: { days },
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function getStepsSummary(days = 30) {
  const response = await axios.get(`${API_BASE_URL}/health/steps/summary`, {
    params: { days },
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function saveStepLog(payload) {
  const response = await axios.post(`${API_BASE_URL}/health/steps`, payload, {
    headers: {
      ...getAuthHeaders(),
      "Content-Type": "application/json",
    },
  });

  return response.data;
}

export async function deleteStepLog(id) {
  const response = await axios.delete(`${API_BASE_URL}/health/steps/${id}`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}