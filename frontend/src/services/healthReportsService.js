import api from './api'

export const healthReportsService = {
  getDailyReport(date) {
    return api.get('/health/reports/daily', {
      params: { date }
    })
  },

  getWeeklyReport(startDate, endDate) {
    return api.get('/health/reports/weekly', {
      params: {
        start_date: startDate,
        end_date: endDate
      }
    })
  },

  getMonthlyReport(month) {
    return api.get('/health/reports/monthly', {
      params: { month }
    })
  },

  getExportPreview(period, date, month) {
    return api.get('/health/reports/export-preview', {
      params: {
        period,
        date,
        month
      }
    })
  },

  downloadPdfReport(period, date, month) {
    return api.get('/health/reports/pdf', {
      params: {
        period,
        date,
        month
      },
      responseType: 'blob'
    })
  }
}

export default healthReportsService
