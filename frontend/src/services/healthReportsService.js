import api from './api'

export const healthReportsService = {
  getDailyReport(date) {
    return api.get('/v1/health/reports/daily', {
      params: { date }
    })
  },

  getWeeklyReport(startDate, endDate) {
    return api.get('/v1/health/reports/weekly', {
      params: {
        start_date: startDate,
        end_date: endDate
      }
    })
  },

  getMonthlyReport(month) {
    return api.get('/v1/health/reports/monthly', {
      params: { month }
    })
  },

  getExportPreview(period, date, month) {
    return api.get('/v1/health/reports/export-preview', {
      params: {
        period,
        date,
        month
      }
    })
  }
}
