import api from "./api";

export const healthAlertService = {
  async getAlerts(params = {}) {
    const response = await api.get("/health/alerts", { params });
    return response.data;
  },

  async getSummary() {
    const response = await api.get("/health/alerts/summary");
    return response.data;
  },

  async runEngine(date = null) {
    const response = await api.post("/health/alerts/run", { date });
    return response.data;
  },

  async markAsRead(id) {
    const response = await api.patch(`/health/alerts/${id}/read`);
    return response.data;
  },

  async resolve(id) {
    const response = await api.patch(`/health/alerts/${id}/resolve`);
    return response.data;
  },

  async dismiss(id) {
    const response = await api.patch(`/health/alerts/${id}/dismiss`);
    return response.data;
  },

  async deleteAlert(id) {
    const response = await api.delete(`/health/alerts/${id}`);
    return response.data;
  },
};
