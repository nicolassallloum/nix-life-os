<template>
  <div class="medication-page">
    <div class="page-header">
      <div>
        <h1>Medication Tracking</h1>
        <p>Track medicaments, times, daily dose, status, prescribed doctor, and notes.</p>
      </div>

      <button class="primary-btn" @click="resetForm">
        + Add Medication
      </button>
    </div>

    <div v-if="errorMessage" class="alert alert-error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <div class="summary-grid">
      <div class="summary-card">
        <span>Total Medications</span>
        <strong>{{ medications.length }}</strong>
      </div>

      <div class="summary-card">
        <span>Active</span>
        <strong>{{ activeCount }}</strong>
      </div>

      <div class="summary-card">
        <span>Paused</span>
        <strong>{{ pausedCount }}</strong>
      </div>

      <div class="summary-card">
        <span>Completed / Inactive</span>
        <strong>{{ completedCount }}</strong>
      </div>
    </div>

    <div class="content-grid">
      <form class="card form-card" @submit.prevent="saveMedication">
        <div class="card-header">
          <h2>{{ editingId ? "Edit Medication" : "Add Medication" }}</h2>
          <p>Enter medication name, dosage, daily dose, and dose times.</p>
        </div>

        <div class="form-grid">
          <div class="form-group">
            <label>Medication Name *</label>
            <input
              v-model="form.medication_name"
              type="text"
              placeholder="Example: Amlodipine"
              required
            />
          </div>

          <div class="form-group">
            <label>Dosage *</label>
            <input
              v-model="form.dosage"
              type="text"
              placeholder="Example: 5 mg"
              required
            />
          </div>

          <div class="form-group">
            <label>Daily Dose</label>
            <input
              v-model="form.daily_dose"
              type="text"
              placeholder="Example: 1 tablet daily"
            />
          </div>

          <div class="form-group">
            <label>Dose Times</label>
            <input
              v-model="doseTimesText"
              type="text"
              placeholder="Example: 08:00, 20:00"
            />
            <small>Separate multiple times with comma.</small>
          </div>

          <div class="form-group">
            <label>Frequency *</label>
            <input
              v-model="form.frequency"
              type="text"
              placeholder="Example: Once daily"
              required
            />
          </div>

          <div class="form-group">
            <label>Status *</label>
            <select v-model="form.status" required>
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

          <div class="form-group full-width">
            <label>Prescribed By</label>
            <input
              v-model="form.prescribed_by"
              type="text"
              placeholder="Doctor name"
            />
          </div>

          <div class="form-group full-width">
            <label>Notes</label>
            <textarea
              v-model="form.notes"
              rows="4"
              placeholder="Example: Take after breakfast."
            ></textarea>
          </div>
        </div>

        <div class="form-actions">
          <button class="primary-btn" type="submit" :disabled="loading">
            {{ loading ? "Saving..." : editingId ? "Update Medication" : "Save Medication" }}
          </button>

          <button
            v-if="editingId"
            class="secondary-btn"
            type="button"
            @click="resetForm"
          >
            Cancel Edit
          </button>
        </div>
      </form>

      <div class="card list-card">
        <div class="card-header list-header">
          <div>
            <h2>Medication List</h2>
            <p>View, edit, or delete your medications.</p>
          </div>

          <select v-model="statusFilter" @change="loadMedications">
            <option value="">All Statuses</option>
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="completed">Completed</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div v-if="loadingList" class="empty-state">
          Loading medications...
        </div>

        <div v-else-if="medications.length === 0" class="empty-state">
          No medications found. Add your first medication from the form.
        </div>

        <div v-else class="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Medication</th>
                <th>Dosage</th>
                <th>Daily Dose</th>
                <th>Times</th>
                <th>Status</th>
                <th>Start</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-for="item in medications" :key="item.id">
                <td>
                  <strong>{{ item.medication_name }}</strong>
                  <small v-if="item.prescribed_by">By {{ item.prescribed_by }}</small>
                </td>

                <td>{{ item.dosage }}</td>
                <td>{{ item.daily_dose || "-" }}</td>

                <td>
                  <span v-if="Array.isArray(item.dose_times) && item.dose_times.length">
                    {{ item.dose_times.join(", ") }}
                  </span>
                  <span v-else>-</span>
                </td>

                <td>
                  <span class="status-badge" :class="`status-${item.status}`">
                    {{ item.status }}
                  </span>
                </td>

                <td>{{ formatDate(item.start_date) }}</td>

                <td class="actions">
                  <button class="small-btn" @click="editMedication(item)">
                    Edit
                  </button>

                  <button class="danger-btn" @click="deleteMedication(item.id)">
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="info-note">
          Medication tracking is for personal organization only. Always follow your doctor’s prescription.
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import healthService from "@/services/healthService";

const medications = ref([]);
const loading = ref(false);
const loadingList = ref(false);
const editingId = ref(null);
const statusFilter = ref("");
const doseTimesText = ref("");
const errorMessage = ref("");
const successMessage = ref("");

const form = reactive({
  medication_name: "",
  dosage: "",
  daily_dose: "",
  dose_times: [],
  frequency: "",
  start_date: new Date().toISOString().slice(0, 10),
  end_date: "",
  status: "active",
  prescribed_by: "",
  notes: "",
});

const activeCount = computed(() =>
  medications.value.filter((item) => item.status === "active").length
);

const pausedCount = computed(() =>
  medications.value.filter((item) => item.status === "paused").length
);

const completedCount = computed(() =>
  medications.value.filter((item) =>
    ["completed", "inactive"].includes(item.status)
  ).length
);

onMounted(() => {
  loadMedications();
});

async function loadMedications() {
  loadingList.value = true;
  clearMessages();

  try {
    const params = {};

    if (statusFilter.value) {
      params.status = statusFilter.value;
    }

    const response = await healthService.medications.list(params);
    medications.value = response.data?.data || [];
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to load medications.");
  } finally {
    loadingList.value = false;
  }
}

async function saveMedication() {
  loading.value = true;
  clearMessages();

  try {
    const payload = buildPayload();

    if (editingId.value) {
      await healthService.medications.update(editingId.value, payload);
      successMessage.value = "Medication updated successfully.";
    } else {
      await healthService.medications.create(payload);
      successMessage.value = "Medication created successfully.";
    }

    resetForm();
    await loadMedications();
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to save medication.");
  } finally {
    loading.value = false;
  }
}

async function deleteMedication(id) {
  const confirmed = window.confirm("Are you sure you want to delete this medication?");

  if (!confirmed) {
    return;
  }

  clearMessages();

  try {
    await healthService.medications.delete(id);
    successMessage.value = "Medication deleted successfully.";
    await loadMedications();
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to delete medication.");
  }
}

function editMedication(item) {
  editingId.value = item.id;

  form.medication_name = item.medication_name || "";
  form.dosage = item.dosage || "";
  form.daily_dose = item.daily_dose || "";
  form.dose_times = Array.isArray(item.dose_times) ? item.dose_times : [];
  form.frequency = item.frequency || "";
  form.start_date = item.start_date || new Date().toISOString().slice(0, 10);
  form.end_date = item.end_date || "";
  form.status = item.status || "active";
  form.prescribed_by = item.prescribed_by || "";
  form.notes = item.notes || "";

  doseTimesText.value = form.dose_times.join(", ");
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function resetForm() {
  editingId.value = null;

  form.medication_name = "";
  form.dosage = "";
  form.daily_dose = "";
  form.dose_times = [];
  form.frequency = "";
  form.start_date = new Date().toISOString().slice(0, 10);
  form.end_date = "";
  form.status = "active";
  form.prescribed_by = "";
  form.notes = "";

  doseTimesText.value = "";
}

function buildPayload() {
  const doseTimes = doseTimesText.value
    .split(",")
    .map((time) => time.trim())
    .filter(Boolean);

  return {
    medication_name: form.medication_name,
    dosage: form.dosage,
    daily_dose: form.daily_dose || null,
    dose_times: doseTimes,
    frequency: form.frequency,
    start_date: form.start_date,
    end_date: form.end_date || null,
    status: form.status,
    prescribed_by: form.prescribed_by || null,
    notes: form.notes || null,
  };
}

function clearMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function formatDate(value) {
  if (!value) {
    return "-";
  }

  return String(value).slice(0, 10);
}

function getErrorMessage(error, fallback) {
  return (
    error?.response?.data?.message ||
    Object.values(error?.response?.data?.errors || {})?.flat()?.[0] ||
    fallback
  );
}
</script>

<style scoped>
.medication-page {
  padding: 24px;
  background: #f8fafc;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 30px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 8px;
}

.page-header p {
  color: #64748b;
  font-size: 15px;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.summary-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 18px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.05);
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 13px;
  margin-bottom: 8px;
}

.summary-card strong {
  color: #0f172a;
  font-size: 26px;
}

.content-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
  gap: 20px;
  align-items: flex-start;
}

.card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 22px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
}

.card-header {
  margin-bottom: 18px;
}

.card-header h2 {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 6px;
}

.card-header p {
  color: #64748b;
  font-size: 14px;
}

.list-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
}

.form-grid {
  display: grid;
  gap: 14px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.form-group label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

.form-group small {
  color: #94a3b8;
  font-size: 12px;
}

.form-group input,
.form-group select,
.form-group textarea,
.list-header select {
  width: 100%;
  border: 1px solid #d1d5db;
  border-radius: 12px;
  padding: 11px 12px;
  font-size: 14px;
  color: #111827;
  outline: none;
  background: #ffffff;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus,
.list-header select:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
}

.full-width {
  grid-column: 1 / -1;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 18px;
}

.primary-btn,
.secondary-btn,
.small-btn,
.danger-btn {
  border: none;
  border-radius: 12px;
  padding: 11px 16px;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s ease;
}

.primary-btn {
  background: #2563eb;
  color: #ffffff;
}

.primary-btn:hover {
  background: #1d4ed8;
}

.primary-btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.secondary-btn {
  background: #e2e8f0;
  color: #0f172a;
}

.small-btn {
  background: #eff6ff;
  color: #1d4ed8;
  padding: 8px 10px;
}

.danger-btn {
  background: #fee2e2;
  color: #b91c1c;
  padding: 8px 10px;
}

.alert {
  border-radius: 14px;
  padding: 14px 16px;
  margin-bottom: 16px;
  font-weight: 700;
}

.alert-error {
  background: #fef2f2;
  color: #b91c1c;
  border: 1px solid #fecaca;
}

.alert-success {
  background: #ecfdf5;
  color: #047857;
  border: 1px solid #bbf7d0;
}

.table-wrapper {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th {
  background: #f8fafc;
  color: #475569;
  font-size: 12px;
  text-transform: uppercase;
  text-align: left;
  padding: 12px;
  border-bottom: 1px solid #e5e7eb;
}

td {
  padding: 14px 12px;
  border-bottom: 1px solid #eef2f7;
  color: #334155;
  vertical-align: top;
}

td strong {
  display: block;
  color: #0f172a;
  margin-bottom: 4px;
}

td small {
  color: #64748b;
}

.actions-col {
  width: 150px;
}

.actions {
  display: flex;
  gap: 8px;
}

.status-badge {
  display: inline-flex;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
  text-transform: capitalize;
}

.status-active {
  background: #dcfce7;
  color: #15803d;
}

.status-paused {
  background: #fef9c3;
  color: #a16207;
}

.status-completed {
  background: #e0f2fe;
  color: #0369a1;
}

.status-inactive {
  background: #f1f5f9;
  color: #475569;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  color: #64748b;
  border-radius: 16px;
}

.info-note {
  margin-top: 16px;
  background: #f8fafc;
  border-left: 4px solid #2563eb;
  padding: 12px 14px;
  color: #475569;
  font-size: 13px;
  border-radius: 10px;
}

@media (max-width: 1100px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 700px) {
  .page-header,
  .list-header {
    flex-direction: column;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .medication-page {
    padding: 16px;
  }
}
</style>