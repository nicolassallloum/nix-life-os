<template>
  <div class="lab-page">
    <div class="page-header">
      <div>
        <h1>Lab Test Results</h1>
        <p>Track kidney-related lab results including creatinine, urea, eGFR, potassium, phosphorus, and hemoglobin.</p>
      </div>

      <button class="primary-btn" @click="resetForm">
        + Add Lab Test
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
        <span>Creatinine</span>
        <strong>{{ latestValue("creatinine") }}</strong>
        <small>mg/dL</small>
      </div>

      <div class="summary-card">
        <span>eGFR</span>
        <strong>{{ latestValue("egfr") }}</strong>
        <small>mL/min</small>
      </div>

      <div class="summary-card">
        <span>Urea</span>
        <strong>{{ latestValue("urea") }}</strong>
        <small>mg/dL</small>
      </div>

      <div class="summary-card">
        <span>Potassium</span>
        <strong>{{ latestValue("potassium") }}</strong>
        <small>mmol/L</small>
      </div>

      <div class="summary-card">
        <span>Phosphorus</span>
        <strong>{{ latestValue("phosphorus") }}</strong>
        <small>mg/dL</small>
      </div>

      <div class="summary-card">
        <span>Hemoglobin</span>
        <strong>{{ latestValue("hemoglobin") }}</strong>
        <small>g/dL</small>
      </div>
    </div>

    <div v-if="warnings.length" class="warning-card">
      <h2>CKD Warning Notes</h2>

      <ul>
        <li v-for="warning in warnings" :key="warning">
          {{ warning }}
        </li>
      </ul>

      <p>
        These warnings are informational only and do not replace medical advice.
      </p>
    </div>

    <div class="content-grid">
      <form class="card form-card" @submit.prevent="saveLabTest">
        <div class="card-header">
          <h2>{{ editingId ? "Edit Lab Test" : "Add Lab Test Result" }}</h2>
          <p>Enter your lab result values manually.</p>
        </div>

        <div class="form-grid">
          <div class="form-group">
            <label>Test Date *</label>
            <input v-model="form.test_date" type="date" required />
          </div>

          <div class="form-group">
            <label>Lab Name</label>
            <input v-model="form.lab_name" type="text" placeholder="Example: Local Lab" />
          </div>

          <div class="form-group full-width">
            <label>Test Name</label>
            <input
              v-model="form.test_name"
              type="text"
              placeholder="Example: CKD Blood Test Panel"
            />
          </div>

          <div class="form-group">
            <label>Creatinine</label>
            <input v-model="form.creatinine" type="number" step="0.01" min="0" placeholder="2.70" />
          </div>

          <div class="form-group">
            <label>Urea</label>
            <input v-model="form.urea" type="number" step="0.01" min="0" placeholder="92" />
          </div>

          <div class="form-group">
            <label>eGFR</label>
            <input v-model="form.egfr" type="number" step="0.01" min="0" placeholder="27" />
          </div>

          <div class="form-group">
            <label>Hemoglobin</label>
            <input v-model="form.hemoglobin" type="number" step="0.01" min="0" placeholder="11.2" />
          </div>

          <div class="form-group">
            <label>Sodium</label>
            <input v-model="form.sodium" type="number" step="0.01" min="0" placeholder="139" />
          </div>

          <div class="form-group">
            <label>Potassium</label>
            <input v-model="form.potassium" type="number" step="0.01" min="0" placeholder="5.3" />
          </div>

          <div class="form-group">
            <label>Phosphorus</label>
            <input v-model="form.phosphorus" type="number" step="0.01" min="0" placeholder="5.1" />
          </div>

          <div class="form-group full-width">
            <label>Notes</label>
            <textarea
              v-model="form.notes"
              rows="4"
              placeholder="Example: Manual entry from lab report."
            ></textarea>
          </div>
        </div>

        <div class="form-actions">
          <button class="primary-btn" type="submit" :disabled="loading">
            {{ loading ? "Saving..." : editingId ? "Update Lab Test" : "Save Lab Test" }}
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
            <h2>Lab Test History</h2>
            <p>Review previous kidney-related lab results.</p>
          </div>

          <button class="secondary-btn" @click="loadLabTests">
            Refresh
          </button>
        </div>

        <div v-if="loadingList" class="empty-state">
          Loading lab tests...
        </div>

        <div v-else-if="labTests.length === 0" class="empty-state">
          No lab tests found. Add your first lab test result from the form.
        </div>

        <div v-else class="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Lab</th>
                <th>Creatinine</th>
                <th>Urea</th>
                <th>eGFR</th>
                <th>K</th>
                <th>Phos</th>
                <th>Hb</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-for="item in labTests" :key="item.id">
                <td>
                  <strong>{{ formatDate(item.test_date) }}</strong>
                  <small>{{ item.test_name || "CKD Blood Test Panel" }}</small>
                </td>

                <td>{{ item.lab_name || "-" }}</td>
                <td :class="valueClass('creatinine', item.creatinine)">{{ displayValue(item.creatinine) }}</td>
                <td :class="valueClass('urea', item.urea)">{{ displayValue(item.urea) }}</td>
                <td :class="valueClass('egfr', item.egfr)">{{ displayValue(item.egfr) }}</td>
                <td :class="valueClass('potassium', item.potassium)">{{ displayValue(item.potassium) }}</td>
                <td :class="valueClass('phosphorus', item.phosphorus)">{{ displayValue(item.phosphorus) }}</td>
                <td :class="valueClass('hemoglobin', item.hemoglobin)">{{ displayValue(item.hemoglobin) }}</td>

                <td class="actions">
                  <button class="small-btn" @click="editLabTest(item)">
                    Edit
                  </button>

                  <button class="danger-btn" @click="deleteLabTest(item.id)">
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="trend-box">
          <h3>Trend Data Status</h3>
          <p>
            Records loaded for chart-ready trend endpoint:
            <strong>{{ trendRecordsCount }}</strong>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import healthService from "@/services/healthService";

const labTests = ref([]);
const trendData = ref([]);
const warnings = ref([]);
const loading = ref(false);
const loadingList = ref(false);
const editingId = ref(null);
const errorMessage = ref("");
const successMessage = ref("");

const form = reactive({
  test_date: new Date().toISOString().slice(0, 10),
  test_name: "CKD Blood Test Panel",
  lab_name: "",
  creatinine: "",
  urea: "",
  egfr: "",
  hemoglobin: "",
  sodium: "",
  potassium: "",
  phosphorus: "",
  notes: "",
});

const latestLab = computed(() => {
  return labTests.value.length ? labTests.value[0] : null;
});

const trendRecordsCount = computed(() => trendData.value.length);

onMounted(async () => {
  await loadLabTests();
  await loadTrends();
});

async function loadLabTests() {
  loadingList.value = true;
  clearMessages();

  try {
    const response = await healthService.labTests.list();
    labTests.value = response.data?.data || [];
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to load lab tests.");
  } finally {
    loadingList.value = false;
  }
}

async function loadTrends() {
  try {
    const response = await healthService.labTests.trends({ days: 365 });
    trendData.value = response.data?.data?.chart || [];
    warnings.value = response.data?.data?.warnings || [];
  } catch (error) {
    console.error("Failed to load lab trends:", error);
  }
}

async function saveLabTest() {
  loading.value = true;
  clearMessages();

  try {
    const payload = buildPayload();

    if (editingId.value) {
      const response = await healthService.labTests.update(editingId.value, payload);
      warnings.value = response.data?.warnings || [];
      successMessage.value = "Lab test updated successfully.";
    } else {
      const response = await healthService.labTests.create(payload);
      warnings.value = response.data?.warnings || [];
      successMessage.value = "Lab test created successfully.";
    }

    resetForm();
    await loadLabTests();
    await loadTrends();
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to save lab test.");
  } finally {
    loading.value = false;
  }
}

async function deleteLabTest(id) {
  const confirmed = window.confirm("Are you sure you want to delete this lab test?");

  if (!confirmed) {
    return;
  }

  clearMessages();

  try {
    await healthService.labTests.delete(id);
    successMessage.value = "Lab test deleted successfully.";
    await loadLabTests();
    await loadTrends();
  } catch (error) {
    errorMessage.value = getErrorMessage(error, "Failed to delete lab test.");
  }
}

function editLabTest(item) {
  editingId.value = item.id;

  form.test_date = item.test_date || new Date().toISOString().slice(0, 10);
  form.test_name = item.test_name || "CKD Blood Test Panel";
  form.lab_name = item.lab_name || "";
  form.creatinine = item.creatinine || "";
  form.urea = item.urea || "";
  form.egfr = item.egfr || "";
  form.hemoglobin = item.hemoglobin || "";
  form.sodium = item.sodium || "";
  form.potassium = item.potassium || "";
  form.phosphorus = item.phosphorus || "";
  form.notes = item.notes || "";

  window.scrollTo({ top: 0, behavior: "smooth" });
}

function resetForm() {
  editingId.value = null;

  form.test_date = new Date().toISOString().slice(0, 10);
  form.test_name = "CKD Blood Test Panel";
  form.lab_name = "";
  form.creatinine = "";
  form.urea = "";
  form.egfr = "";
  form.hemoglobin = "";
  form.sodium = "";
  form.potassium = "";
  form.phosphorus = "";
  form.notes = "";
}

function buildPayload() {
  return {
    test_date: form.test_date,
    test_name: form.test_name || "CKD Blood Test Panel",
    lab_name: form.lab_name || null,
    creatinine: numberOrNull(form.creatinine),
    urea: numberOrNull(form.urea),
    egfr: numberOrNull(form.egfr),
    hemoglobin: numberOrNull(form.hemoglobin),
    sodium: numberOrNull(form.sodium),
    potassium: numberOrNull(form.potassium),
    phosphorus: numberOrNull(form.phosphorus),
    source_type: "manual",
    notes: form.notes || null,
  };
}

function latestValue(field) {
  if (!latestLab.value || latestLab.value[field] === null || latestLab.value[field] === undefined) {
    return "-";
  }

  return Number(latestLab.value[field]).toFixed(2);
}

function displayValue(value) {
  if (value === null || value === undefined || value === "") {
    return "-";
  }

  return Number(value).toFixed(2);
}

function numberOrNull(value) {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  return Number(value);
}

function valueClass(field, value) {
  const numericValue = Number(value);

  if (Number.isNaN(numericValue)) {
    return "";
  }

  if (field === "creatinine" && numericValue > 1.3) {
    return "value-warning";
  }

  if (field === "urea" && numericValue > 50) {
    return "value-warning";
  }

  if (field === "egfr" && numericValue < 30) {
    return "value-danger";
  }

  if (field === "egfr" && numericValue < 60) {
    return "value-warning";
  }

  if (field === "potassium" && numericValue > 5) {
    return "value-danger";
  }

  if (field === "phosphorus" && numericValue > 4.5) {
    return "value-warning";
  }

  if (field === "hemoglobin" && numericValue < 13) {
    return "value-warning";
  }

  return "";
}

function formatDate(value) {
  if (!value) {
    return "-";
  }

  return String(value).slice(0, 10);
}

function clearMessages() {
  errorMessage.value = "";
  successMessage.value = "";
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
.lab-page {
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
  max-width: 780px;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
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
  font-size: 24px;
}

.summary-card small {
  display: block;
  color: #94a3b8;
  margin-top: 4px;
}

.warning-card {
  background: #fff7ed;
  border: 1px solid #fed7aa;
  border-left: 5px solid #f97316;
  border-radius: 16px;
  padding: 18px 20px;
  margin-bottom: 20px;
}

.warning-card h2 {
  color: #9a3412;
  font-size: 18px;
  font-weight: 800;
  margin-bottom: 10px;
}

.warning-card ul {
  margin: 0;
  padding-left: 20px;
  color: #7c2d12;
}

.warning-card li {
  margin-bottom: 6px;
}

.warning-card p {
  color: #9a3412;
  font-size: 13px;
  margin-top: 12px;
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
  grid-template-columns: repeat(2, minmax(0, 1fr));
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

.form-group input,
.form-group textarea {
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
.form-group textarea:focus {
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
  white-space: nowrap;
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

.value-warning {
  color: #b45309;
  font-weight: 800;
}

.value-danger {
  color: #b91c1c;
  font-weight: 800;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  color: #64748b;
  border-radius: 16px;
}

.trend-box {
  margin-top: 16px;
  background: #f8fafc;
  border-left: 4px solid #2563eb;
  padding: 12px 14px;
  color: #475569;
  border-radius: 10px;
}

.trend-box h3 {
  color: #0f172a;
  font-size: 15px;
  font-weight: 800;
  margin-bottom: 4px;
}

@media (max-width: 1250px) {
  .summary-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 750px) {
  .page-header,
  .list-header {
    flex-direction: column;
  }

  .summary-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .lab-page {
    padding: 16px;
  }
}
</style>