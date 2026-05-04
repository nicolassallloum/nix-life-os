// Add food item
{
  food_name: form.food_name,
  calories_per_100g: Number(form.calories_per_100g),
  protein_per_100g: Number(form.protein_per_100g),
  carbs_per_100g: Number(form.carbs_per_100g),
  fat_per_100g: Number(form.fat_per_100g),
  sodium_per_100g_mg: Number(form.sodium_per_100g_mg),
  potassium_per_100g_mg: Number(form.potassium_per_100g_mg),
  phosphorus_per_100g_mg: Number(form.phosphorus_per_100g_mg)
}

// Add meal
{
  meal_date: form.meal_date,
  meal_type: form.meal_type,
  notes: form.notes,
  items: [
    {
      food_item_id: form.food_item_id,
      quantity_g: Number(form.quantity_g)
    }
  ]
}