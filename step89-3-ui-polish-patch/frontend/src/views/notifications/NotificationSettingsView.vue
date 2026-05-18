<script setup>
import { onMounted, ref } from 'vue'
import {
  getNotificationPreferences,
  updateNotificationPreferences,
} from '../../api/notifications'

const loading = ref(false)
const saving = ref(false)
const loadError = ref('')
const saveMessage = ref('')
const saveError = ref('')

const form = ref({
  meal_reminders_enabled: true,
  breakfast_time: '08:00',
  lunch_time: '13:00',
  dinner_time: '19:00',

  weight_reminders_enabled: true,
  weight_reminder_time: '08:30',

  expense_reminders_enabled: true,
  expense_reminder_time: '21:00',

  finance_alerts_enabled: true,
  health_alerts_enabled: true,
  life_balance_alerts_enabled: true,

  daily_expense_warning_limit: 50,
  life_balance_warning_score: 60,
})

const loadPreferences = async () => {
  loading.value = true
  loadError.value = ''

  try {
    const response = await getNotificationPreferences()
    const preferences = response?.data?.data ?? response?.data ?? {}

    form.value = {
      ...form.value,
      ...preferences,
    }
  } catch (error) {
    console.error('Failed to load preferences', error)
    loadError.value = 'Notification settings could not be loaded. If the backend Docker service is off, this is expected.'
  } finally {
    loading.value = false
  }
}

const savePreferences = async () => {
  saving.value = true
  saveMessage.value = ''
  saveError.value = ''

  try {
    await updateNotificationPreferences(form.value)
    saveMessage.value = 'Notification settings saved successfully.'
  } catch (error) {
    console.error('Failed to save preferences', error)
    saveError.value = 'Failed to save settings. If the backend Docker service is off, this is expected.'
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadPreferences()
})
</script>

<template>
  <div class="nix-notification-settings nix-section">
    <header class="nix-section-header">
      <div>
        <p class="nix-kicker">Notifications</p>
        <h1 class="nix-page-title">Notification Settings</h1>
        <p class="nix-section-subtitle">
          Configure meal reminders, health checks, finance alerts, and Life Balance rules.
        </p>
      </div>
    </header>

    <div v-if="loading" class="nix-loading-state">
      Loading notification settings...
    </div>

    <div v-else-if="loadError" class="nix-alert-warning">
      {{ loadError }}
    </div>

    <form v-else class="nix-settings-form" @submit.prevent="savePreferences">
      <section class="nix-card nix-settings-card">
        <div class="nix-card-header">
          <div>
            <h2 class="nix-card-title">Meal Reminders</h2>
            <p class="nix-card-subtitle">Reminder times for daily meals.</p>
          </div>
        </div>

        <label class="nix-toggle-row">
          <span class="nix-toggle-copy">
            <span class="nix-toggle-title">Enable meal reminders</span>
            <span class="nix-toggle-description">Show reminders for breakfast, lunch, and dinner.</span>
          </span>
          <input
            v-model="form.meal_reminders_enabled"
            type="checkbox"
            class="nix-toggle-input"
          />
        </label>

        <div class="nix-form-grid nix-grid-3">
          <div>
            <label class="nix-label" for="breakfast_time">Breakfast Time</label>
            <input
              id="breakfast_time"
              v-model="form.breakfast_time"
              type="time"
              class="nix-input"
            />
          </div>

          <div>
            <label class="nix-label" for="lunch_time">Lunch Time</label>
            <input
              id="lunch_time"
              v-model="form.lunch_time"
              type="time"
              class="nix-input"
            />
          </div>

          <div>
            <label class="nix-label" for="dinner_time">Dinner Time</label>
            <input
              id="dinner_time"
              v-model="form.dinner_time"
              type="time"
              class="nix-input"
            />
          </div>
        </div>
      </section>

      <section class="nix-card nix-settings-card">
        <div class="nix-card-header">
          <div>
            <h2 class="nix-card-title">Weight Reminder</h2>
            <p class="nix-card-subtitle">Daily reminder for weight tracking.</p>
          </div>
        </div>

        <label class="nix-toggle-row">
          <span class="nix-toggle-copy">
            <span class="nix-toggle-title">Enable weight reminder</span>
            <span class="nix-toggle-description">Receive one daily reminder to log your weight.</span>
          </span>
          <input
            v-model="form.weight_reminders_enabled"
            type="checkbox"
            class="nix-toggle-input"
          />
        </label>

        <div class="nix-form-grid">
          <div>
            <label class="nix-label" for="weight_reminder_time">Reminder Time</label>
            <input
              id="weight_reminder_time"
              v-model="form.weight_reminder_time"
              type="time"
              class="nix-input"
            />
          </div>
        </div>
      </section>

      <section class="nix-card nix-settings-card">
        <div class="nix-card-header">
          <div>
            <h2 class="nix-card-title">Expense Reminder</h2>
            <p class="nix-card-subtitle">Finance reminders and spending warning limits.</p>
          </div>
        </div>

        <label class="nix-toggle-row">
          <span class="nix-toggle-copy">
            <span class="nix-toggle-title">Enable expense reminder</span>
            <span class="nix-toggle-description">Remind me to review daily expenses and spending.</span>
          </span>
          <input
            v-model="form.expense_reminders_enabled"
            type="checkbox"
            class="nix-toggle-input"
          />
        </label>

        <div class="nix-form-grid nix-grid-2">
          <div>
            <label class="nix-label" for="expense_reminder_time">Reminder Time</label>
            <input
              id="expense_reminder_time"
              v-model="form.expense_reminder_time"
              type="time"
              class="nix-input"
            />
          </div>

          <div>
            <label class="nix-label" for="daily_expense_warning_limit">Daily Expense Warning Limit</label>
            <input
              id="daily_expense_warning_limit"
              v-model="form.daily_expense_warning_limit"
              type="number"
              min="0"
              class="nix-input"
            />
          </div>
        </div>
      </section>

      <section class="nix-card nix-settings-card">
        <div class="nix-card-header">
          <div>
            <h2 class="nix-card-title">Smart Alerts</h2>
            <p class="nix-card-subtitle">Enable cross-module alerts for finance, health, and Life Balance.</p>
          </div>
        </div>

        <div class="nix-settings-toggle-grid">
          <label class="nix-toggle-row">
            <span class="nix-toggle-copy">
              <span class="nix-toggle-title">Finance alerts</span>
              <span class="nix-toggle-description">Warn me about important financial changes.</span>
            </span>
            <input
              v-model="form.finance_alerts_enabled"
              type="checkbox"
              class="nix-toggle-input"
            />
          </label>

          <label class="nix-toggle-row">
            <span class="nix-toggle-copy">
              <span class="nix-toggle-title">Health alerts</span>
              <span class="nix-toggle-description">Warn me about important health tracking changes.</span>
            </span>
            <input
              v-model="form.health_alerts_enabled"
              type="checkbox"
              class="nix-toggle-input"
            />
          </label>

          <label class="nix-toggle-row">
            <span class="nix-toggle-copy">
              <span class="nix-toggle-title">Life Balance alerts</span>
              <span class="nix-toggle-description">Warn me when the Life Balance score needs attention.</span>
            </span>
            <input
              v-model="form.life_balance_alerts_enabled"
              type="checkbox"
              class="nix-toggle-input"
            />
          </label>
        </div>

        <div class="nix-form-grid">
          <div>
            <label class="nix-label" for="life_balance_warning_score">Life Balance Warning Score</label>
            <input
              id="life_balance_warning_score"
              v-model="form.life_balance_warning_score"
              type="number"
              min="0"
              max="100"
              class="nix-input"
            />
          </div>
        </div>
      </section>

      <div v-if="saveMessage" class="nix-alert-success">
        {{ saveMessage }}
      </div>

      <div v-if="saveError" class="nix-alert-warning">
        {{ saveError }}
      </div>

      <div class="nix-form-actions nix-settings-actions">
        <button type="button" class="nix-button-secondary" :disabled="loading || saving" @click="loadPreferences">
          Reload
        </button>
        <button type="submit" class="nix-button" :disabled="saving">
          {{ saving ? 'Saving...' : 'Save Settings' }}
        </button>
      </div>
    </form>
  </div>
</template>
