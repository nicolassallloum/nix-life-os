<template>
  <section class="calendar-page">
    <header class="page-header">
      <div>
        <p class="eyebrow">Productivity</p>
        <h1>Calendar / Schedule</h1>
        <p class="subtitle">
          Manage events, schedules, daily planning, weekly planning, monthly planning, and reminders.
        </p>
      </div>

      <button class="primary-btn" type="button" @click="openCreateForm">
        + New Event
      </button>
    </header>

    <div class="toolbar card">
      <div class="view-switcher" aria-label="Calendar view switcher">
        <button
          v-for="option in viewOptions"
          :key="option.value"
          type="button"
          :class="['view-btn', { active: filters.view === option.value }]"
          @click="changeView(option.value)"
        >
          {{ option.label }}
        </button>
      </div>

      <div class="date-filter">
        <label for="calendar-date">Date</label>
        <input id="calendar-date" v-model="filters.date" type="date" @change="fetchEvents" />
      </div>

      <button class="secondary-btn" type="button" :disabled="loading" @click="fetchEvents">
        {{ loading ? "Loading..." : "Refresh" }}
      </button>
    </div>

    <div v-if="errorMessage" class="alert error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert success">
      {{ successMessage }}
    </div>

    <section class="summary-grid">
      <article class="card summary-card">
        <span>Total Events</span>
        <strong>{{ events.length }}</strong>
      </article>
      <article class="card summary-card">
        <span>Scheduled</span>
        <strong>{{ scheduledCount }}</strong>
      </article>
      <article class="card summary-card">
        <span>With Reminders</span>
        <strong>{{ reminderCount }}</strong>
      </article>
      <article class="card summary-card">
        <span>Current View</span>
        <strong>{{ activeViewLabel }}</strong>
      </article>
    </section>

    <section class="card calendar-panel">
      <div class="panel-header">
        <div>
          <h2>{{ activeViewLabel }} View</h2>
          <p v-if="rangeLabel">{{ rangeLabel }}</p>
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        Loading calendar events...
      </div>

      <div v-else-if="events.length === 0" class="empty-state">
        <h3>No calendar events found</h3>
        <p>Create your first event or change the selected date/view.</p>
        <button class="primary-btn" type="button" @click="openCreateForm">Create Event</button>
      </div>

      <div v-else class="events-list">
        <article v-for="event in events" :key="event.id" class="event-card">
          <div class="event-main">
            <div class="event-date-box">
              <strong>{{ formatDay(event.start_time) }}</strong>
              <span>{{ formatMonth(event.start_time) }}</span>
            </div>

            <div class="event-content">
              <div class="event-title-row">
                <h3>{{ event.title }}</h3>
                <span :class="['status-badge', event.status]">{{ event.status }}</span>
              </div>

              <p v-if="event.description" class="event-description">{{ event.description }}</p>

              <div class="event-meta">
                <span>🕒 {{ formatDateTime(event.start_time) }} - {{ formatTime(event.end_time) }}</span>
                <span>🏷️ {{ event.event_type || event.type || "event" }}</span>
                <span v-if="event.location">📍 {{ event.location }}</span>
                <span v-if="event.has_reminder || event.reminder_at" class="reminder-badge">
                  🔔 Reminder: {{ formatDateTime(event.reminder_at) }}
                </span>
              </div>
            </div>
          </div>

          <div class="event-actions">
            <button class="secondary-btn" type="button" @click="openEditForm(event)">Edit</button>
            <button class="danger-btn" type="button" @click="deleteEvent(event)">Delete</button>
          </div>
        </article>
      </div>
    </section>

    <div v-if="showForm" class="modal-backdrop" @click.self="closeForm">
      <form class="modal card" @submit.prevent="saveEvent">
        <div class="modal-header">
          <h2>{{ editingEventId ? "Edit Event" : "Create Event" }}</h2>
          <button type="button" class="icon-btn" @click="closeForm">×</button>
        </div>

        <div class="form-grid">
          <label>
            Title <span>*</span>
            <input v-model.trim="form.title" type="text" required placeholder="Event title" />
          </label>

          <label>
            Event Type <span>*</span>
            <select v-model="form.event_type" required>
              <option value="meeting">Meeting</option>
              <option value="personal">Personal</option>
              <option value="task">Task</option>
              <option value="deadline">Deadline</option>
              <option value="reminder">Reminder</option>
            </select>
          </label>

          <label>
            Status <span>*</span>
            <select v-model="form.status" required>
              <option value="scheduled">Scheduled</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </label>

          <label>
            Location
            <input v-model.trim="form.location" type="text" placeholder="Location" />
          </label>

          <label>
            Start Time <span>*</span>
            <input v-model="form.start_time" type="datetime-local" required />
          </label>

          <label>
            End Time
            <input v-model="form.end_time" type="datetime-local" />
          </label>

          <label>
            Reminder Time
            <input v-model="form.reminder_at" type="datetime-local" />
          </label>
        </div>

        <label class="full-width">
          Description
          <textarea v-model.trim="form.description" rows="4" placeholder="Event description"></textarea>
        </label>

        <div class="modal-actions">
          <button type="button" class="secondary-btn" @click="closeForm">Cancel</button>
          <button type="submit" class="primary-btn" :disabled="saving">
            {{ saving ? "Saving..." : editingEventId ? "Update Event" : "Create Event" }}
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import calendarService from "@/services/calendarService";

const today = new Date().toISOString().slice(0, 10);

const viewOptions = [
  { label: "Day", value: "day" },
  { label: "Week", value: "week" },
  { label: "Month", value: "month" },
];

const filters = reactive({
  view: "month",
  date: today,
});

const defaultForm = () => ({
  title: "",
  description: "",
  event_type: "meeting",
  status: "scheduled",
  start_time: `${today}T09:00`,
  end_time: `${today}T10:00`,
  location: "",
  reminder_at: "",
});

const events = ref([]);
const loading = ref(false);
const saving = ref(false);
const showForm = ref(false);
const editingEventId = ref(null);
const errorMessage = ref("");
const successMessage = ref("");
const range = reactive({ from: "", to: "" });
const form = reactive(defaultForm());

const activeViewLabel = computed(() => {
  return viewOptions.find((option) => option.value === filters.view)?.label || "Month";
});

const scheduledCount = computed(() => events.value.filter((event) => event.status === "scheduled").length);
const reminderCount = computed(() => events.value.filter((event) => event.has_reminder || event.reminder_at).length);
const rangeLabel = computed(() => {
  if (!range.from || !range.to) return "";
  return `${formatDateTime(range.from)} → ${formatDateTime(range.to)}`;
});

function resetMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function setForm(payload) {
  Object.assign(form, defaultForm(), payload);
}

function normalizeDateTimeForInput(value) {
  if (!value) return "";
  return String(value).replace(" ", "T").slice(0, 16);
}

function normalizeDateTimeForApi(value) {
  if (!value) return null;
  const normalized = String(value).replace("T", " ");
  return normalized.length === 16 ? `${normalized}:00` : normalized;
}

function buildPayload() {
  return {
    title: form.title,
    description: form.description || null,
    event_type: form.event_type,
    status: form.status,
    start_time: normalizeDateTimeForApi(form.start_time),
    end_time: normalizeDateTimeForApi(form.end_time),
    location: form.location || null,
    reminder_at: normalizeDateTimeForApi(form.reminder_at),
  };
}

async function fetchEvents() {
  loading.value = true;
  resetMessages();

  try {
    const response = await calendarService.getEvents({
      view: filters.view,
      date: filters.date,
    });

    const payload = response?.data || {};
    events.value = payload.events || [];
    range.from = payload.from || "";
    range.to = payload.to || "";
  } catch (error) {
    errorMessage.value = error.response?.data?.message || "Unable to load calendar events.";
  } finally {
    loading.value = false;
  }
}

function changeView(view) {
  filters.view = view;
  fetchEvents();
}

function openCreateForm() {
  resetMessages();
  editingEventId.value = null;
  setForm(defaultForm());
  showForm.value = true;
}

function openEditForm(event) {
  resetMessages();
  editingEventId.value = event.id;
  setForm({
    title: event.title || "",
    description: event.description || "",
    event_type: event.event_type || event.type || "meeting",
    status: event.status || "scheduled",
    start_time: normalizeDateTimeForInput(event.start_time || event.start_at),
    end_time: normalizeDateTimeForInput(event.end_time || event.end_at),
    location: event.location || "",
    reminder_at: normalizeDateTimeForInput(event.reminder_at || event.metadata?.reminder_at),
  });
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  editingEventId.value = null;
}

async function saveEvent() {
  saving.value = true;
  resetMessages();

  try {
    if (editingEventId.value) {
      await calendarService.updateEvent(editingEventId.value, buildPayload());
      successMessage.value = "Calendar event updated successfully.";
    } else {
      await calendarService.createEvent(buildPayload());
      successMessage.value = "Calendar event created successfully.";
    }

    closeForm();
    await fetchEvents();
  } catch (error) {
    errorMessage.value = error.response?.data?.message || "Unable to save calendar event.";
  } finally {
    saving.value = false;
  }
}

async function deleteEvent(event) {
  const confirmed = window.confirm(`Delete calendar event: ${event.title}?`);
  if (!confirmed) return;

  resetMessages();

  try {
    await calendarService.deleteEvent(event.id);
    successMessage.value = "Calendar event deleted successfully.";
    await fetchEvents();
  } catch (error) {
    errorMessage.value = error.response?.data?.message || "Unable to delete calendar event.";
  }
}

function formatDateTime(value) {
  if (!value) return "N/A";
  return new Date(String(value).replace(" ", "T")).toLocaleString();
}

function formatTime(value) {
  if (!value) return "N/A";
  return new Date(String(value).replace(" ", "T")).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDay(value) {
  if (!value) return "--";
  return new Date(String(value).replace(" ", "T")).getDate();
}

function formatMonth(value) {
  if (!value) return "---";
  return new Date(String(value).replace(" ", "T")).toLocaleString([], { month: "short" });
}

onMounted(fetchEvents);
</script>

<style scoped>
.calendar-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1.5rem;
}

.page-header,
.toolbar,
.panel-header,
.event-main,
.event-title-row,
.event-actions,
.modal-header,
.modal-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.eyebrow {
  margin: 0 0 0.25rem;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #64748b;
}

h1,
h2,
h3,
p {
  margin-top: 0;
}

.subtitle,
.panel-header p,
.event-description {
  color: #64748b;
}

.card {
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 12px 30px rgba(15, 23, 42, 0.06);
}

.toolbar {
  flex-wrap: wrap;
  padding: 1rem;
}

.view-switcher {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.view-btn,
.primary-btn,
.secondary-btn,
.danger-btn,
.icon-btn {
  border: 0;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  transition: 0.2s ease;
}

.view-btn,
.secondary-btn {
  padding: 0.7rem 1rem;
  background: #f1f5f9;
  color: #334155;
}

.view-btn.active,
.primary-btn {
  padding: 0.75rem 1.1rem;
  background: #2563eb;
  color: #ffffff;
}

.danger-btn {
  padding: 0.7rem 1rem;
  background: #fee2e2;
  color: #b91c1c;
}

.icon-btn {
  width: 36px;
  height: 36px;
  background: #f1f5f9;
  color: #0f172a;
  font-size: 1.3rem;
}

.date-filter {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 700;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 0.8rem;
  font: inherit;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 1rem;
}

.summary-card {
  padding: 1rem;
}

.summary-card span {
  color: #64748b;
  font-size: 0.9rem;
}

.summary-card strong {
  display: block;
  margin-top: 0.5rem;
  font-size: 1.7rem;
}

.calendar-panel {
  padding: 1.25rem;
}

.loading-state,
.empty-state {
  padding: 3rem 1rem;
  text-align: center;
  color: #64748b;
}

.events-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.event-card {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  background: #f8fafc;
}

.event-date-box {
  min-width: 72px;
  padding: 0.75rem;
  border-radius: 14px;
  background: #ffffff;
  text-align: center;
}

.event-date-box strong {
  display: block;
  font-size: 1.6rem;
}

.event-date-box span {
  color: #64748b;
  font-size: 0.85rem;
  text-transform: uppercase;
}

.event-content {
  flex: 1;
}

.event-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  color: #475569;
  font-size: 0.9rem;
}

.status-badge,
.reminder-badge {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.35rem 0.7rem;
  font-size: 0.8rem;
  font-weight: 700;
}

.status-badge {
  background: #dbeafe;
  color: #1d4ed8;
}

.status-badge.completed {
  background: #dcfce7;
  color: #15803d;
}

.status-badge.cancelled {
  background: #fee2e2;
  color: #b91c1c;
}

.reminder-badge {
  background: #fef3c7;
  color: #92400e;
}

.alert {
  border-radius: 14px;
  padding: 1rem;
  font-weight: 700;
}

.alert.error {
  background: #fee2e2;
  color: #991b1b;
}

.alert.success {
  background: #dcfce7;
  color: #166534;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(15, 23, 42, 0.55);
}

.modal {
  width: min(760px, 100%);
  max-height: 90vh;
  overflow: auto;
  padding: 1.5rem;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

label {
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
  color: #334155;
  font-weight: 700;
}

label span {
  color: #dc2626;
}

.full-width {
  margin-top: 1rem;
}

.modal-actions {
  margin-top: 1.25rem;
  justify-content: flex-end;
}

@media (max-width: 900px) {
  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .event-card,
  .event-main,
  .event-actions {
    align-items: flex-start;
    flex-direction: column;
  }
}

@media (max-width: 640px) {
  .calendar-page {
    padding: 1rem;
  }

  .summary-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .page-header,
  .toolbar {
    align-items: stretch;
    flex-direction: column;
  }
}
</style>
