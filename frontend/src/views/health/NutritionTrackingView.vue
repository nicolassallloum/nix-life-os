<template>
  <div class="nutrition-page">
    <div class="page-header">
      <div>
        <h1>Nutrition Tracking</h1>
        <p>Track daily meals, nutrition values, and CKD nutrient limits.</p>
      </div>

      <div class="date-box">
        <label>Date</label>
        <input type="date" v-model="selectedDate" @change="loadLogs" />
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
        <strong>{{ dailyTotals.calories.toFixed(0) }}</strong>
        <small>kcal</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.protein > ckdLimits.protein }">
        <span>Protein</span>
        <strong>{{ dailyTotals.protein.toFixed(1) }}</strong>
        <small>Limit: {{ ckdLimits.protein }}g</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.sodium > ckdLimits.sodium }">
        <span>Sodium</span>
        <strong>{{ dailyTotals.sodium.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.sodium }}mg</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.potassium > ckdLimits.potassium }">
        <span>Potassium</span>
        <strong>{{ dailyTotals.potassium.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.potassium }}mg</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.phosphorus > ckdLimits.phosphorus }">
        <span>Phosphorus</span>
        <strong>{{ dailyTotals.phosphorus.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.phosphorus }}mg</small>
      </div>
    </div>

    <div v-if="limitWarnings.length" class="warning-box">
      <h3>CKD Nutrient Warnings</h3>
      <ul>
        <li v-for="warning in limitWarnings" :key="warning">
          {{ warning }}
        </li>
      </ul>
    </div>

    <div class="content-grid">
      <section class="form-card">
        <h2>{{ isEditing ? 'Edit Meal' : 'Add Meal' }}</h2>

        <div class="form-group">
          <label>Search Food Database</label>
          <input
            type="text"
            v-model="foodSearch"
            placeholder="Search food, example: rice, chicken, apple"
            @input="handleFoodSearch"
          />

          <div v-if="isSearching" class="small-note">
            Searching foods...
          </div>

          <div v-if="foodResults.length" class="search-results">
            <button
              v-for="food in foodResults"
              :key="food.id"
              type="button"
              @click="selectFood(food)"
            >
              <strong>{{ food.name }}</strong>
              <span>
                {{ food.default_serving_label || food.default_serving_grams + ' g' }} —
                {{ Number(food.calories || 0).toFixed(0) }} kcal —
                CKD: {{ food.ckd_warning_level || 'N/A' }}
              </span>
            </button>
          </div>
        </div>

        <div class="manual-note">
          You can search food from database or manually enter food values.
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Meal Type</label>
            <select v-model="form.meal_type">
              <option value="breakfast">Breakfast</option>
              <option value="lunch">Lunch</option>
              <option value="dinner">Dinner</option>
              <option value="snack">Snack</option>
            </select>
          </div>

          <div class="form-group">
            <label>Food Name</label>
            <input type="text" v-model="form.food_name" placeholder="Food name" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Quantity</label>
            <input
              type="number"
              min="0"
              step="0.1"
              v-model.number="form.quantity"
              @input="recalculateFromServing"
            />
          </div>

          <div class="form-group">
            <label>Unit</label>
            <input type="text" v-model="form.unit" placeholder="g, ml, cup" />
          </div>
        </div>

        <div v-if="selectedFoodBase" class="selected-food-box">
          <strong>Selected Database Food:</strong>
          {{ selectedFoodBase.name }}
          <br />
          <span>
            Base serving:
            {{ selectedFoodBase.default_serving_label || selectedFoodBase.default_serving_grams + ' g' }}
          </span>
          <br />
          <span v-if="selectedFoodBase.ckd_notes">
            CKD Notes: {{ selectedFoodBase.ckd_notes }}
          </span>
        </div>

        <div class="nutrition-input-grid">
          <div class="form-group">
            <label>Calories</label>
            <input type="number" step="0.1" v-model.number="form.calories" />
          </div>

          <div class="form-group">
            <label>Protein g</label>
            <input type="number" step="0.1" v-model.number="form.protein" />
          </div>

          <div class="form-group">
            <label>Carbs g</label>
            <input type="number" step="0.1" v-model.number="form.carbs" />
          </div>

          <div class="form-group">
            <label>Fat g</label>
            <input type="number" step="0.1" v-model.number="form.fat" />
          </div>

          <div class="form-group">
            <label>Sodium mg</label>
            <input type="number" step="0.1" v-model.number="form.sodium" />
          </div>

          <div class="form-group">
            <label>Potassium mg</label>
            <input type="number" step="0.1" v-model.number="form.potassium" />
          </div>

          <div class="form-group">
            <label>Phosphorus mg</label>
            <input type="number" step="0.1" v-model.number="form.phosphorus" />
          </div>
        </div>

        <div class="form-group">
          <label>Notes</label>
          <textarea v-model="form.notes" placeholder="Optional notes"></textarea>
        </div>

        <div class="form-actions">
          <button type="button" class="btn-primary" @click="saveMeal" :disabled="isSaving">
            {{ isSaving ? 'Saving...' : isEditing ? 'Update Meal' : 'Add Meal' }}
          </button>

          <button type="button" class="btn-secondary" @click="resetForm">
            Clear
          </button>
        </div>
      </section>

      <section class="list-card">
        <div class="list-header">
          <h2>Daily Meal Logs</h2>
          <button type="button" @click="loadLogs" class="btn-small">
            Refresh
          </button>
        </div>

        <div v-if="isLoading" class="empty-state">
          Loading nutrition logs...
        </div>

        <div v-else-if="!logs.length" class="empty-state">
          No nutrition logs found for this date.
        </div>

        <div v-else class="meal-list">
          <div v-for="log in logs" :key="log.id" class="meal-card">
            <div class="meal-info">
              <div class="meal-title">
                <strong>{{ log.food_name }}</strong>
                <span>{{ formatMealType(log.meal_type) }}</span>
              </div>

              <div class="meal-meta">
                {{ Number(log.quantity || 0).toFixed(0) }} {{ log.unit || 'g' }} —
                {{ Number(log.calories || 0).toFixed(0) }} kcal
              </div>

              <div class="meal-nutrients">
                <span>Protein: {{ Number(log.protein || 0).toFixed(1) }}g</span>
                <span>Sodium: {{ Number(log.sodium || 0).toFixed(0) }}mg</span>
                <span>Potassium: {{ Number(log.potassium || 0).toFixed(0) }}mg</span>
                <span>Phosphorus: {{ Number(log.phosphorus || 0).toFixed(0) }}mg</span>
              </div>
            </div>

            <div class="meal-actions">
              <button type="button" @click="editMeal(log)">Edit</button>
              <button type="button" class="danger" @click="deleteMeal(log.id)">Delete</button>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script>
import nutritionService from '@/services/nutritionService'

export default {
  name: 'NutritionTrackingView',

  data() {
    return {
      selectedDate: new Date().toISOString().slice(0, 10),

      logs: [],
      foodSearch: '',
      foodResults: [],
      selectedFoodBase: null,

      isLoading: false,
      isSearching: false,
      isSaving: false,
      isEditing: false,

      editingId: null,
      searchTimer: null,

      errorMessage: '',
      successMessage: '',

      ckdLimits: {
        protein: 50,
        sodium: 2000,
        potassium: 2000,
        phosphorus: 800
      },

      form: this.getEmptyForm()
    }
  },

  computed: {
    dailyTotals() {
      return this.logs.reduce(
        (totals, log) => {
          totals.calories += Number(log.calories || 0)
          totals.protein += Number(log.protein || 0)
          totals.carbs += Number(log.carbs || 0)
          totals.fat += Number(log.fat || 0)
          totals.sodium += Number(log.sodium || 0)
          totals.potassium += Number(log.potassium || 0)
          totals.phosphorus += Number(log.phosphorus || 0)

          return totals
        },
        {
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          sodium: 0,
          potassium: 0,
          phosphorus: 0
        }
      )
    },

    limitWarnings() {
      const warnings = []

      if (this.dailyTotals.protein > this.ckdLimits.protein) {
        warnings.push(`Protein limit exceeded: ${this.dailyTotals.protein.toFixed(1)}g / ${this.ckdLimits.protein}g`)
      }

      if (this.dailyTotals.sodium > this.ckdLimits.sodium) {
        warnings.push(`Sodium limit exceeded: ${this.dailyTotals.sodium.toFixed(0)}mg / ${this.ckdLimits.sodium}mg`)
      }

      if (this.dailyTotals.potassium > this.ckdLimits.potassium) {
        warnings.push(`Potassium limit exceeded: ${this.dailyTotals.potassium.toFixed(0)}mg / ${this.ckdLimits.potassium}mg`)
      }

      if (this.dailyTotals.phosphorus > this.ckdLimits.phosphorus) {
        warnings.push(`Phosphorus limit exceeded: ${this.dailyTotals.phosphorus.toFixed(0)}mg / ${this.ckdLimits.phosphorus}mg`)
      }

      return warnings
    }
  },

  mounted() {
    this.form.meal_date = this.selectedDate
    this.loadLogs()
  },

  methods: {
    getEmptyForm() {
      return {
        meal_date: new Date().toISOString().slice(0, 10),
        meal_type: 'breakfast',
        food_name: '',
        quantity: 100,
        unit: 'g',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        sodium: 0,
        potassium: 0,
        phosphorus: 0,
        notes: ''
      }
    },

    async loadLogs() {
      this.isLoading = true
      this.errorMessage = ''
      this.successMessage = ''
      this.form.meal_date = this.selectedDate

      try {
        const response = await nutritionService.getNutritionLogs(this.selectedDate)
        const payload = response.data.data

        this.logs = Array.isArray(payload)
          ? payload
          : payload?.data || []
      } catch (error) {
        this.errorMessage = this.getErrorMessage(error, 'Failed to load nutrition logs.')
      } finally {
        this.isLoading = false
      }
    },

    handleFoodSearch() {
      clearTimeout(this.searchTimer)

      if (!this.foodSearch || this.foodSearch.trim().length < 2) {
        this.foodResults = []
        return
      }

      this.searchTimer = setTimeout(() => {
        this.searchFoods()
      }, 400)
    },

    async searchFoods() {
      this.isSearching = true
      this.errorMessage = ''

      try {
        const response = await nutritionService.searchFoods(this.foodSearch.trim())
        const payload = response.data.data

        this.foodResults = Array.isArray(payload)
          ? payload
          : payload?.data || []
      } catch (error) {
        this.errorMessage = this.getErrorMessage(error, 'Failed to search foods.')
      } finally {
        this.isSearching = false
      }
    },

    selectFood(food) {
      this.selectedFoodBase = { ...food }

      this.form.food_name = food.name
      this.form.quantity = Number(food.default_serving_grams || 100)
      this.form.unit = 'g'

      this.form.calories = Number(food.calories || 0)
      this.form.protein = Number(food.protein_g || 0)
      this.form.carbs = Number(food.carbs_g || 0)
      this.form.fat = Number(food.fat_g || 0)
      this.form.sodium = Number(food.sodium_mg || 0)
      this.form.potassium = Number(food.potassium_mg || 0)
      this.form.phosphorus = Number(food.phosphorus_mg || 0)

      this.foodSearch = food.name
      this.foodResults = []
    },

    recalculateFromServing() {
      if (!this.selectedFoodBase) {
        return
      }

      const baseServing = Number(this.selectedFoodBase.default_serving_grams || 100)
      const currentServing = Number(this.form.quantity || 0)

      if (baseServing <= 0 || currentServing <= 0) {
        return
      }

      const factor = currentServing / baseServing

      this.form.calories = this.roundValue(Number(this.selectedFoodBase.calories || 0) * factor)
      this.form.protein = this.roundValue(Number(this.selectedFoodBase.protein_g || 0) * factor)
      this.form.carbs = this.roundValue(Number(this.selectedFoodBase.carbs_g || 0) * factor)
      this.form.fat = this.roundValue(Number(this.selectedFoodBase.fat_g || 0) * factor)
      this.form.sodium = this.roundValue(Number(this.selectedFoodBase.sodium_mg || 0) * factor)
      this.form.potassium = this.roundValue(Number(this.selectedFoodBase.potassium_mg || 0) * factor)
      this.form.phosphorus = this.roundValue(Number(this.selectedFoodBase.phosphorus_mg || 0) * factor)
    },

    async saveMeal() {
      this.errorMessage = ''
      this.successMessage = ''

      if (!this.form.food_name || !this.form.food_name.trim()) {
        this.errorMessage = 'Food name is required.'
        return
      }

      if (!this.form.quantity || this.form.quantity <= 0) {
        this.errorMessage = 'Quantity must be greater than zero.'
        return
      }

      this.isSaving = true

      const payload = {
        meal_date: this.selectedDate,
        meal_type: this.form.meal_type,
        food_name: this.form.food_name,
        quantity: this.form.quantity,
        unit: this.form.unit,
        calories: this.form.calories || 0,
        protein: this.form.protein || 0,
        sodium: this.form.sodium || 0,
        potassium: this.form.potassium || 0,
        phosphorus: this.form.phosphorus || 0,
        notes: this.form.notes || ''
      }

      try {
        if (this.isEditing && this.editingId) {
          await nutritionService.updateNutritionLog(this.editingId, payload)
          this.successMessage = 'Meal updated successfully.'
        } else {
          await nutritionService.createNutritionLog(payload)
          this.successMessage = 'Meal added successfully.'
        }

        this.resetForm()
        await this.loadLogs()
      } catch (error) {
        this.errorMessage = this.getErrorMessage(error, 'Failed to save meal.')
      } finally {
        this.isSaving = false
      }
    },

    editMeal(log) {
      this.isEditing = true
      this.editingId = log.id
      this.selectedFoodBase = null

      this.form = {
        meal_date: log.meal_date || this.selectedDate,
        meal_type: log.meal_type || 'breakfast',
        food_name: log.food_name || '',
        quantity: Number(log.quantity || 100),
        unit: log.unit || 'g',
        calories: Number(log.calories || 0),
        protein: Number(log.protein || 0),
        carbs: Number(log.carbs || 0),
        fat: Number(log.fat || 0),
        sodium: Number(log.sodium || 0),
        potassium: Number(log.potassium || 0),
        phosphorus: Number(log.phosphorus || 0),
        notes: log.notes || ''
      }

      this.foodSearch = log.food_name || ''
      window.scrollTo({ top: 0, behavior: 'smooth' })
    },

    async deleteMeal(id) {
      const confirmed = window.confirm('Are you sure you want to delete this meal?')

      if (!confirmed) {
        return
      }

      this.errorMessage = ''
      this.successMessage = ''

      try {
        await nutritionService.deleteNutritionLog(id)
        this.successMessage = 'Meal deleted successfully.'
        await this.loadLogs()
      } catch (error) {
        this.errorMessage = this.getErrorMessage(error, 'Failed to delete meal.')
      }
    },

    resetForm() {
      this.isEditing = false
      this.editingId = null
      this.foodSearch = ''
      this.foodResults = []
      this.selectedFoodBase = null

      this.form = this.getEmptyForm()
      this.form.meal_date = this.selectedDate
    },

    roundValue(value) {
      return Math.round(value * 100) / 100
    },

    formatMealType(type) {
      if (!type) return 'Meal'

      return type.charAt(0).toUpperCase() + type.slice(1)
    },

    getErrorMessage(error, fallback) {
      if (error?.response?.data?.message) {
        return error.response.data.message
      }

      if (error?.response?.data?.errors) {
        const errors = error.response.data.errors
        const firstKey = Object.keys(errors)[0]

        if (firstKey && errors[firstKey]?.length) {
          return errors[firstKey][0]
        }
      }

      return fallback
    }
  }
}
</script>

<style scoped>
.nutrition-page {
  padding: 24px;
  background: #f8fafc;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 800;
  color: #0f172a;
  margin: 0;
}

.page-header p {
  color: #64748b;
  margin-top: 6px;
}

.date-box {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 180px;
}

.date-box label,
.form-group label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

input,
select,
textarea {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 14px;
  background: #ffffff;
}

textarea {
  min-height: 80px;
  resize: vertical;
}

.alert {
  padding: 12px 14px;
  border-radius: 12px;
  margin-bottom: 16px;
  font-weight: 600;
}

.alert-error {
  background: #fee2e2;
  color: #991b1b;
}

.alert-success {
  background: #dcfce7;
  color: #166534;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(120px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.summary-card {
  background: #ffffff;
  border-radius: 18px;
  padding: 18px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.04);
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.summary-card strong {
  display: block;
  margin-top: 8px;
  color: #0f172a;
  font-size: 26px;
}

.summary-card small {
  color: #64748b;
}

.summary-card.warning {
  border-color: #f97316;
  background: #fff7ed;
}

.warning-box {
  background: #fff7ed;
  border: 1px solid #fdba74;
  color: #9a3412;
  padding: 16px;
  border-radius: 16px;
  margin-bottom: 20px;
}

.warning-box h3 {
  margin: 0 0 8px;
}

.content-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
  gap: 20px;
}

.form-card,
.list-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 20px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.04);
}

.form-card h2,
.list-card h2 {
  margin: 0 0 18px;
  font-size: 20px;
  color: #0f172a;
}

.form-group {
  margin-bottom: 14px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.nutrition-input-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.search-results {
  margin-top: 8px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
}

.search-results button {
  width: 100%;
  text-align: left;
  border: none;
  background: #ffffff;
  padding: 12px;
  border-bottom: 1px solid #e2e8f0;
  cursor: pointer;
}

.search-results button:hover {
  background: #f1f5f9;
}

.search-results span {
  display: block;
  color: #64748b;
  margin-top: 4px;
}

.small-note,
.manual-note {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 12px;
}

.selected-food-box {
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  color: #1e3a8a;
  padding: 12px;
  border-radius: 14px;
  margin-bottom: 14px;
  font-size: 13px;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 18px;
}

.btn-primary,
.btn-secondary,
.btn-small {
  border: none;
  border-radius: 12px;
  padding: 10px 14px;
  cursor: pointer;
  font-weight: 700;
}

.btn-primary {
  background: #2563eb;
  color: white;
}

.btn-primary:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.btn-secondary {
  background: #e2e8f0;
  color: #0f172a;
}

.btn-small {
  background: #f1f5f9;
  color: #0f172a;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.empty-state {
  padding: 30px;
  text-align: center;
  color: #64748b;
  background: #f8fafc;
  border-radius: 16px;
}

.meal-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.meal-card {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 16px;
}

.meal-title {
  display: flex;
  gap: 10px;
  align-items: center;
}

.meal-title strong {
  color: #0f172a;
}

.meal-title span {
  font-size: 12px;
  font-weight: 700;
  color: #2563eb;
  background: #dbeafe;
  padding: 4px 8px;
  border-radius: 999px;
}

.meal-meta {
  color: #64748b;
  margin-top: 6px;
}

.meal-nutrients {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 10px;
}

.meal-nutrients span {
  background: #f1f5f9;
  color: #334155;
  padding: 5px 8px;
  border-radius: 999px;
  font-size: 12px;
}

.meal-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.meal-actions button {
  border: none;
  border-radius: 10px;
  padding: 8px 12px;
  cursor: pointer;
  font-weight: 700;
  background: #e2e8f0;
}

.meal-actions .danger {
  background: #fee2e2;
  color: #991b1b;
}

@media (max-width: 1100px) {
  .summary-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .page-header,
  .meal-card {
    flex-direction: column;
  }

  .summary-grid,
  .form-row,
  .nutrition-input-grid {
    grid-template-columns: 1fr;
  }
}
</style>
