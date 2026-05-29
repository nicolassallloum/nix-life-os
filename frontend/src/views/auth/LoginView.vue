<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">
    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
      <h1 class="text-3xl font-bold text-slate-900 mb-2">NIX LIFE OS</h1>
      <p class="text-slate-500 mb-6">Login to your personal operating system</p>

      <form @submit.prevent="login" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>
          <input
            v-model.trim="form.email"
            type="email"
            class="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/10"            placeholder="nix@example.com"
            autocomplete="email"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Password</label>
          <input
            v-model="form.password"
            type="password"
            class="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/10"
            placeholder="********"
            autocomplete="current-password"
            required
          />
        </div>

        <p v-if="error" class="text-red-600 text-sm">{{ error }}</p>
        <p v-if="success" class="text-green-600 text-sm">{{ success }}</p>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-slate-900 text-white rounded-xl py-3 font-semibold hover:bg-slate-800 disabled:opacity-60"
        >
          {{ loading ? 'Logging in...' : 'Login' }}
        </button>
      </form>

      <p class="text-sm text-slate-600 mt-6 text-center">
        Don't have an account?
        <RouterLink to="/register" class="text-slate-900 font-semibold">Register</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import api, { saveAuthSession } from '@/services/api'

const router = useRouter()
const route = useRoute()

const form = reactive({
  email: '',
  password: '',
})

const loading = ref(false)
const error = ref('')
const success = ref('')

function extractErrors(responseData) {
  if (responseData?.errors) {
    return Object.values(responseData.errors).flat().join(' ')
  }

  return responseData?.message || 'Login failed. Please check your credentials.'
}

async function login() {
  loading.value = true
  error.value = ''
  success.value = ''

  try {
    const response = await api.post('/auth/login', {
      email: form.email,
      password: form.password,
    })

    const data = response.data
    const token = data?.data?.token || data?.token || data?.access_token
    const user = data?.data?.user || data?.user || null

    if (!token) {
      throw new Error('Login succeeded but token was not found in the response.')
    }

    saveAuthSession(token, user)
    success.value = 'Login successful. Redirecting...'

    const redirectPath = typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard'
    await router.push(redirectPath || '/dashboard')
  } catch (err) {
    error.value = extractErrors(err.response?.data) || err.message
  } finally {
    loading.value = false
  }
}
</script>
