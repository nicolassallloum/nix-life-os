const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api/v1";

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
    const error = new Error(data.message || "Request failed.");
    error.status = response.status;
    error.errors = data.errors || {};
    throw error;
  }

  return data;
}

export const taskService = {
  list(params = {}) {
    const query = new URLSearchParams();

    Object.entries(params).forEach(([key, value]) => {
      if (value !== null && value !== undefined && value !== "" && value !== "all") {
        query.append(key, value);
      }
    });

    const queryString = query.toString();

    return request(`/tasks${queryString ? `?${queryString}` : ""}`);
  },

  create(payload) {
    return request("/tasks", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  update(id, payload) {
    return request(`/tasks/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },

  remove(id) {
    return request(`/tasks/${id}`, {
      method: "DELETE",
    });
  },

  complete(id) {
    return request(`/tasks/${id}/complete`, {
      method: "PATCH",
    });
  },

  reopen(id) {
    return request(`/tasks/${id}/reopen`, {
      method: "PATCH",
    });
  },
};
