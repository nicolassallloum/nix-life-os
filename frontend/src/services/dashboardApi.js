const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1";

function getToken() {
  return (
    localStorage.getItem("nix_token") ||
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token")
  );
}

async function request(endpoint) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: "GET",
    headers: {
      Accept: "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(data?.message || `Request failed with status ${response.status}`);
  }

  return data;
}

export async function getUnifiedDashboardSummary() {
  return request("/dashboard/summary");
}

export async function getUnifiedDashboardKpis() {
  return request("/dashboard/kpis");
}

export async function getUnifiedDashboardRecentActivity() {
  return request("/dashboard/recent-activity");
}

/*
|--------------------------------------------------------------------------
| Compatibility Alias
|--------------------------------------------------------------------------
| Some views import getUnifiedDashboardActivity instead of
| getUnifiedDashboardRecentActivity.
|--------------------------------------------------------------------------
*/
export async function getUnifiedDashboardActivity() {
  return getUnifiedDashboardRecentActivity();
}

export default {
  getUnifiedDashboardSummary,
  getUnifiedDashboardKpis,
  getUnifiedDashboardRecentActivity,
  getUnifiedDashboardActivity,
};