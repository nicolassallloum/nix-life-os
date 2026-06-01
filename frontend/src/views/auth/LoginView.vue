<template>
  <div class="flex min-h-screen items-center justify-center bg-slate-100 px-4 py-10">
    <div class="w-full max-w-xl rounded-3xl bg-white p-10 shadow-xl">
      <h1 class="text-4xl font-black tracking-widest text-slate-950">
        NIX LIFE OS
      </h1>

      <p class="mt-4 text-lg text-slate-600">
        Login to your personal operating system
      </p>

      <form class="mt-8 space-y-5" @submit.prevent="login">
        <div>
          <label class="mb-2 block text-sm font-semibold text-slate-800">
            Email
          </label>

          <input
            v-model.trim="form.email"
            type="email"
            autocomplete="email"
            class="w-full rounded-xl border border-slate-200 bg-slate-100 px-4 py-3 text-slate-950 placeholder:text-slate-400 focus:border-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900/10"
            placeholder="admin@nixlifeos.com"
            required
          />
        </div>

        <div>
          <label class="mb-2 block text-sm font-semibold text-slate-800">
            Password
          </label>

          <input
            v-model="form.password"
            type="password"
            autocomplete="current-password"
            class="w-full rounded-xl border border-slate-200 bg-slate-100 px-4 py-3 text-slate-950 placeholder:text-slate-400 focus:border-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900/10"
            placeholder="********"
            required
          />
        </div>

        <p v-if="errorMessage" class="text-sm font-medium text-red-600">
          {{ errorMessage }}
        </p>

        <button
          type="submit"
          :disabled="isLoading"
          class="w-full rounded-xl bg-slate-950 px-4 py-4 text-center text-base font-bold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {{ isLoading ? 'Logging in...' : 'Login' }}
        </button>
      </form>

  <p class="mt-8 text-center text-sm text-slate-600">
    Don't have an account?
    <RouterLink
      to="/register"
      class="font-semibold text-slate-950 hover:underline"
    >
      Register
    </RouterLink>
  </p>

  <p class="mt-3 text-center text-sm text-slate-500">
    Contact
    <a
      href="https://www.instagram.com/nixo.tech/"
      target="_blank"
      rel="noopener noreferrer"
      class="font-semibold text-slate-950 hover:underline"
    >
      NixoTech
    </a>
  </p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const router = useRouter()
const route = useRoute()

const isLoading = ref(false)
const errorMessage = ref('')

const form = reactive({
  email: '',
  password: '',
})

const clearOldAuth = () => {
  const keys = [
    'token',
    'auth_token',
    'access_token',
    'nixlifeos_token',
    'user',
    'auth_user',
    'nixlifeos_user',
    'roles',
    'permissions',
  ]

  keys.forEach((key) => {
    localStorage.removeItem(key)
    sessionStorage.removeItem(key)
  })
}

const saveAuth = (payload) => {
  const data = payload?.data || payload

  const token =
    data?.token ||
    data?.access_token ||
    payload?.token ||
    payload?.access_token

  const user =
    data?.user ||
    payload?.user ||
    null

  if (!token) {
    throw new Error('Login response did not include a token.')
  }

  localStorage.setItem('token', token)
  localStorage.setItem('auth_token', token)
  localStorage.setItem('access_token', token)
  localStorage.setItem('nixlifeos_token', token)

  if (user) {
    localStorage.setItem('user', JSON.stringify(user))
    localStorage.setItem('auth_user', JSON.stringify(user))
    localStorage.setItem('nixlifeos_user', JSON.stringify(user))

    if (Array.isArray(user.roles)) {
      localStorage.setItem('roles', JSON.stringify(user.roles))
    }

    if (Array.isArray(user.permissions)) {
      localStorage.setItem('permissions', JSON.stringify(user.permissions))
    }
  }
}

const login = async () => {
  if (isLoading.value) {
    return
  }

  errorMessage.value = ''
  isLoading.value = true

  const apiBaseUrl =
    import.meta.env.VITE_API_BASE_URL ||
    'https://api.nixlifeos.com/api/v1'

  try {
    clearOldAuth()

    const response = await fetch(`${apiBaseUrl}/auth/login`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: form.email.trim(),
        password: form.password,
      }),
    })

    const payload = await response.json().catch(() => null)

    if (!response.ok || payload?.success === false) {
      throw new Error(payload?.message || 'Login failed. Please check your credentials.')
    }

    saveAuth(payload)

    const redirectTo =
      typeof route.query.redirect === 'string' && route.query.redirect !== '/login'
        ? route.query.redirect
        : '/dashboard'

    await router.replace(redirectTo)
  } catch (error) {
    console.error('[Login] Failed:', error)
    errorMessage.value = error?.message || 'Login failed. Please check your credentials.'
  } finally {
    isLoading.value = false
  }
}
</script>