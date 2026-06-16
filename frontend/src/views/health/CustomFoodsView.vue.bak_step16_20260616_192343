<template>
  <section class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Custom Foods</h1>
        <p class="text-sm text-slate-500">
          Create and manage your personal nutrition food database.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
        @click="resetForm"
      >
        + New Food
      </button>
    </div>

    <div
      v-if="successMessage"
      class="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-700"
    >
      {{ successMessage }}
    </div>

    <div
      v-if="error"
      class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700"
    >
      {{ error }}
    </div>

    <div class="grid gap-5 xl:grid-cols-[420px_1fr]">
      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <h2 class="text-lg font-bold text-slate-900">
          {{ editingId ? "Edit Custom Food" : "Add Custom Food" }}
        </h2>
        <p class="mt-1 text-sm text-slate-500">
          Add CKD-friendly nutrition values for your own food database.
        </p>

        <form class="mt-5 space-y-4" @submit.prevent="saveFood">
          <div>
            <label class="mb-1 block text-sm font-semibold text-slate-700">Food Name *</label>
            <input
              v-model="form.name"
              required
              type="text"
              class="w-full rounded-xl border border-slate-300 px-4 py-3 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
              placeholder="Example: Homemade rice"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="mb-1 block text-sm font-semibold text-slate-700">Quantity *</label>
              <input
                v-model.number="form.serving_size"
                required
                type="number"
                min="0"
                step="0.01"
                class="w-full rounded-xl border border-slate-300 px-4 py-3 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                placeholder="100"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm font-semibold text-slate-700">Unit *</label>
              <select
                v-model="form.unit"
                required
                class="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
              >
                <option value="g">g</option>
                <option value="ml">ml</option>
                <option value="piece">piece</option>
                <option value="cup">cup</option>
                <option value="tbsp">tbsp</option>
                <option value="tsp">tsp</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <NumberInput label="Calories" v-model="form.calories" suffix="kcal" />
            <NumberInput label="Protein" v-model="form.protein_g" suffix="g" />
            <NumberInput label="Carbs" v-model="form.carbs_g" suffix="g" />
            <NumberInput label="Fat" v-model="form.fat_g" suffix="g" />
            <NumberInput label="Sodium" v-model="form.sodium_mg" suffix="mg" />
            <NumberInput label="Potassium" v-model="form.potassium_mg" suffix="mg" />
            <NumberInput label="Phosphorus" v-model="form.phosphorus_mg" suffix="mg" />
          </div>

          <div>
            <label class="mb-1 block text-sm font-semibold text-slate-700">Notes</label>
            <textarea
              v-model="form.notes"
              rows="3"
              class="w-full rounded-xl border border-slate-300 px-4 py-3 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
              placeholder="Optional notes"
            ></textarea>
          </div>

          <div class="flex gap-3">
            <button
              type="submit"
              :disabled="loading"
              class="rounded-xl bg-blue-600 px-5 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {{ loading ? "Saving..." : editingId ? "Update Food" : "Save Food" }}
            </button>

            <button
              v-if="editingId"
              type="button"
              class="rounded-xl border border-slate-300 px-5 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              @click="resetForm"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>

      <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-bold text-slate-900">Custom Food List</h2>
            <p class="text-sm text-slate-500">Your saved personal foods.</p>
          </div>

          <div class="flex gap-2">
            <input
              v-model="search"
              type="text"
              class="rounded-xl border border-slate-300 px-4 py-2 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20"
              placeholder="Search food..."
              @keyup.enter="loadFoods"
            />

            <button
              type="button"
              class="rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              @click="loadFoods"
            >
              Refresh
            </button>
          </div>
        </div>

        <div v-if="loading && foods.length === 0" class="rounded-xl bg-slate-50 p-8 text-center text-sm text-slate-500">
          Loading custom foods...
        </div>

        <div v-else-if="foods.length === 0" class="rounded-xl bg-slate-50 p-8 text-center text-sm text-slate-500">
          No custom foods found.
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-xs uppercase text-slate-500">
                <th class="py-3 pr-4">Food</th>
                <th class="py-3 pr-4">Serving</th>
                <th class="py-3 pr-4">Calories</th>
                <th class="py-3 pr-4">Protein</th>
                <th class="py-3 pr-4">Sodium</th>
                <th class="py-3 pr-4">Potassium</th>
                <th class="py-3 pr-4">Phosphorus</th>
                <th class="py-3 pr-4 text-right">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr
                v-for="food in foods"
                :key="food.id"
                class="border-b border-slate-100 text-slate-700"
              >
                <td class="py-3 pr-4 font-semibold text-slate-900">
                  {{ food.name || food.food_name || "-" }}
                </td>
                <td class="py-3 pr-4">
                  {{ food.serving_size || food.quantity || 0 }} {{ food.serving_unit || food.unit || "g" }}
                </td>
                <td class="py-3 pr-4">{{ food.calories ?? 0 }}</td>
                <td class="py-3 pr-4">{{ food.protein_g ?? food.protein ?? 0 }}g</td>
                <td class="py-3 pr-4">{{ food.sodium_mg ?? food.sodium ?? 0 }}mg</td>
                <td class="py-3 pr-4">{{ food.potassium_mg ?? food.potassium ?? 0 }}mg</td>
                <td class="py-3 pr-4">{{ food.phosphorus_mg ?? food.phosphorus ?? 0 }}mg</td>
                <td class="py-3 pr-4 text-right">
                  <div class="flex justify-end gap-2">
                    <button
                      type="button"
                      class="rounded-lg bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-200"
                      @click="editFood(food)"
                    >
                      Edit
                    </button>

                    <button
                      type="button"
                      class="rounded-lg bg-red-50 px-3 py-1 text-xs font-semibold text-red-600 hover:bg-red-100"
                      @click="deleteFood(food.id)"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="mt-5 rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-800">
          <strong>CKD Note:</strong>
          Sodium, potassium, phosphorus, and protein values help you track kidney-friendly nutrition limits.
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, ref } from "vue";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api/v1";

const loading = ref(false);
const error = ref("");
const successMessage = ref("");
const foods = ref([]);
const search = ref("");
const editingId = ref(null);

const form = ref(defaultForm());

function defaultForm() {
  return {
    name: "",
    serving_size: 100,
    unit: "g",
    calories: 0,
    protein_g: 0,
    carbs_g: 0,
    fat_g: 0,
    sodium_mg: 0,
    potassium_mg: 0,
    phosphorus_mg: 0,
    notes: "",
  };
}

function getToken() {
  return (
    localStorage.getItem("nix_token") ||
    localStorage.getItem("token") ||
    localStorage.getItem("auth_token") ||
    localStorage.getItem("access_token")
  );
}

const endpoints = computed(() => [
  `${API_BASE_URL}/nutrition/custom-foods`,
]);

async function request(method, url, body = null) {
  const token = getToken();

  const response = await fetch(url, {
    method,
    headers: {
      Accept: "application/json",
      ...(body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  const data = await response.json().catch(() => null);

  if (!response.ok || data?.success === false) {
    const validation = data?.errors
      ? Object.values(data.errors).flat().join(" ")
      : "";

    throw new Error(validation || data?.message || `Request failed: ${response.status}`);
  }

  return data;
}

function normalizeArray(payload) {
  if (Array.isArray(payload?.data)) return payload.data;
  if (Array.isArray(payload?.data?.data)) return payload.data.data;
  if (Array.isArray(payload?.items)) return payload.items;
  if (Array.isArray(payload)) return payload;
  return [];
}

async function tryEndpoints(method, suffix = "", body = null) {
  let lastError = null;

  for (const base of endpoints.value) {
    try {
      return await request(method, `${base}${suffix}`, body);
    } catch (err) {
      lastError = err;
    }
  }

  throw lastError || new Error("Custom foods API endpoint not found.");
}

function buildPayload() {
  return {
    name: form.value.name,
    serving_size: Number(form.value.serving_size || 0),
    serving_unit: form.value.unit,
    calories: Number(form.value.calories || 0),
    protein_g: Number(form.value.protein_g || 0),
    carbs_g: Number(form.value.carbs_g || 0),
    fat_g: Number(form.value.fat_g || 0),
    sodium_mg: Number(form.value.sodium_mg || 0),
    potassium_mg: Number(form.value.potassium_mg || 0),
    phosphorus_mg: Number(form.value.phosphorus_mg || 0),
    notes: form.value.notes || null,
  };
}

async function loadFoods() {
  loading.value = true;
  error.value = "";
  successMessage.value = "";

  try {
    const query = search.value ? `?search=${encodeURIComponent(search.value)}` : "";
    const result = await tryEndpoints("GET", query);
    foods.value = normalizeArray(result);
  } catch (err) {
    error.value = err.message || "Unable to load custom foods.";
  } finally {
    loading.value = false;
  }
}

async function saveFood() {
  loading.value = true;
  error.value = "";
  successMessage.value = "";

  try {
    const payload = buildPayload();

    if (editingId.value) {
      await tryEndpoints("PUT", `/${editingId.value}`, payload);
      successMessage.value = "Custom food updated successfully.";
    } else {
      await tryEndpoints("POST", "", payload);
      successMessage.value = "Custom food created successfully.";
    }

    resetForm();
    await loadFoods();
    successMessage.value = editingId.value ? "Custom food updated successfully." : "Custom food created successfully.";
  } catch (err) {
    error.value = err.message || "Unable to save custom food.";
  } finally {
    loading.value = false;
  }
}

function editFood(food) {
  editingId.value = food.id;

  form.value = {
    name: food.name || food.food_name || "",
    serving_size: Number(food.serving_size || food.quantity || 100),
    unit: food.unit || "g",
    calories: Number(food.calories || 0),
    protein_g: Number(food.protein_g || food.protein || 0),
    carbs_g: Number(food.carbs_g || food.carbs || 0),
    fat_g: Number(food.fat_g || food.fat || 0),
    sodium_mg: Number(food.sodium_mg || food.sodium || 0),
    potassium_mg: Number(food.potassium_mg || food.potassium || 0),
    phosphorus_mg: Number(food.phosphorus_mg || food.phosphorus || 0),
    notes: food.notes || "",
  };

  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function deleteFood(id) {
  if (!confirm("Delete this custom food?")) return;

  loading.value = true;
  error.value = "";
  successMessage.value = "";

  try {
    await tryEndpoints("DELETE", `/${id}`);
    successMessage.value = "Custom food deleted successfully.";
    await loadFoods();
  } catch (err) {
    error.value = err.message || "Unable to delete custom food.";
  } finally {
    loading.value = false;
  }
}

function resetForm() {
  editingId.value = null;
  form.value = defaultForm();
}

const NumberInput = defineComponent({
  props: {
    modelValue: {
      type: [Number, String],
      default: 0,
    },
    label: {
      type: String,
      required: true,
    },
    suffix: {
      type: String,
      default: "",
    },
  },
  emits: ["update:modelValue"],
  setup(props, { emit }) {
    return () =>
      h("div", {}, [
        h("label", { class: "mb-1 block text-sm font-semibold text-slate-700" }, props.label),
        h("div", { class: "relative" }, [
          h("input", {
            value: props.modelValue,
            type: "number",
            min: "0",
            step: "0.01",
            class:
              "w-full rounded-xl border border-slate-300 px-4 py-3 pr-12 text-sm focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-600/20",
            onInput: (event) => emit("update:modelValue", event.target.value),
          }),
          props.suffix
            ? h("span", { class: "absolute right-4 top-3 text-xs font-semibold text-slate-400" }, props.suffix)
            : null,
        ]),
      ]);
  },
});

onMounted(() => {
  loadFoods();
});
</script>
