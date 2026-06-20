import api from './api'

function reportParams(period = 'daily', date = '', month = '', startDate = '', endDate = '') {
  if (period === 'weekly') {
    return {
      period,
      date: startDate || date,
      start_date: startDate || date,
      end_date: endDate || date,
    }
  }

  if (period === 'monthly') {
    return {
      period,
      month,
    }
  }

  return {
    period: 'daily',
    date,
  }
}

export const healthReportsService = {
  getDailyReport(date) {
    return api.get('/health/reports/daily', {
      params: { date },
    })
  },

  getWeeklyReport(startDate, endDate) {
    return api.get('/health/reports/weekly', {
      params: {
        start_date: startDate,
        end_date: endDate,
      },
    })
  },

  getMonthlyReport(month) {
    return api.get('/health/reports/monthly', {
      params: { month },
    })
  },

  getExportPreview(period, date, month, startDate = '', endDate = '') {
    return api.get('/health/reports/export-preview', {
      params: reportParams(period, date, month, startDate, endDate),
    })
  },

  downloadPdfReport(period, date, month, startDate = '', endDate = '') {
    return api.get('/health/reports/pdf', {
      params: reportParams(period, date, month, startDate, endDate),
      responseType: 'blob',
    })
  },
}

export default healthReportsService
