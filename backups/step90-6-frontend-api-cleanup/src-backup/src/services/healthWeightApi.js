const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  "/api/v1";

function getToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

async function request(path, options = {}) {
  const token = getToken();

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw data;
  }

  return data;
}

export const healthWeightApi = {
  getLogs(params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/health/weight${query ? `?${query}` : ""}`);
  },

  getSummary(params = {}) {
    const query = new URLSearchParams(params).toString();
    return request(`/health/weight/summary${query ? `?${query}` : ""}`);
  },

  createLog(payload) {
    return request("/health/weight", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  updateLog(id, payload) {
    return request(`/health/weight/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },

  deleteLog(id) {
    return request(`/health/weight/${id}`, {
      method: "DELETE",
    });
  },
};

export default healthWeightApi;
