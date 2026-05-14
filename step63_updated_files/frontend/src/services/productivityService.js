import api from "./api";

export const productivityService = {
  async getDashboardSummary() {
    const response = await api.get("/productivity/dashboard");
    return response.data;
  },

  async getHabits(params = {}) {
    const response = await api.get("/productivity/habits", { params });
    return response.data;
  },

  async getHabit(id) {
    const response = await api.get(`/productivity/habits/${id}`);
    return response.data;
  },

  async createHabit(payload) {
    const response = await api.post("/productivity/habits", payload);
    return response.data;
  },

  async updateHabit(id, payload) {
    const response = await api.put(`/productivity/habits/${id}`, payload);
    return response.data;
  },

  async deleteHabit(id) {
    const response = await api.delete(`/productivity/habits/${id}`);
    return response.data;
  },

  async checkInHabit(id, payload = {}) {
    const response = await api.post(`/productivity/habits/${id}/check-in`, payload);
    return response.data;
  },

  async getHabitsWeeklySummary(params = {}) {
    const response = await api.get("/productivity/habits/summary/weekly", { params });
    return response.data;
  },
};

export default productivityService;
