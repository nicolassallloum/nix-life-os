<script setup>
import { onMounted, ref } from "vue";
import {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
} from "../../api/notifications";

const notifications = ref([]);
const loading = ref(false);
const selectedFilter = ref("all");

const loadNotifications = async () => {
  loading.value = true;

  try {
    const params = {};

    if (selectedFilter.value === "unread") {
      params.is_read = false;
    }

    if (selectedFilter.value === "read") {
      params.is_read = true;
    }

    const response = await getNotifications(params);
    notifications.value = response.data.data;
  } catch (error) {
    console.error("Failed to load notifications", error);
  } finally {
    loading.value = false;
  }
};

const handleMarkAsRead = async (id) => {
  await markNotificationAsRead(id);
  await loadNotifications();
};

const handleMarkAllAsRead = async () => {
  await markAllNotificationsAsRead();
  await loadNotifications();
};

const handleDelete = async (id) => {
  await deleteNotification(id);
  await loadNotifications();
};

const severityClass = (severity) => {
  if (severity === "danger") {
    return "bg-red-100 text-red-700 border-red-200";
  }

  if (severity === "warning") {
    return "bg-yellow-100 text-yellow-700 border-yellow-200";
  }

  if (severity === "success") {
    return "bg-green-100 text-green-700 border-green-200";
  }

  return "bg-blue-100 text-blue-700 border-blue-200";
};

onMounted(() => {
  loadNotifications();
});
</script>

<template>
  <div class="p-8 space-y-8">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Notifications</h1>
        <p class="text-gray-500 mt-1">
          Manage reminders, alerts, and system messages.
        </p>
      </div>

      <button
        @click="handleMarkAllAsRead"
        class="px-4 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-800"
      >
        Mark All as Read
      </button>
    </div>

    <div class="flex gap-3">
      <button
        @click="selectedFilter = 'all'; loadNotifications()"
        class="px-4 py-2 rounded-xl border"
        :class="selectedFilter === 'all' ? 'bg-gray-900 text-white' : 'bg-white'"
      >
        All
      </button>

      <button
        @click="selectedFilter = 'unread'; loadNotifications()"
        class="px-4 py-2 rounded-xl border"
        :class="selectedFilter === 'unread' ? 'bg-gray-900 text-white' : 'bg-white'"
      >
        Unread
      </button>

      <button
        @click="selectedFilter = 'read'; loadNotifications()"
        class="px-4 py-2 rounded-xl border"
        :class="selectedFilter === 'read' ? 'bg-gray-900 text-white' : 'bg-white'"
      >
        Read
      </button>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading notifications...
    </div>

    <div v-else class="space-y-4">
      <div
        v-for="notification in notifications"
        :key="notification.id"
        class="bg-white border rounded-2xl p-5 shadow-sm"
        :class="notification.is_read ? 'opacity-70' : 'border-gray-300'"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="space-y-2">
            <div class="flex items-center gap-3">
              <span
                class="px-3 py-1 rounded-full text-xs font-semibold border"
                :class="severityClass(notification.severity)"
              >
                {{ notification.severity }}
              </span>

              <span class="text-xs text-gray-400 uppercase">
                {{ notification.notification_type }}
              </span>

              <span
                v-if="!notification.is_read"
                class="w-2 h-2 rounded-full bg-blue-600"
              ></span>
            </div>

            <h2 class="text-lg font-bold text-gray-900">
              {{ notification.title }}
            </h2>

            <p class="text-gray-600">
              {{ notification.message }}
            </p>

            <p class="text-xs text-gray-400">
              {{ new Date(notification.created_at).toLocaleString() }}
            </p>
          </div>

          <div class="flex gap-2">
            <button
              v-if="!notification.is_read"
              @click="handleMarkAsRead(notification.id)"
              class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 hover:bg-blue-100 text-sm"
            >
              Read
            </button>

            <button
              @click="handleDelete(notification.id)"
              class="px-3 py-2 rounded-xl bg-red-50 text-red-700 hover:bg-red-100 text-sm"
            >
              Delete
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="notifications.length === 0"
        class="bg-white rounded-2xl border p-8 text-center text-gray-500"
      >
        No notifications found.
      </div>
    </div>
  </div>
</template>
