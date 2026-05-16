<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">
    <div class="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
      <h1 class="text-3xl font-bold text-slate-900 mb-2">Create Account</h1>
      <p class="text-slate-500 mb-6">Start using NIX LIFE OS</p>

      <form @submit.prevent="register" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Name</label>
          <input
            v-model="form.name"
            type="text"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="Nix"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>
          <input
            v-model="form.email"
            type="email"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="nix@example.com"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Password</label>
          <input
            v-model="form.password"
            type="password"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="********"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>
          <input
            v-model="form.password_confirmation"
            type="password"
            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-slate-900"
            placeholder="********"
          />
        </div>

        <p v-if="error" class="text-red-600 text-sm">
          {{ error }}
        </p>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-slate-900 text-white rounded-xl py-3 font-semibold hover:bg-slate-800 disabled:opacity-60"
        >
          {{ loading ? "Creating account..." : "Register" }}
        </button>
      </form>

      <p class="text-sm text-slate-600 mt-6 text-center">
        Already have an account?
        <RouterLink to="/login" class="text-slate-900 font-semibold">
          Login
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
  name: "",
  email: "",
  password: "",
  password_confirmation: "",
});

const loading = ref(false);
const error = ref("");

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8001/api/v1";

async function register() {
  loading.value = true;
  error.value = "";

  try {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(form),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || "Registration failed");
    }

    localStorage.setItem("nix_token", data.token);
    localStorage.setItem("nix_user", JSON.stringify(data.user));

    router.push("/");
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
}
</script>
