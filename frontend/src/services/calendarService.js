import api from "./api";

export const calendarService = {
  async getEvents(params = {}) {
    const response = await api.get("/productivity/calendar/events", { params });
    return response.data;
  },

  async getEvent(id) {
    const response = await api.get(`/productivity/calendar/events/${id}`);
    return response.data;
  },

  async createEvent(payload) {
    const response = await api.post("/productivity/calendar/events", payload);
    return response.data;
  },

  async updateEvent(id, payload) {
    const response = await api.put(`/productivity/calendar/events/${id}`, payload);
    return response.data;
  },

  async deleteEvent(id) {
    const response = await api.delete(`/productivity/calendar/events/${id}`);
    return response.data;
  },
};

export default calendarService;
