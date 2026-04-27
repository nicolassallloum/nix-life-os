import axios from "axios";

const API_BASE_URL = "http://127.0.0.1:8000/api/v1";

function getAuthHeaders() {
  const token = localStorage.getItem("token");

  return {
    Accept: "application/json",
    Authorization: `Bearer ${token}`,
  };
}

export async function getUnifiedDashboardSummary() {
  const response = await axios.get(`${API_BASE_URL}/dashboard/summary`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function getUnifiedDashboardKpis() {
  const response = await axios.get(`${API_BASE_URL}/dashboard/kpis`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}

export async function getUnifiedDashboardActivity() {
  const response = await axios.get(`${API_BASE_URL}/dashboard/recent-activity`, {
    headers: getAuthHeaders(),
  });

  return response.data;
}