<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "/api/v1";
const token = localStorage.getItem("token");

const foods = ref([]);
const search = ref("");

const form = ref({
  food_name: "",
  category: "",
  calories_per_100g: 0,
  protein_per_100g: 0,
  carbs_per_100g: 0,
  fat_per_100g: 0,
  sodium_per_100g_mg: 0,
  potassium_per_100g_mg: 0,
  phosphorus_per_100g_mg: 0,
  is_ckd_friendly: true,
});

async function loadFoods() {
  const response = await fetch(
    `${API_BASE}/health/nutrition/foods?search=${search.value}`,
    {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  foods.value = data.data || [];
}

async function saveFood() {
  const response = await fetch(`${API_BASE}/health/nutrition/foods`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(form.value),
  });

  if (response.ok) {
    await loadFoods();

    form.value = {
      food_name: "",
      category: "",
      calories_per_100g: 0,
      protein_per_100g: 0,
      carbs_per_100g: 0,
      fat_per_100g: 0,
      sodium_per_100g_mg: 0,
      potassium_per_100g_mg: 0,
      phosphorus_per_100g_mg: 0,
      is_ckd_friendly: true,
    };
  }
}

onMounted(loadFoods);
</script>

<template>
  <div>
    <h2 class="text-3xl font-bold text-gray-900 mb-2">Food Items</h2>
    <p class="text-gray-500 mb-8">Manage food nutrition facts per 100g.</p>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <div class="bg-white rounded-2xl shadow p-6">
        <h3 class="text-xl font-bold mb-4">Add Food</h3>

        <div class="space-y-4">
          <input v-model="form.food_name" placeholder="Food Name" class="w-full rounded-xl border px-4 py-2" />
          <input v-model="form.category" placeholder="Category" class="w-full rounded-xl border px-4 py-2" />

          <input v-model.number="form.calories_per_100g" type="number" placeholder="Calories / 100g" class="w-full rounded-xl border px-4 py-2" />
          <input v-model.number="form.protein_per_100g" type="number" placeholder="Protein / 100g" class="w-full rounded-xl border px-4 py-2" />
          <input v-model.number="form.carbs_per_100g" type="number" placeholder="Carbs / 100g" class="w-full rounded-xl border px-4 py-2" />
          <input v-model.number="form.fat_per_100g" type="number" placeholder="Fat / 100g" class="w-full rounded-xl border px-4 py-2" />

          <input v-model.number="form.sodium_per_100g_mg" type="number" placeholder="Sodium mg / 100g" class="w-full rounded-xl border px-4 py-2" />
          <input v-model.number="form.potassium_per_100g_mg" type="number" placeholder="Potassium mg / 100g" class="w-full rounded-xl border px-4 py-2" />
          <input v-model.number="form.phosphorus_per_100g_mg" type="number" placeholder="Phosphorus mg / 100g" class="w-full rounded-xl border px-4 py-2" />

          <label class="flex items-center gap-2">
            <input v-model="form.is_ckd_friendly" type="checkbox" />
            CKD Friendly
          </label>

          <button @click="saveFood" class="w-full rounded-xl bg-black text-white py-3">
            Save Food
          </button>
        </div>
      </div>

      <div class="lg:col-span-2 bg-white rounded-2xl shadow p-6">
        <div class="flex justify-between mb-4">
          <h3 class="text-xl font-bold">Food List</h3>
          <input
            v-model="search"
            @input="loadFoods"
            placeholder="Search food..."
            class="rounded-xl border px-4 py-2"
          />
        </div>

        <table class="w-full text-left">
          <thead>
            <tr class="border-b">
              <th class="py-3">Food</th>
              <th>Calories</th>
              <th>Protein</th>
              <th>Sodium</th>
              <th>Potassium</th>
              <th>Phosphorus</th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="food in foods" :key="food.id" class="border-b">
              <td class="py-3">{{ food.food_name }}</td>
              <td>{{ food.calories_per_100g }}</td>
              <td>{{ food.protein_per_100g }}g</td>
              <td>{{ food.sodium_per_100g_mg }}mg</td>
              <td>{{ food.potassium_per_100g_mg }}mg</td>
              <td>{{ food.phosphorus_per_100g_mg }}mg</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>