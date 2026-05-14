import api from "./api";

export const productivityService = {
  async getDashboardSummary() {
    const response = await api.get("/productivity/dashboard");
    return response.data;
  },
};

export default productivityService;
