🔹 STEP 47 — Nutrition Screen Full Integration
Nutrition Facts Database + Nutrition Tracking Screen

You are now connecting the Nutrition Facts Database to the Nutrition Tracking screen so the user can search foods, autofill values, calculate serving nutrition, and save meals.

1. Goal of This Step

The Nutrition Tracking screen must support:

Search food from database
Autofill nutrition values
Manual food entry
Serving size calculation
Daily totals update automatically
CKD nutrient limit warnings
Add meal
Edit meal
Delete meal
Empty and error states
2. Expected Backend API Endpoints

Your frontend should use these endpoints:

GET    /api/v1/nutrition/foods/search?query=rice
GET    /api/v1/nutrition/foods/{id}
GET    /api/v1/health/nutrition-logs?date=2026-05-10
POST   /api/v1/health/nutrition-logs
PUT    /api/v1/health/nutrition-logs/{id}
DELETE /api/v1/health/nutrition-logs/{id}

Recommended route structure:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    Route::prefix('nutrition')->group(function () {
        Route::get('/foods/search', [NutritionFoodController::class, 'search']);
        Route::get('/foods/{id}', [NutritionFoodController::class, 'show']);
    });

    Route::prefix('health')->group(function () {
        Route::get('/nutrition-logs', [HealthNutritionLogController::class, 'index']);
        Route::post('/nutrition-logs', [HealthNutritionLogController::class, 'store']);
        Route::put('/nutrition-logs/{id}', [HealthNutritionLogController::class, 'update']);
        Route::delete('/nutrition-logs/{id}', [HealthNutritionLogController::class, 'destroy']);
    });
});
3. Laravel Route Checks

Run this inside backend:

cd /u01/nix-life-os/backend

php artisan route:list | grep nutrition
php artisan route:list | grep nutrition-logs

Expected result should include something like:

GET|HEAD   api/v1/nutrition/foods/search
GET|HEAD   api/v1/nutrition/foods/{id}
GET|HEAD   api/v1/health/nutrition-logs
POST       api/v1/health/nutrition-logs
PUT|PATCH  api/v1/health/nutrition-logs/{id}
DELETE     api/v1/health/nutrition-logs/{id}

If routes are missing, clear cache:

php artisan optimize:clear
php artisan route:clear
php artisan config:clear
php artisan cache:clear

Then test again.

4. Nutrition Food Search API Test

Use your token:

export TOKEN="YOUR_TOKEN_HERE"

Search food:

curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/search?query=rice" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Foods loaded successfully.",
  "data": [
    {
      "id": 1,
      "name": "White Rice Cooked",
      "brand": null,
      "serving_size": 100,
      "serving_unit": "g",
      "calories": 130,
      "protein_g": 2.7,
      "carbs_g": 28.2,
      "fat_g": 0.3,
      "sodium_mg": 1,
      "potassium_mg": 35,
      "phosphorus_mg": 43
    }
  ]
}
5. Add Meal API Test
curl -i -X POST "http://127.0.0.1:8000/api/v1/health/nutrition-logs" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "meal_date": "2026-05-10",
  "meal_type": "lunch",
  "food_name": "White Rice Cooked",
  "food_id": 1,
  "serving_size": 150,
  "serving_unit": "g",
  "calories": 195,
  "protein_g": 4.05,
  "carbs_g": 42.3,
  "fat_g": 0.45,
  "sodium_mg": 1.5,
  "potassium_mg": 52.5,
  "phosphorus_mg": 64.5,
  "notes": "Autofilled from nutrition database"
}'

Expected response:

{
  "success": true,
  "message": "Nutrition log created successfully.",
  "data": {
    "id": 10,
    "meal_date": "2026-05-10",
    "meal_type": "lunch",
    "food_name": "White Rice Cooked",
    "serving_size": 150,
    "serving_unit": "g",
    "calories": 195,
    "protein_g": 4.05,
    "sodium_mg": 1.5,
    "potassium_mg": 52.5,
    "phosphorus_mg": 64.5
  }
}
6. Vue API Service File

Create or update this file:

cd /u01/nix-life-os/frontend

nano src/services/nutritionService.js

Use this full code:

import api from './api'

const nutritionService = {
  searchFoods(query) {
    return api.get('/nutrition/foods/search', {
      params: { query }
    })
  },

  getFood(id) {
    return api.get(`/nutrition/foods/${id}`)
  },

  getNutritionLogs(date) {
    return api.get('/health/nutrition-logs', {
      params: { date }
    })
  },

  createNutritionLog(payload) {
    return api.post('/health/nutrition-logs', payload)
  },

  updateNutritionLog(id, payload) {
    return api.put(`/health/nutrition-logs/${id}`, payload)
  },

  deleteNutritionLog(id) {
    return api.delete(`/health/nutrition-logs/${id}`)
  }
}

export default nutritionService

Important: this assumes your src/services/api.js already has the base URL:

baseURL: '/api/v1'

or:

baseURL: 'http://127.0.0.1:8000/api/v1'

depending on your setup.

7. Full Vue Nutrition Screen Implementation

Update:

nano src/views/health/NutritionTrackingView.vue

Use this full implementation:

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

      <div class="summary-card" :class="{ warning: dailyTotals.protein_g > ckdLimits.protein_g }">
        <span>Protein</span>
        <strong>{{ dailyTotals.protein_g.toFixed(1) }}</strong>
        <small>Limit: {{ ckdLimits.protein_g }}g</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.sodium_mg > ckdLimits.sodium_mg }">
        <span>Sodium</span>
        <strong>{{ dailyTotals.sodium_mg.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.sodium_mg }}mg</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.potassium_mg > ckdLimits.potassium_mg }">
        <span>Potassium</span>
        <strong>{{ dailyTotals.potassium_mg.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.potassium_mg }}mg</small>
      </div>

      <div class="summary-card" :class="{ warning: dailyTotals.phosphorus_mg > ckdLimits.phosphorus_mg }">
        <span>Phosphorus</span>
        <strong>{{ dailyTotals.phosphorus_mg.toFixed(0) }}</strong>
        <small>Limit: {{ ckdLimits.phosphorus_mg }}mg</small>
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
                {{ food.serving_size }}{{ food.serving_unit }} —
                {{ food.calories }} kcal
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
            <label>Serving Size</label>
            <input
              type="number"
              min="0"
              step="0.1"
              v-model.number="form.serving_size"
              @input="recalculateFromServing"
            />
          </div>

          <div class="form-group">
            <label>Serving Unit</label>
            <input type="text" v-model="form.serving_unit" placeholder="g, ml, cup" />
          </div>
        </div>

        <div class="nutrition-input-grid">
          <div class="form-group">
            <label>Calories</label>
            <input type="number" step="0.1" v-model.number="form.calories" />
          </div>

          <div class="form-group">
            <label>Protein g</label>
            <input type="number" step="0.1" v-model.number="form.protein_g" />
          </div>

          <div class="form-group">
            <label>Carbs g</label>
            <input type="number" step="0.1" v-model.number="form.carbs_g" />
          </div>

          <div class="form-group">
            <label>Fat g</label>
            <input type="number" step="0.1" v-model.number="form.fat_g" />
          </div>

          <div class="form-group">
            <label>Sodium mg</label>
            <input type="number" step="0.1" v-model.number="form.sodium_mg" />
          </div>

          <div class="form-group">
            <label>Potassium mg</label>
            <input type="number" step="0.1" v-model.number="form.potassium_mg" />
          </div>

          <div class="form-group">
            <label>Phosphorus mg</label>
            <input type="number" step="0.1" v-model.number="form.phosphorus_mg" />
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
                {{ log.serving_size }} {{ log.serving_unit }} —
                {{ Number(log.calories || 0).toFixed(0) }} kcal
              </div>

              <div class="meal-nutrients">
                <span>Protein: {{ Number(log.protein_g || 0).toFixed(1) }}g</span>
                <span>Sodium: {{ Number(log.sodium_mg || 0).toFixed(0) }}mg</span>
                <span>Potassium: {{ Number(log.potassium_mg || 0).toFixed(0) }}mg</span>
                <span>Phosphorus: {{ Number(log.phosphorus_mg || 0).toFixed(0) }}mg</span>
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
        protein_g: 50,
        sodium_mg: 2000,
        potassium_mg: 2000,
        phosphorus_mg: 800
      },

      form: {
        meal_date: '',
        meal_type: 'breakfast',
        food_id: null,
        food_name: '',
        serving_size: 100,
        serving_unit: 'g',
        calories: 0,
        protein_g: 0,
        carbs_g: 0,
        fat_g: 0,
        sodium_mg: 0,
        potassium_mg: 0,
        phosphorus_mg: 0,
        notes: ''
      }
    }
  },

  computed: {
    dailyTotals() {
      return this.logs.reduce(
        (totals, log) => {
          totals.calories += Number(log.calories || 0)
          totals.protein_g += Number(log.protein_g || 0)
          totals.carbs_g += Number(log.carbs_g || 0)
          totals.fat_g += Number(log.fat_g || 0)
          totals.sodium_mg += Number(log.sodium_mg || 0)
          totals.potassium_mg += Number(log.potassium_mg || 0)
          totals.phosphorus_mg += Number(log.phosphorus_mg || 0)

          return totals
        },
        {
          calories: 0,
          protein_g: 0,
          carbs_g: 0,
          fat_g: 0,
          sodium_mg: 0,
          potassium_mg: 0,
          phosphorus_mg: 0
        }
      )
    },

    limitWarnings() {
      const warnings = []

      if (this.dailyTotals.protein_g > this.ckdLimits.protein_g) {
        warnings.push(`Protein limit exceeded: ${this.dailyTotals.protein_g.toFixed(1)}g / ${this.ckdLimits.protein_g}g`)
      }

      if (this.dailyTotals.sodium_mg > this.ckdLimits.sodium_mg) {
        warnings.push(`Sodium limit exceeded: ${this.dailyTotals.sodium_mg.toFixed(0)}mg / ${this.ckdLimits.sodium_mg}mg`)
      }

      if (this.dailyTotals.potassium_mg > this.ckdLimits.potassium_mg) {
        warnings.push(`Potassium limit exceeded: ${this.dailyTotals.potassium_mg.toFixed(0)}mg / ${this.ckdLimits.potassium_mg}mg`)
      }

      if (this.dailyTotals.phosphorus_mg > this.ckdLimits.phosphorus_mg) {
        warnings.push(`Phosphorus limit exceeded: ${this.dailyTotals.phosphorus_mg.toFixed(0)}mg / ${this.ckdLimits.phosphorus_mg}mg`)
      }

      return warnings
    }
  },

  mounted() {
    this.form.meal_date = this.selectedDate
    this.loadLogs()
  },

  methods: {
    async loadLogs() {
      this.isLoading = true
      this.errorMessage = ''
      this.successMessage = ''
      this.form.meal_date = this.selectedDate

      try {
        const response = await nutritionService.getNutritionLogs(this.selectedDate)
        this.logs = response.data.data || []
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
        this.foodResults = response.data.data || []
      } catch (error) {
        this.errorMessage = this.getErrorMessage(error, 'Failed to search foods.')
      } finally {
        this.isSearching = false
      }
    },

    selectFood(food) {
      this.selectedFoodBase = { ...food }

      this.form.food_id = food.id
      this.form.food_name = food.name
      this.form.serving_size = Number(food.serving_size || 100)
      this.form.serving_unit = food.serving_unit || 'g'

      this.form.calories = Number(food.calories || 0)
      this.form.protein_g = Number(food.protein_g || 0)
      this.form.carbs_g = Number(food.carbs_g || 0)
      this.form.fat_g = Number(food.fat_g || 0)
      this.form.sodium_mg = Number(food.sodium_mg || 0)
      this.form.potassium_mg = Number(food.potassium_mg || 0)
      this.form.phosphorus_mg = Number(food.phosphorus_mg || 0)

      this.foodSearch = food.name
      this.foodResults = []
    },

    recalculateFromServing() {
      if (!this.selectedFoodBase) {
        return
      }

      const baseServing = Number(this.selectedFoodBase.serving_size || 100)
      const currentServing = Number(this.form.serving_size || 0)

      if (baseServing <= 0 || currentServing <= 0) {
        return
      }

      const factor = currentServing / baseServing

      this.form.calories = this.roundValue(Number(this.selectedFoodBase.calories || 0) * factor)
      this.form.protein_g = this.roundValue(Number(this.selectedFoodBase.protein_g || 0) * factor)
      this.form.carbs_g = this.roundValue(Number(this.selectedFoodBase.carbs_g || 0) * factor)
      this.form.fat_g = this.roundValue(Number(this.selectedFoodBase.fat_g || 0) * factor)
      this.form.sodium_mg = this.roundValue(Number(this.selectedFoodBase.sodium_mg || 0) * factor)
      this.form.potassium_mg = this.roundValue(Number(this.selectedFoodBase.potassium_mg || 0) * factor)
      this.form.phosphorus_mg = this.roundValue(Number(this.selectedFoodBase.phosphorus_mg || 0) * factor)
    },

    async saveMeal() {
      this.errorMessage = ''
      this.successMessage = ''

      if (!this.form.food_name || !this.form.food_name.trim()) {
        this.errorMessage = 'Food name is required.'
        return
      }

      if (!this.form.serving_size || this.form.serving_size <= 0) {
        this.errorMessage = 'Serving size must be greater than zero.'
        return
      }

      this.isSaving = true

      const payload = {
        ...this.form,
        meal_date: this.selectedDate
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
        food_id: log.food_id || null,
        food_name: log.food_name || '',
        serving_size: Number(log.serving_size || 100),
        serving_unit: log.serving_unit || 'g',
        calories: Number(log.calories || 0),
        protein_g: Number(log.protein_g || 0),
        carbs_g: Number(log.carbs_g || 0),
        fat_g: Number(log.fat_g || 0),
        sodium_mg: Number(log.sodium_mg || 0),
        potassium_mg: Number(log.potassium_mg || 0),
        phosphorus_mg: Number(log.phosphorus_mg || 0),
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

      this.form = {
        meal_date: this.selectedDate,
        meal_type: 'breakfast',
        food_id: null,
        food_name: '',
        serving_size: 100,
        serving_unit: 'g',
        calories: 0,
        protein_g: 0,
        carbs_g: 0,
        fat_g: 0,
        sodium_mg: 0,
        potassium_mg: 0,
        phosphorus_mg: 0,
        notes: ''
      }
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
8. Serving Size Calculation Logic

The formula is:

new nutrient value = base nutrient value × requested serving size ÷ base serving size

Example:

Database food:

White Rice Cooked
Base serving: 100g
Calories: 130
Protein: 2.7g
Potassium: 35mg

User enters:

Serving size: 150g

Calculation:

Calories = 130 × 150 ÷ 100 = 195
Protein = 2.7 × 150 ÷ 100 = 4.05g
Potassium = 35 × 150 ÷ 100 = 52.5mg

This is already handled in:

recalculateFromServing()
9. CKD Nutrient Warning Logic

Current limits used in Vue:

ckdLimits: {
  protein_g: 50,
  sodium_mg: 2000,
  potassium_mg: 2000,
  phosphorus_mg: 800
}

Warnings appear when totals exceed limits:

if (dailyTotals.sodium_mg > ckdLimits.sodium_mg) {
  warning appears
}

You can later move these limits to backend/user profile table.

Recommended future table:

CREATE TABLE health_nutrition_limits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    protein_g numeric(8,2),
    sodium_mg numeric(8,2),
    potassium_mg numeric(8,2),
    phosphorus_mg numeric(8,2),
    calories numeric(8,2),
    created_at timestamp,
    updated_at timestamp
);
10. PostgreSQL Validation Queries

Connect to database:

docker exec -it nixlifeos-postgres psql -U postgres -d nixlifeos

Or use your actual DB name/user.

Check nutrition foods table:

SELECT 
    id,
    name,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg
FROM nutrition_foods
ORDER BY created_at DESC
LIMIT 20;

Search test:

SELECT 
    id,
    name,
    calories,
    protein_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg
FROM nutrition_foods
WHERE LOWER(name) LIKE LOWER('%rice%')
LIMIT 20;

Check logs for today:

SELECT 
    id,
    user_id,
    meal_date,
    meal_type,
    food_name,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    created_at
FROM health_nutrition_logs
WHERE meal_date = CURRENT_DATE
ORDER BY created_at DESC;

Check daily totals:

SELECT 
    meal_date,
    SUM(calories) AS total_calories,
    SUM(protein_g) AS total_protein_g,
    SUM(sodium_mg) AS total_sodium_mg,
    SUM(potassium_mg) AS total_potassium_mg,
    SUM(phosphorus_mg) AS total_phosphorus_mg
FROM health_nutrition_logs
WHERE meal_date = CURRENT_DATE
GROUP BY meal_date;

Check logs by user:

SELECT 
    user_id,
    meal_date,
    COUNT(*) AS meals_count,
    SUM(calories) AS calories,
    SUM(protein_g) AS protein_g,
    SUM(sodium_mg) AS sodium_mg,
    SUM(potassium_mg) AS potassium_mg,
    SUM(phosphorus_mg) AS phosphorus_mg
FROM health_nutrition_logs
GROUP BY user_id, meal_date
ORDER BY meal_date DESC;

Check empty date:

SELECT *
FROM health_nutrition_logs
WHERE meal_date = '2030-01-01';

Expected result:

0 rows

The Vue page should show:

No nutrition logs found for this date.
11. Backend Controller Validation Checklist

Your Laravel store() and update() should validate:

$request->validate([
    'meal_date' => ['required', 'date'],
    'meal_type' => ['required', 'in:breakfast,lunch,dinner,snack'],
    'food_id' => ['nullable', 'exists:nutrition_foods,id'],
    'food_name' => ['required', 'string', 'max:255'],
    'serving_size' => ['required', 'numeric', 'min:0.01'],
    'serving_unit' => ['required', 'string', 'max:50'],
    'calories' => ['nullable', 'numeric', 'min:0'],
    'protein_g' => ['nullable', 'numeric', 'min:0'],
    'carbs_g' => ['nullable', 'numeric', 'min:0'],
    'fat_g' => ['nullable', 'numeric', 'min:0'],
    'sodium_mg' => ['nullable', 'numeric', 'min:0'],
    'potassium_mg' => ['nullable', 'numeric', 'min:0'],
    'phosphorus_mg' => ['nullable', 'numeric', 'min:0'],
    'notes' => ['nullable', 'string'],
]);

Important security check:

$query->where('user_id', auth()->id());

Every nutrition log must belong only to the authenticated user.

12. Manual Food Entry Test

Do not search food. Enter manually:

Meal Type: Dinner
Food Name: Homemade Soup
Serving Size: 250
Serving Unit: ml
Calories: 180
Protein: 7
Carbs: 20
Fat: 5
Sodium: 350
Potassium: 400
Phosphorus: 120

Click:

Add Meal

Expected:

Meal appears in daily logs.
Daily totals increase.
PostgreSQL table contains the new row.
food_id can be null.
No frontend error appears.
13. Edit Meal Test

Steps:

Add a meal.
Click Edit.
Change serving size or calories.
Click Update Meal.
Confirm the card updates.
Confirm daily totals update.
Confirm DB row changed.

API test:

curl -i -X PUT "http://127.0.0.1:8000/api/v1/health/nutrition-logs/LOG_ID" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "meal_date": "2026-05-10",
  "meal_type": "lunch",
  "food_name": "White Rice Cooked Updated",
  "food_id": 1,
  "serving_size": 200,
  "serving_unit": "g",
  "calories": 260,
  "protein_g": 5.4,
  "carbs_g": 56.4,
  "fat_g": 0.6,
  "sodium_mg": 2,
  "potassium_mg": 70,
  "phosphorus_mg": 86,
  "notes": "Updated serving size"
}'
14. Delete Meal Test

API test:

curl -i -X DELETE "http://127.0.0.1:8000/api/v1/health/nutrition-logs/LOG_ID" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Nutrition log deleted successfully."
}

Validate in DB:

SELECT *
FROM health_nutrition_logs
WHERE id = 'LOG_ID';

Expected:

0 rows
15. Frontend Route Check

Check router:

cd /u01/nix-life-os/frontend

grep -n "NutritionTrackingView" src/router/index.js
grep -n "nutrition" src/router/index.js

Expected route:

{
  path: '/health/nutrition',
  name: 'HealthNutrition',
  component: NutritionTrackingView,
  meta: {
    requiresAuth: true,
    title: 'Nutrition Tracking'
  }
}

Also check sidebar:

grep -R "Nutrition" -n src

Expected files may include:

src/router/index.js
src/layouts/AppLayout.vue
src/views/health/NutritionTrackingView.vue
16. Common Problems and Fixes
Problem 1 — Route Not Found

Error:

{
  "message": "The route api/v1/nutrition/foods/search could not be found."
}

Fix:

cd /u01/nix-life-os/backend

php artisan route:list | grep nutrition
php artisan optimize:clear

Then check routes/api.php.

Problem 2 — Wrong Frontend API Base URL

If frontend calls:

/api/nutrition/foods/search

instead of:

/api/v1/nutrition/foods/search

fix:

nano src/services/api.js

Make sure base URL includes:

baseURL: '/api/v1'

or full backend URL:

baseURL: 'http://127.0.0.1:8000/api/v1'
Problem 3 — 401 Unauthorized

Cause:

Missing token.
Expired token.
User not logged in.
Sanctum issue.

Test:

curl -i "http://127.0.0.1:8000/api/v1/auth/me" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "data": {
    "id": "...",
    "name": "..."
  }
}
Problem 4 — Food Search Returns Empty

Check database:

SELECT COUNT(*) FROM nutrition_foods;

Search manually:

SELECT name
FROM nutrition_foods
WHERE LOWER(name) LIKE '%rice%';

If empty, insert sample data.

Problem 5 — Serving Calculation Not Updating

Check that selected food came from database.

This calculation only works when:

selectedFoodBase !== null

Manual entries will not auto-calculate because there is no base serving data.

Problem 6 — Daily Totals Do Not Update

Check:

await this.loadLogs()

after add, edit, and delete.

Also check API returns the latest logs after saving.

17. Sample Nutrition Food Insert Data

Use this only if your database has no sample foods:

INSERT INTO nutrition_foods
(
    name,
    brand,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    carbs_g,
    fat_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    created_at,
    updated_at
)
VALUES
('White Rice Cooked', NULL, 100, 'g', 130, 2.7, 28.2, 0.3, 1, 35, 43, NOW(), NOW()),
('Chicken Breast Cooked', NULL, 100, 'g', 165, 31, 0, 3.6, 74, 256, 228, NOW(), NOW()),
('Apple Raw', NULL, 100, 'g', 52, 0.3, 14, 0.2, 1, 107, 11, NOW(), NOW()),
('Boiled Egg', NULL, 50, 'g', 78, 6.3, 0.6, 5.3, 62, 63, 86, NOW(), NOW()),
('Cucumber Raw', NULL, 100, 'g', 15, 0.7, 3.6, 0.1, 2, 147, 24, NOW(), NOW());

If your table uses UUID:

INSERT INTO nutrition_foods
(
    id,
    name,
    brand,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    carbs_g,
    fat_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    created_at,
    updated_at
)
VALUES
(gen_random_uuid(), 'White Rice Cooked', NULL, 100, 'g', 130, 2.7, 28.2, 0.3, 1, 35, 43, NOW(), NOW());
18. Final Testing Checklist
Backend
Test	Expected
php artisan route:list shows food search route	Pass
php artisan route:list shows nutrition logs CRUD routes	Pass
Food search API works	Pass
Add nutrition log works	Pass
Edit nutrition log works	Pass
Delete nutrition log works	Pass
Unauthorized request returns 401	Pass
Invalid serving size returns 422	Pass
Manual food entry with food_id = null works	Pass
Logs are filtered by authenticated user	Pass
Frontend
Test	Expected
Nutrition screen opens	Pass
Date filter works	Pass
Food search shows database results	Pass
Selecting food autofills values	Pass
Serving size recalculates nutrition values	Pass
Manual food entry works	Pass
Add meal works	Pass
Edit meal works	Pass
Delete meal works	Pass
Daily totals update after every action	Pass
CKD warnings appear when limits exceeded	Pass
Empty date shows empty state	Pass
API error shows readable message	Pass
SQL
Test	Query
Food database has data	SELECT COUNT(*) FROM nutrition_foods;
Search works	SELECT * FROM nutrition_foods WHERE LOWER(name) LIKE '%rice%';
Logs saved	SELECT * FROM health_nutrition_logs ORDER BY created_at DESC;
Daily totals correct	SELECT meal_date, SUM(calories), SUM(protein_g), SUM(sodium_mg), SUM(potassium_mg), SUM(phosphorus_mg) FROM health_nutrition_logs GROUP BY meal_date;
Delete works	SELECT * FROM health_nutrition_logs WHERE id = 'LOG_ID';
19. Step 47 Completion Criteria

Step 47 is complete when:

Nutrition Tracking screen can search foods from the nutrition facts database.
Selecting a food autofills nutrition values.
Changing serving size recalculates calories and nutrients.
Manual food entry works without food_id.
Add, edit, and delete meal logs work.
Daily totals update automatically.
CKD nutrient warnings appear correctly.
Empty state and API error state work correctly.
PostgreSQL data matches frontend display.

Final status:

STEP 47 — Nutrition Screen Full Integration: COMPLETED