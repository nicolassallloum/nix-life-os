<script setup>
import { onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import { getUnreadNotificationCount } from "../../api/notifications";

const unreadCount = ref(0);

const loadUnreadCount = async () => {
  try {
    const response = await getUnreadNotificationCount();
    unreadCount.value = response.data.unread_count;
  } catch (error) {
    console.error("Failed to load unread notification count", error);
  }
};

onMounted(() => {
  loadUnreadCount();

  setInterval(() => {
    loadUnreadCount();
  }, 60000);
});
</script>

<template>
  <RouterLink
    to="/notifications"
    class="relative inline-flex items-center justify-center w-11 h-11 rounded-xl bg-white border hover:bg-gray-50"
  >
    <span class="text-xl">🔔</span>

    <span
      v-if="unreadCount > 0"
      class="absolute -top-1 -right-1 min-w-5 h-5 px-1 rounded-full bg-red-600 text-white text-xs flex items-center justify-center"
    >
      {{ unreadCount }}
    </span>
  </RouterLink>
</template>
