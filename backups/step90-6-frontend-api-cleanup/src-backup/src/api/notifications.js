import axios from "axios";

const API_BASE_URL = "/api/v1";

function authHeaders() {
  const token = localStorage.getItem("token");

  return {
    Accept: "application/json",
    Authorization: `Bearer ${token}`,
  };
}

export async function getNotifications(params = {}) {
  const response = await axios.get(`${API_BASE_URL}/notifications`, {
    headers: authHeaders(),
    params,
  });

  return response.data;
}

export async function getUnreadNotificationCount() {
  const response = await axios.get(`${API_BASE_URL}/notifications/unread-count`, {
    headers: authHeaders(),
  });

  return response.data;
}

export async function markNotificationAsRead(id) {
  const response = await axios.patch(
    `${API_BASE_URL}/notifications/${id}/read`,
    {},
    {
      headers: authHeaders(),
    }
  );

  return response.data;
}

export async function markAllNotificationsAsRead() {
  const response = await axios.patch(
    `${API_BASE_URL}/notifications/read-all`,
    {},
    {
      headers: authHeaders(),
    }
  );

  return response.data;
}

export async function deleteNotification(id) {
  const response = await axios.delete(`${API_BASE_URL}/notifications/${id}`, {
    headers: authHeaders(),
  });

  return response.data;
}

export async function getNotificationPreferences() {
  const response = await axios.get(`${API_BASE_URL}/notification-preferences`, {
    headers: authHeaders(),
  });

  return response.data;
}

export async function updateNotificationPreferences(payload) {
  const response = await axios.put(
    `${API_BASE_URL}/notification-preferences`,
    payload,
    {
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}
