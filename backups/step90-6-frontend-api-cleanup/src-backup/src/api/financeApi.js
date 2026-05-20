import axios from "axios";

const api = axios.create({
  baseURL: "/api/v1",
  headers: {
    Accept: "application/json",
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("auth_token");

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

export const financeApi = {
  getAccounts() {
    return api.get("/finance/accounts");
  },

  getTransactions() {
    return api.get("/finance/transactions");
  },

  createTransaction(payload) {
    return api.post("/finance/transactions", payload);
  },

  getBudgets() {
    return api.get("/finance/budgets");
  },

  getDashboardSummary() {
    return api.get("/finance/dashboard-summary");
  },

  getForecast() {
    return api.get("/finance/forecast");
  },

  getAnomalies() {
    return api.get("/finance/anomalies");
  },
};