<script setup>
import { computed, onMounted, ref } from "vue";
import axios from "axios";

const API_BASE_URL = "/api/v1";

const token =
  localStorage.getItem("auth_token") ||
  localStorage.getItem("token") ||
  localStorage.getItem("access_token");

const selectedDate = ref(new Date().toISOString().slice(0, 10));
const loading = ref(false);
const errorMessage = ref("");

const summary = ref({
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  sodium: 0,
  potassium: 0,
  phosphorus: 0,
  sugar: 0,
  fiber: 0,
  fluids: 0,
});

const warnings = ref([]);

const mealForm = ref({
  meal_type: "breakfast",
  food_name: "",
  quantity: 100,
  quantity_unit: "g",
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  sodium: 0,
  potassium: 0,
  phosphorus: 0,
  sugar: 0,
  fiber: 0,
  fluids: 0,
  notes: "",
});

const meals = ref([]);

const axiosConfig = computed(() => ({
  headers: {
    Accept: "application/json",
    Authorization: `Bearer ${token}`,
  },
}));

const nutritionCards = computed(() => [
  {
    label: "Calories",
    value: summary.value.calories,
    unit: "kcal",
  },
  {
    label: "Protein",
    value: summary.value.protein,
    unit: "g",
  },
  {
    label: "Carbs",
    value: summary.value.carbs,
    unit: "g",
  },
  {
    label: "Fat",
    value: summary.value.fat,
    unit: "g",
  },
  {
    label: "Sodium",
    value: summary.value.sodium,
    unit: "mg",
  },
  {
    label: "Potassium",
    value: summary.value.potassium,
    unit: "mg",
  },
  {
    label: "Phosphorus",
    value: summary.value.phosphorus,
    unit: "mg",
  },
  {
    label: "Sugar",
    value: summary.value.sugar,
    unit: "g",
  },
  {
    label: "Fiber",
    value: summary.value.fiber,
    unit: "g",
  },
  {
    label: "Fluids",
    value: summary.value.fluids,
    unit: "ml",
  },
]);

function formatNumber(value) {
  const number = Number(value || 0);

  if (Number.isInteger(number)) {
    return number;
  }

  return number.toFixed(2);
}

async function fetchDailyNutrition() {
  loading.value = true;
  errorMessage.value = "";

  try {
    const response = await axios.post(
      `${API_BASE_URL}/health/nutrition/summary?date=${selectedDate.value}`,
      axiosConfig.value
    );

    const data = response.data?.data || response.data;

    summary.value = {
      calories: data?.totals?.calories ?? data?.calories ?? 0,
      protein: data?.totals?.protein ?? data?.protein ?? 0,
      carbs: data?.totals?.carbs ?? data?.carbs ?? 0,
      fat: data?.totals?.fat ?? data?.fat ?? 0,
      sodium: data?.totals?.sodium ?? data?.sodium ?? 0,
      potassium: data?.totals?.potassium ?? data?.potassium ?? 0,
      phosphorus: data?.totals?.phosphorus ?? data?.phosphorus ?? 0,
      sugar: data?.totals?.sugar ?? data?.sugar ?? 0,
      fiber: data?.totals?.fiber ?? data?.fiber ?? 0,
      fluids: data?.totals?.fluids ?? data?.fluids ?? 0,
    };

    warnings.value =
      data?.warnings ||
      data?.ckd_warnings ||
      data?.safety_warnings ||
      [];
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      "Unable to load nutrition analytics. Please check backend API.";
  } finally {
    loading.value = false;
  }
}

async function fetchMeals() {
  try {
    const response = await axios.get(
      `${API_BASE_URL}/health/nutrition?date=${selectedDate.value}`,
      axiosConfig.value
    );

    meals.value = response.data?.data || [];
  } catch (error) {
    meals.value = [];
  }
}

async function addMeal() {
  loading.value = true;
  errorMessage.value = "";

  try {
    await axios.post(
      `${API_BASE_URL}/health/nutrition`,
      {
        meal_date: selectedDate.value,
        meal_type: mealForm.value.meal_type,
        food_name: mealForm.value.food_name,
        quantity: Number(mealForm.value.quantity),
        unit: mealForm.value.quantity_unit,
        calories: Number(mealForm.value.calories),
        protein_g: Number(mealForm.value.protein),
        carbs_g: Number(mealForm.value.carbs),
        fat_g: Number(mealForm.value.fat),
        sodium_mg: Number(mealForm.value.sodium),
        potassium_mg: Number(mealForm.value.potassium),
        phosphorus_mg: Number(mealForm.value.phosphorus),
        sugar: Number(mealForm.value.sugar),
        fiber: Number(mealForm.value.fiber),
        fluids: Number(mealForm.value.fluids),
        notes: mealForm.value.notes,
      },
      axiosConfig.value
    );

    mealForm.value = {
      meal_type: "breakfast",
      food_name: "",
      quantity: 100,
      quantity_unit: "g",
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      sodium: 0,
      potassium: 0,
      phosphorus: 0,
      sugar: 0,
      fiber: 0,
      fluids: 0,
      notes: "",
    };

    await fetchDailyNutrition();
    await fetchMeals();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      "Unable to add meal. Please check your nutrition endpoint.";
  } finally {
    loading.value = false;
  }
}

async function deleteMeal(id) {
  if (!confirm("Delete this nutrition log?")) {
    return;
  }

  try {
    await axios.delete(
      `${API_BASE_URL}/health/nutrition/${id}`,
      axiosConfig.value
    );

    await fetchDailyNutrition();
    await fetchMeals();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      "Unable to delete meal.";
  }
}

async function refreshPage() {
  await fetchDailyNutrition();
  await fetchMeals();
}

onMounted(async () => {
  await refreshPage();
});
</script>

<template>
  <div class="space-y-8">
    <!-- Header -->
    <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-4xl font-bold text-gray-900">
          Nutrition Dashboard
        </h1>
        <p class="text-gray-500 mt-2">
          Daily CKD-safe nutrient monitoring
        </p>
      </div>

      <div class="flex items-center gap-3">
        <input
          v-model="selectedDate"
          type="date"
          class="rounded-xl border border-gray-300 px-4 py-3 bg-white"
          @change="refreshPage"
        />

        <button
          type="button"
          class="rounded-xl bg-gray-900 text-white px-5 py-3 hover:bg-gray-700"
          @click="refreshPage"
        >
          Refresh
        </button>
      </div>
    </div>

    <!-- Error -->
    <div
      v-if="errorMessage"
      class="rounded-2xl border border-red-200 bg-red-50 text-red-700 p-4"
    >
      {{ errorMessage }}
    </div>

    <!-- Loading -->
    <div
      v-if="loading"
      class="rounded-2xl border border-blue-200 bg-blue-50 text-blue-700 p-4"
    >
      Loading nutrition data...
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      <div
        v-for="card in nutritionCards"
        :key="card.label"
        class="bg-white rounded-2xl shadow p-6 border border-gray-100"
      >
        <p class="text-gray-500">
          {{ card.label }}
        </p>

        <h2 class="text-4xl font-bold text-gray-900 mt-3">
          {{ formatNumber(card.value) }}
          <span class="text-xl">{{ card.unit }}</span>
        </h2>
      </div>
    </div>

    <!-- CKD Safety Warnings -->
    <section class="bg-white rounded-2xl shadow p-6 border border-gray-100">
      <h2 class="text-2xl font-bold text-gray-900">
        CKD Safety Warnings
      </h2>

      <div
        v-if="warnings.length === 0"
        class="mt-5 rounded-2xl bg-green-50 text-green-700 p-5"
      >
        No nutrient limits exceeded for this day.
      </div>

      <div
        v-else
        class="mt-5 space-y-3"
      >
        <div
          v-for="(warning, index) in warnings"
          :key="index"
          class="rounded-2xl bg-red-50 text-red-700 p-5 border border-red-100"
        >
          {{ warning.message || warning }}
        </div>
      </div>
    </section>

    <!-- Add Meal Form -->
    <section class="bg-white rounded-2xl shadow p-6 border border-gray-100">
      <h2 class="text-2xl font-bold text-gray-900 mb-6">
        Add Nutrition Log
      </h2>

      <form
        class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-5"
        @submit.prevent="addMeal"
      >
        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Meal Type
          </label>
          <select
            v-model="mealForm.meal_type"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          >
            <option value="breakfast">Breakfast</option>
            <option value="lunch">Lunch</option>
            <option value="dinner">Dinner</option>
            <option value="snack">Snack</option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Food Name
          </label>
          <input
            v-model="mealForm.food_name"
            type="text"
            required
            placeholder="Example: Boiled chicken"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Quantity
          </label>
          <input
            v-model="mealForm.quantity"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Unit
          </label>
          <select
            v-model="mealForm.quantity_unit"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          >
            <option value="g">g</option>
            <option value="ml">ml</option>
            <option value="piece">piece</option>
            <option value="cup">cup</option>
            <option value="tbsp">tbsp</option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Calories
          </label>
          <input
            v-model="mealForm.calories"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Protein g
          </label>
          <input
            v-model="mealForm.protein"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Carbs g
          </label>
          <input
            v-model="mealForm.carbs"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Fat g
          </label>
          <input
            v-model="mealForm.fat"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Sodium mg
          </label>
          <input
            v-model="mealForm.sodium"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Potassium mg
          </label>
          <input
            v-model="mealForm.potassium"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Phosphorus mg
          </label>
          <input
            v-model="mealForm.phosphorus"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Sugar g
          </label>
          <input
            v-model="mealForm.sugar"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Fiber g
          </label>
          <input
            v-model="mealForm.fiber"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Fluids ml
          </label>
          <input
            v-model="mealForm.fluids"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-600 mb-2">
            Notes
          </label>
          <input
            v-model="mealForm.notes"
            type="text"
            placeholder="Optional notes"
            class="w-full rounded-xl border border-gray-300 px-4 py-3"
          />
        </div>

        <div class="md:col-span-3 lg:col-span-4">
          <button
            type="submit"
            class="rounded-xl bg-gray-900 text-white px-6 py-3 hover:bg-gray-700 disabled:opacity-50"
            :disabled="loading"
          >
            Add Meal
          </button>
        </div>
      </form>
    </section>

    <!-- Meals Table -->
    <section class="bg-white rounded-2xl shadow p-6 border border-gray-100">
      <h2 class="text-2xl font-bold text-gray-900 mb-6">
        Daily Nutrition Logs
      </h2>

      <div class="overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b bg-gray-50 text-left">
              <th class="p-4">Meal</th>
              <th class="p-4">Food</th>
              <th class="p-4">Qty</th>
              <th class="p-4">Calories</th>
              <th class="p-4">Protein</th>
              <th class="p-4">Sodium</th>
              <th class="p-4">Potassium</th>
              <th class="p-4">Phosphorus</th>
              <th class="p-4">Action</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-if="meals.length === 0"
              class="border-b"
            >
              <td
                colspan="9"
                class="p-4 text-gray-500 text-center"
              >
                No nutrition logs found for this day.
              </td>
            </tr>

            <tr
              v-for="meal in meals"
              :key="meal.id"
              class="border-b hover:bg-gray-50"
            >
              <td class="p-4 capitalize">
                {{ meal.meal_type }}
              </td>

              <td class="p-4 font-medium">
                {{ meal.food_name }}
              </td>

              <td class="p-4">
                {{ meal.quantity }} {{ meal.quantity_unit }}
              </td>

              <td class="p-4">
                {{ formatNumber(meal.calories) }}
              </td>

              <td class="p-4">
                {{ formatNumber(meal.protein) }}g
              </td>

              <td class="p-4">
                {{ formatNumber(meal.sodium) }}mg
              </td>

              <td class="p-4">
                {{ formatNumber(meal.potassium) }}mg
              </td>

              <td class="p-4">
                {{ formatNumber(meal.phosphorus) }}mg
              </td>

              <td class="p-4">
                <button
                  type="button"
                  class="text-red-600 hover:text-red-800 font-medium"
                  @click="deleteMeal(meal.id)"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>