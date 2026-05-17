<script setup>
import { ref, onMounted } from "vue";

const roles = ref([]);
const permissions = ref([]);
const loading = ref(false);
const error = ref(null);

const token = localStorage.getItem("token");

async function fetchSecurityData() {
  loading.value = true;
  error.value = null;

  try {
    const [rolesResponse, permissionsResponse] = await Promise.all([
      fetch("http://127.0.0.1:8000/security/roles", {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      }),
      fetch("http://127.0.0.1:8000/security/permissions", {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      }),
    ]);

    const rolesJson = await rolesResponse.json();
    const permissionsJson = await permissionsResponse.json();

    roles.value = rolesJson.data || [];
    permissions.value = permissionsJson.data || [];
  } catch (e) {
    error.value = "Failed to load security data.";
  } finally {
    loading.value = false;
  }
}

onMounted(fetchSecurityData);
</script>

<template>
  <div class="space-y-8">
    <div>
      <h1 class="text-3xl font-bold text-gray-900">
        Security & Roles
      </h1>
      <p class="text-gray-500 mt-2">
        Manage enterprise roles, permissions, and API access rules.
      </p>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading security configuration...
    </div>

    <div v-if="error" class="bg-red-50 text-red-700 p-4 rounded-xl">
      {{ error }}
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div
        v-for="role in roles"
        :key="role.id"
        class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6"
      >
        <h2 class="text-xl font-bold text-gray-900 capitalize">
          {{ role.name }}
        </h2>

        <p class="text-sm text-gray-500 mt-1">
          {{ role.permissions?.length || 0 }} permissions assigned
        </p>

        <div class="mt-4 flex flex-wrap gap-2">
          <span
            v-for="permission in role.permissions"
            :key="permission.id"
            class="text-xs bg-gray-100 text-gray-700 px-3 py-1 rounded-full"
          >
            {{ permission.name }}
          </span>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
      <h2 class="text-xl font-bold text-gray-900 mb-4">
        All Permissions
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-3">
        <div
          v-for="permission in permissions"
          :key="permission.id"
          class="bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700"
        >
          {{ permission.name }}
        </div>
      </div>
    </div>
  </div>
</template>
