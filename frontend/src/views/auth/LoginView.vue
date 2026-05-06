<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">
    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
      <h1 class="text-3xl font-bold text-slate-900 mb-2">NIX LIFE OS</h1>
      <p class="text-slate-500 mb-6">Login to your personal operating system</p>

      <form @submit.prevent="login" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Email
          </label>
          <input
            v-model="form.email"
            type="email"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="nix1@test.com"
            autocomplete="email"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Password
          </label>
          <input
            v-model="form.password"
            type="password"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="********"
            autocomplete="current-password"
            required
          />
        </div>

        <p v-if="error" class="text-red-600 text-sm">
          {{ error }}
        </p>

        <p v-if="success" class="text-green-600 text-sm">
          {{ success }}
        </p>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-slate-900 text-white rounded-xl py-3 font-semibold hover:bg-slate-800 disabled:opacity-60"
        >
          {{ loading ? "Logging in..." : "Login" }}
        </button>
      </form>

      <p class="text-sm text-slate-600 mt-6 text-center">
        Don't have an account?
        <RouterLink to="/register" class="text-slate-900 font-semibold">
          Register
        </RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from "vue";
import { useRouter, RouterLink } from "vue-router";

const router = useRouter();

const form = reactive({
  email: "nix1@test.com",
  password: "password",
});

const loading = ref(false);
const error = ref("");
const success = ref("");

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1";

function extractToken(responseData) {
  return (
    responseData?.token ||
    responseData?.access_token ||
    responseData?.data?.token ||
    responseData?.data?.access_token ||
    responseData?.data?.plainTextToken ||
    responseData?.plainTextToken ||
    null
  );
}

function extractUser(responseData) {
  return (
    responseData?.user ||
    responseData?.data?.user ||
    responseData?.data ||
    null
  );
}

async function login() {
  loading.value = true;
  error.value = "";
  success.value = "";

  try {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: form.email,
        password: form.password,
      }),
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      const validationMessage = data?.errors
        ? Object.values(data.errors).flat().join(" ")
        : null;

      throw new Error(data?.message || validationMessage || "Login failed");
    }

    const token = extractToken(data);
    const user = extractUser(data);

    if (!token) {
      console.error("Login response:", data);
      throw new Error("Login succeeded but token was not found in response.");
    }

    localStorage.setItem("nix_token", token);
    localStorage.setItem("token", token);
    localStorage.setItem("auth_token", token);

    if (user) {
      localStorage.setItem("nix_user", JSON.stringify(user));
      localStorage.setItem("user", JSON.stringify(user));
    }

    success.value = "Login successful. Redirecting...";

    router.push("/");
  } catch (err) {
    error.value = err.message || "Login failed";
  } finally {
    loading.value = false;
  }
}
</script>