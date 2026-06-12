import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

const request = axios.create({
  // Keep /api in the base URL so the Vite proxy can forward requests.
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

request.interceptors.response.use(
  response => {
    const res = response.data

    if (res && res.success !== undefined) {
      if (res.success) {
        return res.data !== undefined ? res.data : res
      }
      ElMessage.error(res.message || res.error?.message || 'Request failed')
      return Promise.reject(new Error(res.message || res.error?.message))
    }

    return res
  },
  async error => {
    const { response } = error

    if (!response) {
      ElMessage.error('Network error. Please check your connection.')
      return Promise.reject(error)
    }

    const { status, data } = response

    if (status === 401) {
      const authStore = useAuthStore()

      try {
        await authStore.refreshToken()
        const config = error.config
        const token = localStorage.getItem('token')
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return request(config)
      } catch (refreshError) {
        authStore.logout()
        ElMessage.error('Session expired. Please log in again.')
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }

    if (status === 403) {
      ElMessage.error('Access denied.')
      return Promise.reject(error)
    }

    if (status === 404) {
      ElMessage.error('Resource not found.')
      return Promise.reject(error)
    }

    if (status >= 500) {
      ElMessage.error('Server error. Please try again later.')
      return Promise.reject(error)
    }

    const message = data?.message || data?.error?.message || 'Request failed'
    ElMessage.error(message)
    return Promise.reject(error)
  }
)

export default request
