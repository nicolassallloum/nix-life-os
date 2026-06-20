<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "/api/v1";
const token = localStorage.getItem("token");

const foods = ref([]);
const meals = ref([]);

const form = ref({
  meal_date: new Date().toISOString().substring(0, 10),
  meal_type: "lunch",
  meal_name: "",
  items: [
    {
      food_item_id: "",
      quantity_g: 100,
    },
  ],
});

async function loadFoods() {
  const response = await fetch(`${API_BASE}/health/nutrition/foods`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
    },
  });

  const data = await response.json();
  foods.value = data.data || [];
}

async function loadMeals() {
  const response = await fetch(
    `${API_BASE}/health/nutrition/meals?date=${form.value.meal_date}`,
    {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  meals.value = data.data || [];
}

function addItem() {
  form.value.items.push({
    food_item_id: "",
    quantity_g: 100,
  });
}

function removeItem(index) {
  form.value.items.splice(index, 1);
}

async function saveMeal() {
  const response = await fetch(`${API_BASE}/health/nutrition/meals`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(form.value),
  });

  if (response.ok) {
    await loadMeals();

    form.value.meal_name = "";
    form.value.items = [
      {
        food_item_id: "",
        quantity_g: 100,
      },
    ];
  }
}

onMounted(async () => {
  await loadFoods();
  await loadMeals();
});
</script>

<template>
  <div>
    <h2 class="text-3xl font-bold text-gray-900 mb-2">Meal Logger</h2>
    <p class="text-gray-500 mb-8">Log meals and automatically calculate nutrients.</p>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <div class="bg-white rounded-2xl shadow p-6">
        <h3 class="text-xl font-bold mb-4">Add Meal</h3>

        <div class="space-y-4">
          <input
            v-model="form.meal_date"
            @change="loadMeals"
            type="date"
            class="w-full rounded-xl border px-4 py-2"
          />

          <select v-model="form.meal_type" class="w-full rounded-xl border px-4 py-2">
            <option value="breakfast">Breakfast</option>
            <option value="lunch">Lunch</option>
            <option value="dinner">Dinner</option>
            <option value="snack">Snack</option>
          </select>

          <input
            v-model="form.meal_name"
            placeholder="Meal name"
            class="w-full rounded-xl border px-4 py-2"
          />

          <div
            v-for="(item, index) in form.items"
            :key="index"
            class="rounded-xl border p-4 space-y-3"
          >
            <select v-model="item.food_item_id" class="w-full rounded-xl border px-4 py-2">
              <option value="">Select Food</option>
              <option v-for="food in foods" :key="food.id" :value="food.id">
                {{ food.food_name }}
              </option>
            </select>

            <input
              v-model.number="item.quantity_g"
              type="number"
              placeholder="Quantity in grams"
              class="w-full rounded-xl border px-4 py-2"
            />

            <button
              v-if="form.items.length > 1"
              @click="removeItem(index)"
              class="text-red-600"
            >
              Remove
            </button>
          </div>

          <button @click="addItem" class="w-full rounded-xl border py-3">
            Add Another Food
          </button>

          <button @click="saveMeal" class="w-full rounded-xl bg-black text-white py-3">
            Save Meal
          </button>
        </div>
      </div>

      <div class="lg:col-span-2 bg-white rounded-2xl shadow p-6">
        <h3 class="text-xl font-bold mb-4">Meals for Selected Day</h3>

        <div v-for="meal in meals" :key="meal.id" class="border-b py-4">
          <div class="flex justify-between">
            <div>
              <h4 class="font-bold capitalize">{{ meal.meal_type }} - {{ meal.meal_name }}</h4>
              <p class="text-gray-500">{{ meal.meal_date }}</p>
            </div>

            <div class="text-right">
              <p class="font-bold">{{ meal.totals.calories }} kcal</p>
              <p class="text-gray-500">{{ meal.totals.protein_g }}g protein</p>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-4 mt-4 text-sm text-gray-600">
            <p>Sodium: {{ meal.totals.sodium_mg }}mg</p>
            <p>Potassium: {{ meal.totals.potassium_mg }}mg</p>
            <p>Phosphorus: {{ meal.totals.phosphorus_mg }}mg</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Health follow-up readability fix: force readable text in light form fields */
input,
select,
textarea,
input:disabled,
select:disabled,
textarea:disabled,
input[readonly],
select[readonly],
textarea[readonly] {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  caret-color: #2563eb !important;
  opacity: 1 !important;
  color-scheme: light !important;
}

input::placeholder,
textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

select option,
option {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
}

input:-webkit-autofill,
textarea:-webkit-autofill,
select:-webkit-autofill {
  -webkit-text-fill-color: #020617 !important;
  box-shadow: 0 0 0 1000px #ffffff inset !important;
  transition: background-color 9999s ease-out 0s !important;
}

input::selection,
textarea::selection,
select::selection {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
  background-color: #2563eb !important;
}

input::-moz-selection,
textarea::-moz-selection,
select::-moz-selection {
  color: #ffffff !important;
  background-color: #2563eb !important;
}
</style>
