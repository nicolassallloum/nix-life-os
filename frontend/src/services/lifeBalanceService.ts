const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  'http://127.0.0.1:8000/api/v1'

function getAuthToken(): string {
  return (
    localStorage.getItem('auth_token') ||
    localStorage.getItem('token') ||
    localStorage.getItem('access_token') ||
    sessionStorage.getItem('auth_token') ||
    sessionStorage.getItem('token') ||
    sessionStorage.getItem('access_token') ||
    ''
  )
}

async function request(path: string, options: RequestInit = {}) {
  const token = getAuthToken()

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  const payload = await response.json().catch(() => null)

  if (response.status === 401) {
    throw new Error('Unauthorized. Please login again.')
  }

  if (!response.ok) {
    throw new Error(payload?.message || `Request failed with status ${response.status}.`)
  }

  return payload
}

const lifeBalanceService = {
  getSummary() {
    return request('/life-balance/summary')
  },

  getAiRecommendations() {
    return request('/life-balance/ai-recommendations')
  },
}

export default lifeBalanceService
