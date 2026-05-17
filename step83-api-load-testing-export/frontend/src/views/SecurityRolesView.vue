<script setup>
import { ref, onMounted } from "vue";
import apiFetch from "@/services/apiFetch";
import { getApiErrorMessage } from "@/services/api";

const roles = ref([]);
const permissions = ref([]);
const loading = ref(false);
const error = ref(null);

async function fetchSecurityData() {
  loading.value = true;
  error.value = null;

  try {
    const [rolesJson, permissionsJson] = await Promise.all([
      apiFetch("/security/roles"),
      apiFetch("/security/permissions"),
    ]);

    roles.value = Array.isArray(rolesJson?.data) ? rolesJson.data : [];
    permissions.value = Array.isArray(permissionsJson?.data) ? permissionsJson.data : [];
  } catch (e) {
    error.value = getApiErrorMessage(e, "Failed to load security data.");
    roles.value = [];
    permissions.value = [];
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

    <div v-else-if="error" class="bg-red-50 text-red-700 p-4 rounded-xl">
      <p class="font-semibold">Unable to load security configuration.</p>
      <p class="mt-1 text-sm">{{ error }}</p>
      <button
        class="mt-3 rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white hover:bg-red-800"
        type="button"
        @click="fetchSecurityData"
      >
        Retry
      </button>
    </div>

    <template v-else>
      <div v-if="roles.length === 0" class="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-gray-500">
        No roles found.
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div
          v-for="role in roles"
          :key="role.id || role.name"
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
              v-for="permission in role.permissions || []"
              :key="permission.id || permission.name"
              class="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700"
            >
              {{ permission.name }}
            </span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-xl font-bold text-gray-900">
          All Permissions
        </h2>
        <p class="text-sm text-gray-500 mt-1">
          {{ permissions.length }} permissions registered.
        </p>

        <div v-if="permissions.length === 0" class="mt-4 rounded-xl border border-dashed border-gray-300 p-4 text-sm text-gray-500">
          No permissions found.
        </div>

        <div v-else class="mt-4 flex flex-wrap gap-2">
          <span
            v-for="permission in permissions"
            :key="permission.id || permission.name"
            class="rounded-full bg-gray-100 px-3 py-1 text-xs font-semibold text-gray-700"
          >
            {{ permission.name }}
          </span>
        </div>
      </div>
    </template>
  </div>
</template>
