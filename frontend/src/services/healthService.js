import api from "./api";

const healthService = {
  dashboard() {
    return api.get("/health/dashboard");
  },

  aiInsights(params = {}) {
    return api.get("/health/ai-insights", { params });
  },

  steps: {
    list(params = {}) {
      return api.get("/health/steps", { params });
    },
    summary(params = {}) {
      return api.get("/health/steps/summary", { params });
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
    summary(params = {}) {
      return api.get("/health/weight/summary", { params });
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
    summary(params = {}) {
      return api.get("/health/nutrition/summary", { params });
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
    dailySummary(params = {}) {
      return api.get("/health/hydration/summary/daily", { params });
    },
    weeklySummary(params = {}) {
      return api.get("/health/hydration/summary/weekly", { params });
    },
    quickAdd(payload) {
      return api.post("/health/hydration/quick-add", payload);
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

  sports: {
    list(params = {}) {
      return api.get("/health/sports", { params });
    },
    create(payload) {
      return api.post("/health/sports", payload);
    },
    update(id, payload) {
      return api.put(`/health/sports/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/sports/${id}`);
    },
  },

  medications: {
    list(params = {}) {
      return api.get("/health/medications", { params });
    },
    today(params = {}) {
      return api.get("/health/medications/today", { params });
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

  medicationReminders: {
    list(params = {}) {
      return api.get("/health/medication-reminders", { params });
    },
    today(params = {}) {
      return api.get("/health/medication-reminders/today", { params });
    },
    create(payload) {
      return api.post("/health/medication-reminders", payload);
    },
    update(id, payload) {
      return api.put(`/health/medication-reminders/${id}`, payload);
    },
    delete(id) {
      return api.delete(`/health/medication-reminders/${id}`);
    },
  },

  medicationDoses: {
    history(params = {}) {
      return api.get("/health/medication-doses/history", { params });
    },
    markTaken(id) {
      return api.post(`/health/medication-doses/${id}/taken`);
    },
    markSkipped(id, payload = {}) {
      return api.post(`/health/medication-doses/${id}/skipped`, payload);
    },
  },

  labTests: {
    categories() {
      return api.get("/health/lab-tests/categories");
    },
    list(params = {}) {
      return api.get("/health/lab-tests", { params });
    },
    show(id) {
      return api.get(`/health/lab-tests/${id}`);
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

  alerts: {
    list(params = {}) {
      return api.get("/health/alerts", { params });
    },
    summary(params = {}) {
      return api.get("/health/alerts/summary", { params });
    },
    run(payload = {}) {
      return api.post("/health/alerts/run", payload);
    },
    markRead(id) {
      return api.patch(`/health/alerts/${id}/read`);
    },
    resolve(id) {
      return api.patch(`/health/alerts/${id}/resolve`);
    },
    dismiss(id) {
      return api.patch(`/health/alerts/${id}/dismiss`);
    },
    delete(id) {
      return api.delete(`/health/alerts/${id}`);
    },
  },

  reports: {
    daily(params = {}) {
      return api.get("/health/reports/daily", { params });
    },
    weekly(params = {}) {
      return api.get("/health/reports/weekly", { params });
    },
    monthly(params = {}) {
      return api.get("/health/reports/monthly", { params });
    },
    exportPreview(params = {}) {
      return api.get("/health/reports/export-preview", { params });
    },
  },

  nutritionFacts: {
    categories() {
      return api.get("/nutrition/categories");
    },
    foods(params = {}) {
      return api.get("/nutrition/foods", { params });
    },
    search(params = {}) {
      return api.get("/nutrition/foods/search", { params });
    },
    show(id) {
      return api.get(`/nutrition/foods/${id}`);
    },
    servings(id) {
      return api.get(`/nutrition/foods/${id}/servings`);
    },
    autofill(payload) {
      return api.post("/nutrition/foods/autofill", payload);
    },
    customFoods(params = {}) {
      return api.get("/nutrition/custom-foods", { params });
    },
    createCustomFood(payload) {
      return api.post("/nutrition/custom-foods", payload);
    },
    updateCustomFood(id, payload) {
      return api.put(`/nutrition/custom-foods/${id}`, payload);
    },
    deleteCustomFood(id) {
      return api.delete(`/nutrition/custom-foods/${id}`);
    },
  },
};

export default healthService;
