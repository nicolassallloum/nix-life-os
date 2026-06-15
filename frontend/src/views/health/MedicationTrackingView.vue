<template>
  <div class="medication-input-page medication-page">
    <div class="page-header">
      <div>
        <h1>Medication Tracking</h1>
        <p>
          Track medications, daily dose, dose times, reminders, and today’s medication schedule.
        </p>
      </div>

      <button class="primary-btn" @click="resetForm">
        + New Medication
      </button>
    </div>

    <div v-if="error" class="alert alert-error">
      {{ error }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <!-- Today Summary -->
    <div class="summary-grid">
      <div class="summary-card">
        <span>Pending</span>
        <strong>{{ todaySummary.pending || 0 }}</strong>
      </div>

      <div class="summary-card">
        <span>Taken</span>
        <strong>{{ todaySummary.taken || 0 }}</strong>
      </div>

      <div class="summary-card">
        <span>Late</span>
        <strong>{{ todaySummary.late || 0 }}</strong>
      </div>

      <div class="summary-card">
        <span>Missed</span>
        <strong>{{ todaySummary.missed || 0 }}</strong>
      </div>

      <div class="summary-card">
        <span>Skipped</span>
        <strong>{{ todaySummary.skipped || 0 }}</strong>
      </div>
    </div>

    <!-- Today's Schedule -->
    <section class="card">
      <div class="section-header">
        <div>
          <h2>Today’s Medication Schedule</h2>
          <p>View today’s generated medication doses and update their status.</p>
        </div>

        <div class="header-actions">
          <button class="secondary-btn" :disabled="loadingToday" @click="loadTodaySchedule">
            Refresh
          </button>

          <button class="secondary-btn" :disabled="generatingDoses" @click="generateDoseMessage">
            Generate Doses
          </button>
        </div>
      </div>

      <div v-if="loadingToday" class="loading-state">
        Loading today’s medication schedule...
      </div>

      <div v-else-if="todayDoses.length === 0" class="empty-state">
        No medication doses generated for today yet.
        <br />
        Create a medication with dose times, then create reminders from the form below.
      </div>

      <div v-else class="dose-list">
        <div v-for="dose in todayDoses" :key="dose.id" class="dose-card">
          <div class="dose-main">
            <div>
              <h3>{{ dose.medication?.medication_name || "Medication" }}</h3>
              <p>
                {{ dose.medication?.dosage || "No dosage" }}
                <span v-if="dose.medication?.daily_dose">
                  • {{ dose.medication.daily_dose }}
                </span>
              </p>
              <small>
                Scheduled: {{ formatDateTime(dose.scheduled_for) }}
              </small>
            </div>

            <span :class="['status-badge', dose.status]">
              {{ dose.status }}
            </span>
          </div>

          <div class="dose-actions">
            <button
              v-if="dose.status === 'pending'"
              class="success-btn"
              :disabled="actionLoadingId === dose.id"
              @click="markDoseTaken(dose.id)"
            >
              Mark Taken
            </button>

            <button
              v-if="dose.status === 'pending'"
              class="warning-btn"
              :disabled="actionLoadingId === dose.id"
              @click="markDoseSkipped(dose.id)"
            >
              Skip
            </button>

            <span v-if="dose.taken_at" class="dose-note">
              Taken at: {{ formatDateTime(dose.taken_at) }}
            </span>

            <span v-if="dose.skip_reason" class="dose-note">
              Reason: {{ dose.skip_reason }}
            </span>
          </div>
        </div>
      </div>
    </section>

    <div class="content-grid">
      <!-- Medication Form -->
      <section class="card">
        <div class="section-header">
          <div>
            <h2>{{ editingId ? "Edit Medication" : "Add Medication" }}</h2>
            <p>
              Add medication details. Dose times are used to create reminders.
            </p>
          </div>
        </div>

        <form class="form-grid" @submit.prevent="submitMedication">
          <div class="form-group">
            <label>Medication Name *</label>
            <input
              v-model.trim="form.medication_name"
              type="text"
              placeholder="Example: Medication A"
              required
            />
          </div>

          <div class="form-group">
            <label>Dosage *</label>
            <input
              v-model.trim="form.dosage"
              type="text"
              placeholder="Example: 5 mg"
              required
            />
          </div>

          <div class="form-group">
            <label>Daily Dose</label>
            <input
              v-model.trim="form.daily_dose"
              type="text"
              placeholder="Example: 1 tablet daily"
            />
          </div>

          <div class="form-group">
            <label>Daily Times *</label>
            <select v-model.number="form.daily_times" required @change="syncMedicationTimes">
              <option :value="1">1 time per day</option>
              <option :value="2">2 times per day</option>
              <option :value="3">3 times per day</option>
            </select>
            <small>Select how many dosage times this medication has per day.</small>
          </div>

          <div
            v-for="(time, index) in form.times"
            :key="`medication-time-${index}`"
            class="form-group"
          >
            <label>Dosage Time {{ index + 1 }} *</label>
            <input
              v-model="time.dosage_time"
              type="time"
              required
            />
            <input
              v-model.trim="time.dosage_note"
              type="text"
              class="mt-2"
              placeholder="Optional note, example: After breakfast"
            />
          </div>

          <div class="form-group">
            <label>Frequency *</label>
            <input
              v-model.trim="form.frequency"
              type="text"
              placeholder="Example: Once daily"
              required
            />
          </div>

          <div class="form-group">
            <label>Status</label>
            <select v-model="form.status">
              <option value="active">Active</option>
              <option value="paused">Paused</option>
              <option value="completed">Completed</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div class="form-group">
            <label>Start Date *</label>
            <input v-model="form.start_date" type="date" required />
          </div>

          <div class="form-group">
            <label>End Date</label>
            <input v-model="form.end_date" type="date" />
          </div>

          <div class="form-group">
            <label>Prescribed By</label>
            <input
              v-model.trim="form.prescribed_by"
              type="text"
              placeholder="Doctor name"
            />
          </div>

          <div class="form-group full-width">
            <label>Notes</label>
            <textarea
              v-model.trim="form.notes"
              rows="3"
              placeholder="Example: Take after breakfast"
            ></textarea>
          </div>

          <div class="form-group full-width checkbox-row">
            <label>
              <input v-model="form.create_reminders" type="checkbox" />
              Automatically create reminders from dose times
            </label>
          </div>

          <div class="form-actions full-width">
            <button class="primary-btn" type="submit" :disabled="saving">
              {{ saving ? "Saving..." : editingId ? "Update Medication" : "Add Medication" }}
            </button>

            <button class="secondary-btn" type="button" @click="resetForm">
              Clear
            </button>
          </div>
        </form>
      </section>

      <!-- Medication List -->
      <section class="card">
        <div class="section-header">
          <div>
            <h2>Medication List</h2>
            <p>Manage your saved medications.</p>
          </div>

          <button class="secondary-btn" :disabled="loadingMedications" @click="loadMedications">
            Refresh
          </button>
        </div>

        <div class="filter-row">
          <input
            v-model.trim="filters.search"
            type="text"
            placeholder="Search medication..."
            @keyup.enter="loadMedications"
          />

          <select v-model="filters.status" @change="loadMedications">
            <option value="">All Statuses</option>
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="completed">Completed</option>
            <option value="inactive">Inactive</option>
          </select>

          <button class="secondary-btn" @click="loadMedications">
            Search
          </button>
        </div>

        <div v-if="loadingMedications" class="loading-state">
          Loading medications...
        </div>

        <div v-else-if="medications.length === 0" class="empty-state">
          No medications found.
        </div>

        <div v-else class="medication-list">
          <div
            v-for="medication in medications"
            :key="medication.id"
            class="medication-card"
          >
            <div class="medication-info">
              <div>
                <h3>{{ medication.medication_name }}</h3>
                <p>
                  {{ medication.dosage }}
                  <span v-if="medication.daily_dose">
                    • {{ medication.daily_dose }}
                  </span>
                </p>
                <small>
                  {{ medication.frequency }}
                  <span v-if="getMedicationTimes(medication).length">
                    • Times: {{ getMedicationTimes(medication).join(", ") }}
                  </span>
                </small>
              </div>

              <span :class="['status-badge', medication.status]">
                {{ medication.status }}
              </span>
            </div>

            <div class="medication-meta">
              <span>Start: {{ medication.start_date || "-" }}</span>
              <span>End: {{ medication.end_date || "-" }}</span>
              <span v-if="medication.prescribed_by">
                Doctor: {{ medication.prescribed_by }}
              </span>
            </div>

            <p v-if="medication.notes" class="notes">
              {{ medication.notes }}
            </p>

            <div class="medication-actions">
              <button class="secondary-btn" @click="editMedication(medication)">
                Edit
              </button>

              <button
                class="danger-btn"
                :disabled="deletingId === medication.id"
                @click="deleteMedication(medication.id)"
              >
                Delete
              </button>

              <button
                class="secondary-btn"
                @click="createRemindersForMedication(medication)"
              >
                Create Reminders
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from "vue";
import healthService from "@/services/healthService";

const medications = ref([]);
const todayDoses = ref([]);
const todaySummary = ref({
  pending: 0,
  taken: 0,
  late: 0,
  missed: 0,
  skipped: 0,
});

const loadingMedications = ref(false);
const loadingToday = ref(false);
const saving = ref(false);
const deletingId = ref(null);
const actionLoadingId = ref(null);
const generatingDoses = ref(false);

const error = ref("");
const successMessage = ref("");
const editingId = ref(null);

const filters = reactive({
  search: "",
  status: "",
});


function unwrapApiData(response) {
  return response?.data ?? response ?? {}
}

function unwrapApiArray(response) {
  const payload = unwrapApiData(response)
  const data = payload?.data ?? payload

  if (Array.isArray(data)) return data
  if (Array.isArray(data?.data)) return data.data
  if (Array.isArray(data?.medications)) return data.medications
  if (Array.isArray(data?.schedule)) return data.schedule

  return []
}

function getApiMessage(response, fallback = "Server error. Please try again later.") {
  const payload = unwrapApiData(response)
  return payload?.message || response?.message || fallback
}

function setUserError(err, fallback = "Server error. Please try again later.") {
  error.value = err?.response?.data?.message || err?.message || fallback
}


const form = reactive({
  medication_name: "",
  dosage: "",
  daily_dose: "",
  daily_times: 1,
  times: [
    {
      dosage_time: "",
      dosage_note: "",
    },
  ],
  frequency: "",
  start_date: getTodayDate(),
  end_date: "",
  status: "active",
  prescribed_by: "",
  notes: "",
  create_reminders: true,
});

onMounted(async () => {
  await Promise.all([
    loadMedications(),
    loadTodaySchedule(),
  ]);
});

function getTodayDate() {
  return new Date().toISOString().slice(0, 10);
}

function clearMessages() {
  error.value = "";
  successMessage.value = "";
}

function setSuccess(message) {
  successMessage.value = message;
  error.value = "";
}

function setError(message) {
  error.value = message;
  successMessage.value = "";
}

function getResponseData(response) {
  return response?.data?.data ?? response?.data ?? [];
}

function getErrorMessage(err, fallback = "Something went wrong.") {
  return (
    err?.response?.data?.message ||
    err?.response?.data?.error ||
    err?.message ||
    fallback
  );
}

function normalizeDailyTimes(value) {
  const parsed = Number(value);
  if (![1, 2, 3].includes(parsed)) return 1;
  return parsed;
}

function syncMedicationTimes() {
  const count = normalizeDailyTimes(form.daily_times);
  form.daily_times = count;

  while (form.times.length < count) {
    form.times.push({
      dosage_time: "",
      dosage_note: "",
    });
  }

  while (form.times.length > count) {
    form.times.pop();
  }
}

function buildMedicationTimes() {
  syncMedicationTimes();

  const times = form.times.map((item) => ({
    dosage_time: (item.dosage_time || "").trim(),
    dosage_note: (item.dosage_note || "").trim() || null,
  }));

  const invalid = times.find((item) => !/^\d{2}:\d{2}$/.test(item.dosage_time));

  if (invalid) {
    throw new Error("Please fill all dosage times using HH:mm format, example 08:00.");
  }

  return times;
}

function getMedicationTimes(medication) {
  if (Array.isArray(medication?.times) && medication.times.length) {
    return medication.times.map((item) => item.dosage_time).filter(Boolean);
  }

  if (Array.isArray(medication?.dose_times)) {
    return medication.dose_times.filter(Boolean);
  }

  return [];
}
async function loadMedications() {
  loadingMedications.value = true;
  clearMessages();

  try {
    const response = await healthService.medications.list({
      search: filters.search || undefined,
      status: filters.status || undefined,
    });

    medications.value = unwrapApiArray(response);
  } catch (err) {
    setUserError(err, "Failed to load medications.");
    medications.value = [];
  } finally {
    loadingMedications.value = false;
  }
}

async function loadTodaySchedule() {
  loadingToday.value = true;
  error.value = "";

  try {
    const response = await healthService.medicationReminders.today();
    const payload = unwrapApiData(response);
    const data = payload?.data ?? payload ?? {};

    todayDoses.value = Array.isArray(data)
      ? data
      : Array.isArray(data?.schedule)
        ? data.schedule
        : Array.isArray(data?.data)
          ? data.data
          : [];

    todaySummary.value = payload?.summary || data?.summary || {
      pending: todayDoses.value.filter((dose) => dose.status === "pending").length,
      taken: todayDoses.value.filter((dose) => dose.status === "taken").length,
      late: todayDoses.value.filter((dose) => dose.status === "late").length,
      missed: todayDoses.value.filter((dose) => dose.status === "missed").length,
      skipped: todayDoses.value.filter((dose) => dose.status === "skipped").length,
    };
  } catch (err) {
    setUserError(err, "Failed to load today’s medication schedule.");
    todayDoses.value = [];
    todaySummary.value = {
      pending: 0,
      taken: 0,
      late: 0,
      missed: 0,
      skipped: 0,
    };
  } finally {
    loadingToday.value = false;
  }
}

async function submitMedication() {
  clearMessages();
  saving.value = true;

  try {
    const times = buildMedicationTimes();
    const doseTimes = times.map((item) => item.dosage_time);

    const payload = {
      medication_name: form.medication_name,
      dosage: form.dosage,
      daily_dose: form.daily_dose || null,
      daily_times: normalizeDailyTimes(form.daily_times),
      times,
      frequency: form.frequency,
      start_date: form.start_date,
      end_date: form.end_date || null,
      status: form.status,
      doctor_name: form.prescribed_by || null,
      prescribed_by: form.prescribed_by || null,
      notes: form.notes || null,
    };

    let response;

    if (editingId.value) {
      response = await healthService.medications.update(editingId.value, payload);
      setSuccess("Medication updated successfully.");
    } else {
      response = await healthService.medications.create(payload);
      setSuccess("Medication created successfully.");
    }

    const savedMedication = response?.data?.data;

    if (!editingId.value && form.create_reminders && savedMedication?.id && doseTimes.length > 0) {
      await createReminders(savedMedication.id, doseTimes);
    }

    resetForm();
    await loadMedications();
    await loadTodaySchedule();
  } catch (err) {
    setError(getErrorMessage(err, err.message || "Failed to save medication."));
  } finally {
    saving.value = false;
  }
}

async function createReminders(medicationId, doseTimes) {
  const uniqueTimes = [...new Set(doseTimes)];

  for (const reminderTime of uniqueTimes) {
    await healthService.medicationReminders.create({
      medication_id: medicationId,
      reminder_time: reminderTime,
      frequency_type: "daily",
      notification_enabled: true,
      is_active: true,
    });
  }
}

async function createRemindersForMedication(medication) {
  clearMessages();

  try {
    // Phase 14: backend returns medication times through the times relation.
    // Support both current times relation and legacy dose_times.
    const doseTimes = getMedicationTimes(medication);

    if (!doseTimes.length) {
      setError("This medication does not have dose times.");
      return;
    }

    await createReminders(medication.id, doseTimes);

    setSuccess("Medication reminders created successfully.");
    await loadTodaySchedule();
  } catch (err) {
    setError(getErrorMessage(err, "Failed to create reminders."));
  }
}

function editMedication(medication) {
  editingId.value = medication.id;

  form.medication_name = medication.medication_name || "";
  form.dosage = medication.dosage || "";
  form.daily_dose = medication.daily_dose || "";
  form.daily_times = normalizeDailyTimes(medication.daily_times || getMedicationTimes(medication).length || 1);
  syncMedicationTimes();

  const medicationTimes = Array.isArray(medication.times) && medication.times.length
    ? medication.times
    : getMedicationTimes(medication).map((dosageTime) => ({
        dosage_time: dosageTime,
        dosage_note: "",
      }));

  form.times.forEach((item, index) => {
    item.dosage_time = medicationTimes[index]?.dosage_time || "";
    item.dosage_note = medicationTimes[index]?.dosage_note || "";
  });

  form.frequency = medication.frequency || "";
  form.start_date = medication.start_date || getTodayDate();
  form.end_date = medication.end_date || "";
  form.status = medication.status || "active";
  form.prescribed_by = medication.prescribed_by || "";
  form.notes = medication.notes || "";
  form.create_reminders = false;

  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function deleteMedication(id) {
  const confirmed = window.confirm("Are you sure you want to delete this medication?");
  if (!confirmed) return;

  deletingId.value = id;
  clearMessages();

  try {
    await healthService.medications.delete(id);
    setSuccess("Medication deleted successfully.");
    await loadMedications();
    await loadTodaySchedule();
  } catch (err) {
    setError(getErrorMessage(err, "Failed to delete medication."));
  } finally {
    deletingId.value = null;
  }
}

async function markDoseTaken(id) {
  actionLoadingId.value = id;
  clearMessages();

  try {
    const response = await healthService.medicationDoses.markTaken(id);
    setSuccess(response?.data?.message || "Medication dose marked as taken.");
    await loadTodaySchedule();
  } catch (err) {
    setError(getErrorMessage(err, "Failed to mark medication dose as taken."));
  } finally {
    actionLoadingId.value = null;
  }
}

async function markDoseSkipped(id) {
  const reason = window.prompt("Reason for skipping this dose:", "Skipped by user");
  if (reason === null) return;

  actionLoadingId.value = id;
  clearMessages();

  try {
    const response = await healthService.medicationDoses.markSkipped(id, {
      skip_reason: reason,
      notes: "Skipped from Medication Tracking screen",
    });

    setSuccess(response?.data?.message || "Medication dose marked as skipped.");
    await loadTodaySchedule();
  } catch (err) {
    setError(getErrorMessage(err, "Failed to skip medication dose."));
  } finally {
    actionLoadingId.value = null;
  }
}

async function generateDoseMessage() {
  generatingDoses.value = true;
  try {
    error.value = "";
    successMessage.value = "Medication doses are created from reminders. Create reminders for a medication, then refresh today’s schedule.";
    await loadTodaySchedule();
  } finally {
    generatingDoses.value = false;
  }
}

function resetForm() {
  editingId.value = null;

  form.medication_name = "";
  form.dosage = "";
  form.daily_dose = "";
  form.daily_times = 1;
  form.times = [
    {
      dosage_time: "",
      dosage_note: "",
    },
  ];
  form.frequency = "";
  form.start_date = getTodayDate();
  form.end_date = "";
  form.status = "active";
  form.prescribed_by = "";
  form.notes = "";
  form.create_reminders = true;
}

function formatDateTime(value) {
  if (!value) return "-";

  try {
    return new Date(value).toLocaleString();
  } catch {
    return value;
  }
}
</script>

<style scoped>
.medication-page {
  padding: 24px;
  color: #0f172a;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 24px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
}

.page-header p {
  margin: 8px 0 0;
  color: #64748b;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(120px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card {
  padding: 18px;
  border-radius: 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 13px;
  margin-bottom: 8px;
}

.summary-card strong {
  font-size: 28px;
  font-weight: 800;
}

.content-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
  gap: 24px;
  margin-top: 24px;
}

.card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  padding: 22px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
}

.section-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 18px;
}

.section-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 800;
}

.section-header p {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.alert {
  padding: 14px 16px;
  border-radius: 12px;
  margin-bottom: 18px;
  font-weight: 600;
}

.alert-error {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #991b1b;
}

.alert-success {
  background: #ecfdf5;
  border: 1px solid #bbf7d0;
  color: #166534;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.form-group label {
  font-size: 14px;
  font-weight: 700;
}

.form-group input,
.form-group select,
.form-group textarea,
.filter-row input,
.filter-row select {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 11px 12px;
  font-size: 14px;
  outline: none;
  background: #ffffff;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus,
.filter-row input:focus,
.filter-row select:focus {
  border-color: #2563eb;
}

.form-group small {
  color: #64748b;
  font-size: 12px;
}

.full-width {
  grid-column: 1 / -1;
}

.checkbox-row label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}

.checkbox-row input {
  width: auto;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}

.primary-btn,
.secondary-btn,
.success-btn,
.warning-btn,
.danger-btn {
  border: none;
  border-radius: 12px;
  padding: 10px 14px;
  font-weight: 800;
  cursor: pointer;
  transition: 0.2s ease;
}

.primary-btn {
  background: #2563eb;
  color: white;
}

.secondary-btn {
  background: #f1f5f9;
  color: #0f172a;
  border: 1px solid #cbd5e1;
}

.success-btn {
  background: #16a34a;
  color: white;
}

.warning-btn {
  background: #f59e0b;
  color: white;
}

.danger-btn {
  background: #dc2626;
  color: white;
}

.primary-btn:disabled,
.secondary-btn:disabled,
.success-btn:disabled,
.warning-btn:disabled,
.danger-btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.filter-row {
  display: grid;
  grid-template-columns: 1fr 160px auto;
  gap: 10px;
  margin-bottom: 18px;
}

.loading-state,
.empty-state {
  padding: 24px;
  text-align: center;
  color: #64748b;
  background: #f8fafc;
  border-radius: 14px;
  border: 1px dashed #cbd5e1;
}

.dose-list,
.medication-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.dose-card,
.medication-card {
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 16px;
  background: #f8fafc;
}

.dose-main,
.medication-info {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  align-items: flex-start;
}

.dose-main h3,
.medication-info h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 800;
}

.dose-main p,
.medication-info p {
  margin: 6px 0;
  color: #334155;
}

.dose-main small,
.medication-info small {
  color: #64748b;
}

.dose-actions,
.medication-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 14px;
}

.dose-note {
  color: #64748b;
  font-size: 13px;
}

.medication-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  color: #64748b;
  font-size: 13px;
  margin-top: 12px;
}

.notes {
  color: #475569;
  background: #ffffff;
  border-radius: 12px;
  padding: 12px;
  margin: 12px 0 0;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 76px;
  padding: 6px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 900;
  text-transform: capitalize;
}

.status-badge.active,
.status-badge.taken {
  background: #dcfce7;
  color: #166534;
}

.status-badge.pending {
  background: #dbeafe;
  color: #1d4ed8;
}

.status-badge.late {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.missed,
.status-badge.inactive {
  background: #fee2e2;
  color: #991b1b;
}

.status-badge.skipped,
.status-badge.paused {
  background: #f1f5f9;
  color: #475569;
}

.status-badge.completed {
  background: #ede9fe;
  color: #5b21b6;
}

@media (max-width: 1100px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .summary-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .filter-row {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .medication-page {
    padding: 16px;
  }

  .page-header,
  .section-header,
  .dose-main,
  .medication-info {
    flex-direction: column;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .form-actions,
  .dose-actions,
  .medication-actions {
    flex-direction: column;
    align-items: stretch;
  }
}

/* Phase 13F: medication component input readability */
.medication-input-page input,
.medication-input-page textarea,
.medication-input-page select,
.medication-input-page input:disabled,
.medication-input-page textarea:disabled,
.medication-input-page select:disabled,
.medication-input-page input[readonly],
.medication-input-page textarea[readonly],
.medication-input-page select[readonly] {
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  opacity: 1 !important;
}

.medication-input-page input,
.medication-input-page textarea {
  background-color: #ffffff !important;
  caret-color: #2563eb !important;
}

.medication-input-page select {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
}

.medication-input-page input::placeholder,
.medication-input-page textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

.medication-input-page input::selection,
.medication-input-page textarea::selection,
.medication-input-page select::selection {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
  background-color: #2563eb !important;
}

.medication-input-page input::-moz-selection,
.medication-input-page textarea::-moz-selection,
.medication-input-page select::-moz-selection {
  color: #ffffff !important;
  background-color: #2563eb !important;
}

</style>