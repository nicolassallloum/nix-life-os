<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">
    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
      <h1 class="text-3xl font-bold text-slate-900 mb-2">Create Account</h1>
      <p class="text-slate-500 mb-6">Start using NIX LIFE OS</p>

      <form @submit.prevent="register" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Name</label>
          <input
            v-model.trim="form.name"
            type="text"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="Nix"
            autocomplete="name"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>
          <input
            v-model.trim="form.email"
            type="email"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="nix@example.com"
            autocomplete="email"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Password</label>
          <input
            v-model="form.password"
            type="password"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="Password123!"
            autocomplete="new-password"
            required
          />
          <p class="text-xs text-slate-500 mt-1">
            Use at least 8 characters with uppercase, lowercase, number, and symbol.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>
          <input
            v-model="form.password_confirmation"
            type="password"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="Password123!"
            autocomplete="new-password"
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
          {{ loading ? 'Creating account...' : 'Register' }}
        </button>
      </form>

      <p class="text-sm text-slate-600 mt-6 text-center">
        Already have an account?
        <RouterLink to="/login" class="text-slate-900 font-semibold">Login</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import api, { saveAuthSession } from '@/services/api'

const router = useRouter()

const form = reactive({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
})

const loading = ref(false)
const error = ref('')
const success = ref('')

function extractErrors(responseData) {
  if (responseData?.errors) {
    return Object.values(responseData.errors).flat().join(' ')
  }

  return responseData?.message || 'Registration failed.'
}

async function register() {
  loading.value = true
  error.value = ''
  success.value = ''

  try {
    const response = await api.post('/auth/register', { ...form })
    const data = response.data

    const token = data?.data?.token || data?.token || data?.access_token
    const user = data?.data?.user || data?.user || null

    if (!token) {
      throw new Error('Registration succeeded but token was not found in the response.')
    }

    saveAuthSession(token, user)
    success.value = 'Registration successful. Redirecting...'

    await router.push('/dashboard')
  } catch (err) {
    error.value = extractErrors(err.response?.data) || err.message
  } finally {
    loading.value = false
  }
}
</script>
