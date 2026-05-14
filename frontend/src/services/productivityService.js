import api from "./api";

export const productivityService = {
  async getDashboardSummary() {
    const response = await api.get("/productivity/dashboard");
    return response.data;
  },

  /* 
  |--------------------------------------------------------------------------
  | Goals
  |--------------------------------------------------------------------------
  */

  async getGoals(params = {}) {
    const response = await api.get("/productivity/goals", { params });
    return response.data;
  },

  async getGoal(id) {
    const response = await api.get(`/productivity/goals/${id}`);
    return response.data;
  },

  async createGoal(payload) {
    const response = await api.post("/productivity/goals", payload);
    return response.data;
  },

  async updateGoal(id, payload) {
    const response = await api.put(`/productivity/goals/${id}`, payload);
    return response.data;
  },

  async deleteGoal(id) {
    const response = await api.delete(`/productivity/goals/${id}`);
    return response.data;
  },

  async updateGoalProgress(id, payload) {
    const response = await api.patch(`/productivity/goals/${id}/progress`, payload);
    return response.data;
  },

  async completeGoal(id) {
    const response = await api.patch(`/productivity/goals/${id}/complete`);
    return response.data;
  },

  async reopenGoal(id) {
    const response = await api.patch(`/productivity/goals/${id}/reopen`);
    return response.data;
  },

  async recalculateGoalProgress(id) {
    const response = await api.post(`/productivity/goals/${id}/recalculate-progress`);
    return response.data;
  },

  async linkGoalTask(id, taskId) {
    const response = await api.post(`/productivity/goals/${id}/tasks`, {
      task_id: taskId,
    });

    return response.data;
  },

  async unlinkGoalTask(id, taskId) {
    const response = await api.delete(`/productivity/goals/${id}/tasks/${taskId}`);
    return response.data;
  },

  async linkGoalHabit(id, habitId) {
    const response = await api.post(`/productivity/goals/${id}/habits`, {
      habit_id: habitId,
    });

    return response.data;
  },

  async unlinkGoalHabit(id, habitId) {
    const response = await api.delete(`/productivity/goals/${id}/habits/${habitId}`);
    return response.data;
  },

  /*
  |--------------------------------------------------------------------------
  | Habits
  |--------------------------------------------------------------------------
  */

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

  /*
  |--------------------------------------------------------------------------
  | Calendar / Schedule
  |--------------------------------------------------------------------------
  */

  async getCalendarEvents(params = {}) {
    const response = await api.get("/productivity/calendar/events", { params });
    return response.data;
  },

  async getCalendarEvent(id) {
    const response = await api.get(`/productivity/calendar/events/${id}`);
    return response.data;
  },

  async createCalendarEvent(payload) {
    const response = await api.post("/productivity/calendar/events", payload);
    return response.data;
  },

  async updateCalendarEvent(id, payload) {
    const response = await api.put(`/productivity/calendar/events/${id}`, payload);
    return response.data;
  },

  async deleteCalendarEvent(id) {
    const response = await api.delete(`/productivity/calendar/events/${id}`);
    return response.data;
  },
};

export default productivityService;