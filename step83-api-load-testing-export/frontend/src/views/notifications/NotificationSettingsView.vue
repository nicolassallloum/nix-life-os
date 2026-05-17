<script setup>
import { onMounted, ref } from "vue";
import {
  getNotificationPreferences,
  updateNotificationPreferences,
} from "../../api/notifications";

const loading = ref(false);
const saving = ref(false);

const form = ref({
  meal_reminders_enabled: true,
  breakfast_time: "08:00",
  lunch_time: "13:00",
  dinner_time: "19:00",

  weight_reminders_enabled: true,
  weight_reminder_time: "08:30",

  expense_reminders_enabled: true,
  expense_reminder_time: "21:00",

  finance_alerts_enabled: true,
  health_alerts_enabled: true,
  life_balance_alerts_enabled: true,

  daily_expense_warning_limit: 50,
  life_balance_warning_score: 60,
});

const loadPreferences = async () => {
  loading.value = true;

  try {
    const response = await getNotificationPreferences();

    form.value = {
      ...form.value,
      ...response.data,
    };
  } catch (error) {
    console.error("Failed to load preferences", error);
  } finally {
    loading.value = false;
  }
};

const savePreferences = async () => {
  saving.value = true;

  try {
    await updateNotificationPreferences(form.value);
    alert("Notification settings saved successfully.");
  } catch (error) {
    console.error("Failed to save preferences", error);
    alert("Failed to save settings.");
  } finally {
    saving.value = false;
  }
};

onMounted(() => {
  loadPreferences();
});
</script>

<template>
  <div class="p-8 space-y-8">
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Notification Settings</h1>
      <p class="text-gray-500 mt-1">
        Configure reminders and alert rules.
      </p>
    </div>

    <div v-if="loading" class="text-gray-500">
      Loading settings...
    </div>

    <form v-else @submit.prevent="savePreferences" class="space-y-6">
      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">
        <h2 class="text-xl font-bold text-gray-900">Meal Reminders</h2>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.meal_reminders_enabled" />
          <span>Enable meal reminders</span>
        </label>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="text-sm text-gray-500">Breakfast Time</label>
            <input
              type="time"
              v-model="form.breakfast_time"
              class="w-full mt-1 border rounded-xl px-4 py-2"
            />
          </div>

          <div>
            <label class="text-sm text-gray-500">Lunch Time</label>
            <input
              type="time"
              v-model="form.lunch_time"
              class="w-full mt-1 border rounded-xl px-4 py-2"
            />
          </div>

          <div>
            <label class="text-sm text-gray-500">Dinner Time</label>
            <input
              type="time"
              v-model="form.dinner_time"
              class="w-full mt-1 border rounded-xl px-4 py-2"
            />
          </div>
        </div>
      </section>

      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">
        <h2 class="text-xl font-bold text-gray-900">Weight Reminder</h2>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.weight_reminders_enabled" />
          <span>Enable weight reminder</span>
        </label>

        <div>
          <label class="text-sm text-gray-500">Reminder Time</label>
          <input
            type="time"
            v-model="form.weight_reminder_time"
            class="w-full mt-1 border rounded-xl px-4 py-2"
          />
        </div>
      </section>

      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">
        <h2 class="text-xl font-bold text-gray-900">Expense Reminder</h2>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.expense_reminders_enabled" />
          <span>Enable expense reminder</span>
        </label>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="text-sm text-gray-500">Reminder Time</label>
            <input
              type="time"
              v-model="form.expense_reminder_time"
              class="w-full mt-1 border rounded-xl px-4 py-2"
            />
          </div>

          <div>
            <label class="text-sm text-gray-500">Daily Expense Warning Limit</label>
            <input
              type="number"
              v-model="form.daily_expense_warning_limit"
              class="w-full mt-1 border rounded-xl px-4 py-2"
            />
          </div>
        </div>
      </section>

      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">
        <h2 class="text-xl font-bold text-gray-900">Smart Alerts</h2>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.finance_alerts_enabled" />
          <span>Enable finance alerts</span>
        </label>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.health_alerts_enabled" />
          <span>Enable health alerts</span>
        </label>

        <label class="flex items-center gap-3">
          <input type="checkbox" v-model="form.life_balance_alerts_enabled" />
          <span>Enable Life Balance alerts</span>
        </label>

        <div>
          <label class="text-sm text-gray-500">Life Balance Warning Score</label>
          <input
            type="number"
            min="0"
            max="100"
            v-model="form.life_balance_warning_score"
            class="w-full mt-1 border rounded-xl px-4 py-2"
          />
        </div>
      </section>

      <button
        type="submit"
        class="px-6 py-3 rounded-xl bg-gray-900 text-white hover:bg-gray-800"
        :disabled="saving"
      >
        {{ saving ? "Saving..." : "Save Settings" }}
      </button>
    </form>
  </div>
</template>
