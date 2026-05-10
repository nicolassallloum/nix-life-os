import api from "./api";

const healthService = {
  dashboard() {
    return api.get("/health/dashboard");
  },

  steps: {
    list(params = {}) {
      return api.get("/health/steps", { params });
    },
    create(payload) {
      return api.post("/health/steps", payload);
    },
    update(id, payload) {
      return api.put(`/health/steps/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/steps/${id}`);
    },
  },

  weight: {
    list(params = {}) {
      return api.get("/health/weight", { params });
    },
    create(payload) {
      return api.post("/health/weight", payload);
    },
    update(id, payload) {
      return api.put(`/health/weight/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/weight/${id}`);
    },
  },

  nutrition: {
    list(params = {}) {
      return api.get("/health/nutrition", { params });
    },
    create(payload) {
      return api.post("/health/nutrition", payload);
    },
    update(id, payload) {
      return api.put(`/health/nutrition/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/nutrition/${id}`);
    },
  },

  hydration: {
    list(params = {}) {
      return api.get("/health/hydration", { params });
    },
    create(payload) {
      return api.post("/health/hydration", payload);
    },
    update(id, payload) {
      return api.put(`/health/hydration/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/hydration/${id}`);
    },
  },

  sleep: {
    list(params = {}) {
      return api.get("/health/sleep", { params });
    },
    create(payload) {
      return api.post("/health/sleep", payload);
    },
    update(id, payload) {
      return api.put(`/health/sleep/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/sleep/${id}`);
    },
  },

  mood: {
    list(params = {}) {
      return api.get("/health/mood", { params });
    },
    create(payload) {
      return api.post("/health/mood", payload);
    },
    update(id, payload) {
      return api.put(`/health/mood/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/mood/${id}`);
    },
  },

  medications: {
    list(params = {}) {
      return api.get("/health/medications", { params });
    },
    create(payload) {
      return api.post("/health/medications", payload);
    },
    update(id, payload) {
      return api.put(`/health/medications/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/medications/${id}`);
    },
  },

  labTests: {
    list(params = {}) {
      return api.get("/health/lab-tests", { params });
    },
    create(payload) {
      return api.post("/health/lab-tests", payload);
    },
    update(id, payload) {
      return api.put(`/health/lab-tests/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/lab-tests/${id}`);
    },
    trends(params = {}) {
      return api.get("/health/lab-tests/trends", { params });
    },
  },
};

export default healthService;