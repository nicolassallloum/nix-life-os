<template>
  <section class="nutrition-page">
    <div class="page-header">
      <div>
        <h1>Nutrition Tracking</h1>
        <p>Track meals, calories, protein, sodium, potassium, and phosphorus.</p>
      </div>

      <div class="date-filter">
        <label for="selectedDate">Tracking Date</label>
        <input
          id="selectedDate"
          v-model="selectedDate"
          type="date"
          @change="loadNutritionData"
        />
      </div>
    </div>

    <div v-if="errorMessage" class="alert alert-error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <div class="summary-grid">
      <div class="summary-card">
        <span>Calories</span>
        <strong>{{ formatNumber(summary.total_calories) }}</strong>
        <small>Limit: {{ summary.limits.calories }} kcal</small>
        <div :class="statusClass(summary.status.calories)">
          {{ formatStatus(summary.status.calories) }}
        </div>
      </div>

      <div class="summary-card">
        <span>Protein</span>
        <strong>{{ formatNumber(summary.total_protein) }} g</strong>
        <small>Limit: {{ summary.limits.protein }} g</small>
        <div :class="statusClass(summary.status.protein)">
          {{ formatStatus(summary.status.protein) }}
        </div>
      </div>

      <div class="summary-card">
        <span>Sodium</span>
        <strong>{{ formatNumber(summary.total_sodium) }} mg</strong>
        <small>Limit: {{ summary.limits.sodium }} mg</small>
        <div :class="statusClass(summary.status.sodium)">
          {{ formatStatus(summary.status.sodium) }}
        </div>
      </div>

      <div class="summary-card">
        <span>Potassium</span>
        <strong>{{ formatNumber(summary.total_potassium) }} mg</strong>
        <small>Limit: {{ summary.limits.potassium }} mg</small>
        <div :class="statusClass(summary.status.potassium)">
          {{ formatStatus(summary.status.potassium) }}
        </div>
      </div>

      <div class="summary-card">
        <span>Phosphorus</span>
        <strong>{{ formatNumber(summary.total_phosphorus) }} mg</strong>
        <small>Limit: {{ summary.limits.phosphorus }} mg</small>
        <div :class="statusClass(summary.status.phosphorus)">
          {{ formatStatus(summary.status.phosphorus) }}
        </div>
      </div>
    </div>

    <div class="content-grid">
      <div class="panel">
        <div class="panel-header">
          <h2>{{ isEditing ? "Edit Meal" : "Add Meal" }}</h2>
          <button
            v-if="isEditing"
            class="btn btn-secondary"
            type="button"
            @click="resetForm"
          >
            Cancel Edit
          </button>
        </div>

        <form class="meal-form" @submit.prevent="saveMeal">
          <div class="form-row">
            <div class="form-group">
              <label>Meal Date</label>
              <input v-model="form.meal_date" type="date" required />
            </div>

            <div class="form-group">
              <label>Meal Type</label>
              <select v-model="form.meal_type">
                <option value="breakfast">Breakfast</option>
                <option value="lunch">Lunch</option>
                <option value="dinner">Dinner</option>
                <option value="snack">Snack</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label>Food Name</label>
            <input
              v-model.trim="form.food_name"
              type="text"
              placeholder="Example: Boiled Egg"
              required
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Quantity</label>
              <input v-model.number="form.quantity" type="number" min="0" step="0.01" />
            </div>

            <div class="form-group">
              <label>Unit</label>
              <input v-model.trim="form.unit" type="text" placeholder="piece, plate, bowl" />
            </div>
          </div>

          <div class="form-row nutrients">
            <div class="form-group">
              <label>Calories</label>
              <input v-model.number="form.calories" type="number" min="0" step="0.01" />
            </div>

            <div class="form-group">
              <label>Protein</label>
              <input v-model.number="form.protein" type="number" min="0" step="0.01" />
            </div>

            <div class="form-group">
              <label>Sodium</label>
              <input v-model.number="form.sodium" type="number" min="0" step="0.01" />
            </div>

            <div class="form-group">
              <label>Potassium</label>
              <input v-model.number="form.potassium" type="number" min="0" step="0.01" />
            </div>

            <div class="form-group">
              <label>Phosphorus</label>
              <input v-model.number="form.phosphorus" type="number" min="0" step="0.01" />
            </div>
          </div>

          <div class="form-group">
            <label>Notes</label>
            <textarea
              v-model.trim="form.notes"
              rows="3"
              placeholder="Optional notes"
            ></textarea>
          </div>

          <button class="btn btn-primary" type="submit" :disabled="saving">
            {{ saving ? "Saving..." : isEditing ? "Update Meal" : "Add Meal" }}
          </button>
        </form>
      </div>

      <div class="panel">
        <div class="panel-header">
          <h2>Meal History</h2>
          <button class="btn btn-secondary" type="button" @click="loadNutritionData">
            Refresh
          </button>
        </div>

        <div v-if="loading" class="empty-state">
          Loading nutrition logs...
        </div>

        <div v-else-if="mealLogs.length === 0" class="empty-state">
          No meals found for this date. Add your first meal.
        </div>

        <div v-else class="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Meal</th>
                <th>Food</th>
                <th>Qty</th>
                <th>Calories</th>
                <th>Protein</th>
                <th>Sodium</th>
                <th>Potassium</th>
                <th>Phosphorus</th>
                <th>Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-for="meal in mealLogs" :key="meal.id">
                <td>
                  <span class="meal-type">{{ meal.meal_type || "-" }}</span>
                </td>
                <td>
                  <strong>{{ meal.food_name }}</strong>
                  <small v-if="meal.notes">{{ meal.notes }}</small>
                </td>
                <td>{{ formatNumber(meal.quantity) }} {{ meal.unit }}</td>
                <td>{{ formatNumber(meal.calories) }}</td>
                <td>{{ formatNumber(meal.protein) }}</td>
                <td>{{ formatNumber(meal.sodium) }}</td>
                <td>{{ formatNumber(meal.potassium) }}</td>
                <td>{{ formatNumber(meal.phosphorus) }}</td>
                <td class="actions">
                  <button class="btn-small" type="button" @click="editMeal(meal)">
                    Edit
                  </button>
                  <button class="btn-small btn-danger" type="button" @click="deleteMeal(meal.id)">
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  "http://127.0.0.1:8000/api/v1";

const today = new Date().toISOString().slice(0, 10);

const selectedDate = ref(today);
const mealLogs = ref([]);
const loading = ref(false);
const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const editingId = ref(null);

const summary = reactive({
  total_calories: 0,
  total_protein: 0,
  total_sodium: 0,
  total_potassium: 0,
  total_phosphorus: 0,
  limits: {
    calories: 1800,
    protein: 45,
    sodium: 2000,
    potassium: 2000,
    phosphorus: 800,
  },
  status: {
    calories: "within_limit",
    protein: "within_limit",
    sodium: "within_limit",
    potassium: "within_limit",
    phosphorus: "within_limit",
  },
});

const form = reactive({
  meal_date: today,
  meal_type: "breakfast",
  food_name: "",
  quantity: 1,
  unit: "piece",
  calories: 0,
  protein: 0,
  sodium: 0,
  potassium: 0,
  phosphorus: 0,
  notes: "",
});

const isEditing = computed(() => Boolean(editingId.value));

function getToken() {
  return (
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token") ||
    sessionStorage.getItem("token") ||
    sessionStorage.getItem("auth_token") ||
    sessionStorage.getItem("access_token") ||
    ""
  );
}

function authHeaders() {
  const token = getToken();

  return {
    Accept: "application/json",
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

async function handleResponse(response) {
  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const message =
      data.message ||
      Object.values(data.errors || {})
        .flat()
        .join(" ") ||
      "Request failed.";
    throw new Error(message);
  }

  return data;
}

function clearMessages() {
  errorMessage.value = "";
  successMessage.value = "";
}

function setSummary(data = {}) {
  summary.total_calories = Number(data.total_calories || 0);
  summary.total_protein = Number(data.total_protein || 0);
  summary.total_sodium = Number(data.total_sodium || 0);
  summary.total_potassium = Number(data.total_potassium || 0);
  summary.total_phosphorus = Number(data.total_phosphorus || 0);

  summary.limits = {
    calories: Number(data.limits?.calories || 1800),
    protein: Number(data.limits?.protein || 45),
    sodium: Number(data.limits?.sodium || 2000),
    potassium: Number(data.limits?.potassium || 2000),
    phosphorus: Number(data.limits?.phosphorus || 800),
  };

  summary.status = {
    calories: data.status?.calories || "within_limit",
    protein: data.status?.protein || "within_limit",
    sodium: data.status?.sodium || "within_limit",
    potassium: data.status?.potassium || "within_limit",
    phosphorus: data.status?.phosphorus || "within_limit",
  };
}

async function loadNutritionData() {
  loading.value = true;
  clearMessages();

  try {
    form.meal_date = selectedDate.value;

    const [logsResponse, summaryResponse] = await Promise.all([
      fetch(`${API_BASE_URL}/health/nutrition?date=${selectedDate.value}`, {
        headers: authHeaders(),
      }),
      fetch(`${API_BASE_URL}/health/nutrition/summary?date=${selectedDate.value}`, {
        headers: authHeaders(),
      }),
    ]);

    const logsJson = await handleResponse(logsResponse);
    const summaryJson = await handleResponse(summaryResponse);

    mealLogs.value = Array.isArray(logsJson.data) ? logsJson.data : [];
    setSummary(summaryJson.data || {});
  } catch (error) {
    errorMessage.value = error.message || "Failed to load nutrition data.";
  } finally {
    loading.value = false;
  }
}

function buildPayload() {
  return {
    meal_date: form.meal_date,
    meal_type: form.meal_type,
    food_name: form.food_name,
    quantity: Number(form.quantity || 0),
    unit: form.unit,
    calories: Number(form.calories || 0),
    protein: Number(form.protein || 0),
    sodium: Number(form.sodium || 0),
    potassium: Number(form.potassium || 0),
    phosphorus: Number(form.phosphorus || 0),
    notes: form.notes,
  };
}

async function saveMeal() {
  saving.value = true;
  clearMessages();

  try {
    const url = isEditing.value
      ? `${API_BASE_URL}/health/nutrition/${editingId.value}`
      : `${API_BASE_URL}/health/nutrition`;

    const method = isEditing.value ? "PUT" : "POST";

    const response = await fetch(url, {
      method,
      headers: authHeaders(),
      body: JSON.stringify(buildPayload()),
    });

    await handleResponse(response);

    successMessage.value = isEditing.value
      ? "Meal updated successfully."
      : "Meal added successfully.";

    resetForm(false);
    await loadNutritionData();
  } catch (error) {
    errorMessage.value = error.message || "Failed to save meal.";
  } finally {
    saving.value = false;
  }
}

function editMeal(meal) {
  editingId.value = meal.id;

  form.meal_date = meal.meal_date || selectedDate.value;
  form.meal_type = meal.meal_type || "breakfast";
  form.food_name = meal.food_name || "";
  form.quantity = Number(meal.quantity || 1);
  form.unit = meal.unit || "";
  form.calories = Number(meal.calories || 0);
  form.protein = Number(meal.protein || 0);
  form.sodium = Number(meal.sodium || 0);
  form.potassium = Number(meal.potassium || 0);
  form.phosphorus = Number(meal.phosphorus || 0);
  form.notes = meal.notes || "";

  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function deleteMeal(id) {
  const confirmed = window.confirm("Delete this meal log?");
  if (!confirmed) return;

  clearMessages();

  try {
    const response = await fetch(`${API_BASE_URL}/health/nutrition/${id}`, {
      method: "DELETE",
      headers: authHeaders(),
    });

    await handleResponse(response);

    successMessage.value = "Meal deleted successfully.";
    await loadNutritionData();
  } catch (error) {
    errorMessage.value = error.message || "Failed to delete meal.";
  }
}

function resetForm(clearMessage = true) {
  if (clearMessage) {
    clearMessages();
  }

  editingId.value = null;

  form.meal_date = selectedDate.value;
  form.meal_type = "breakfast";
  form.food_name = "";
  form.quantity = 1;
  form.unit = "piece";
  form.calories = 0;
  form.protein = 0;
  form.sodium = 0;
  form.potassium = 0;
  form.phosphorus = 0;
  form.notes = "";
}

function formatNumber(value) {
  const number = Number(value || 0);
  return Number.isInteger(number) ? number.toString() : number.toFixed(2);
}

function formatStatus(status) {
  if (!status) return "Within limit";
  return status.replaceAll("_", " ");
}

function statusClass(status) {
  return status === "over_limit" ? "limit-status over" : "limit-status ok";
}

onMounted(() => {
  loadNutritionData();
});
</script>

<style scoped>
.nutrition-page {
  padding: 32px;
  color: #111827;
  background: #f8fafc;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 800;
  margin: 0;
}

.page-header p {
  color: #64748b;
  margin-top: 6px;
}

.date-filter {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 190px;
}

.date-filter label,
.form-group label {
  font-size: 13px;
  font-weight: 700;
  color: #475569;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #dbe3ef;
  border-radius: 12px;
  padding: 10px 12px;
  font-size: 14px;
  outline: none;
  background: #fff;
}

input:focus,
select:focus,
textarea:focus {
  border-color: #111827;
}

.alert {
  padding: 12px 14px;
  border-radius: 14px;
  margin-bottom: 16px;
  font-weight: 700;
}

.alert-error {
  background: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.alert-success {
  background: #ecfdf5;
  color: #065f46;
  border: 1px solid #bbf7d0;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(150px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  padding: 18px;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.05);
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
  margin-bottom: 8px;
}

.summary-card strong {
  display: block;
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 6px;
}

.summary-card small {
  color: #64748b;
}

.limit-status {
  margin-top: 10px;
  display: inline-block;
  padding: 5px 9px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
  text-transform: capitalize;
}

.limit-status.ok {
  background: #dcfce7;
  color: #166534;
}

.limit-status.over {
  background: #fee2e2;
  color: #991b1b;
}

.content-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
  gap: 20px;
  align-items: flex-start;
}

.panel {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 12px 30px rgba(15, 23, 42, 0.06);
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.panel-header h2 {
  margin: 0;
  font-size: 18px;
  font-weight: 800;
}

.meal-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-row.nutrients {
  grid-template-columns: repeat(2, 1fr);
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.btn,
.btn-small {
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 800;
}

.btn {
  padding: 11px 16px;
}

.btn-small {
  padding: 7px 10px;
  font-size: 12px;
}

.btn-primary {
  background: #020617;
  color: #fff;
}

.btn-secondary {
  background: #f1f5f9;
  color: #0f172a;
}

.btn-danger {
  background: #fee2e2;
  color: #991b1b;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.table-wrapper {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

th {
  text-align: left;
  color: #64748b;
  font-size: 12px;
  text-transform: uppercase;
  border-bottom: 1px solid #e5e7eb;
  padding: 10px;
}

td {
  border-bottom: 1px solid #f1f5f9;
  padding: 12px 10px;
  vertical-align: top;
}

td strong {
  display: block;
  color: #111827;
}

td small {
  display: block;
  color: #64748b;
  margin-top: 4px;
}

.meal-type {
  display: inline-block;
  padding: 5px 8px;
  border-radius: 999px;
  background: #eef2ff;
  color: #3730a3;
  font-weight: 800;
  text-transform: capitalize;
  font-size: 12px;
}

.actions {
  display: flex;
  gap: 8px;
  white-space: nowrap;
}

.empty-state {
  border: 1px dashed #cbd5e1;
  border-radius: 16px;
  padding: 28px;
  text-align: center;
  color: #64748b;
  background: #f8fafc;
}

@media (max-width: 1200px) {
  .summary-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 700px) {
  .nutrition-page {
    padding: 20px;
  }

  .page-header {
    flex-direction: column;
  }

  .summary-grid,
  .form-row,
  .form-row.nutrients {
    grid-template-columns: 1fr;
  }
}
</style>
