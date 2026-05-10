🔹 STEP 48 — Custom Food Management
Nix Life OS Nutrition Module

You are now extending the Nutrition module with a Custom Food Management system.

This feature allows the user to create personal foods, optionally promote foods to global database usage, search foods, and reuse them inside meal logs.

1. Feature Goal

The Custom Food Management screen must allow:

Add custom food.
Edit custom food.
Delete custom food.
Mark food as personal or global.
Store nutrition facts.
Validate:
Calories
Protein
Sodium
Potassium
Phosphorus
Search custom foods.
Use custom food in meal logs.
Prevent duplicate foods.
Prepare structure for future AI food recommendations.
2. Recommended Database Design
Table: nutrition_custom_foods

Create a new table for custom user foods.

cd /u01/nix-life-os/backend

php artisan make:migration create_nutrition_custom_foods_table

Open the new migration file:

nano database/migrations/XXXX_XX_XX_XXXXXX_create_nutrition_custom_foods_table.php

Use this migration:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_custom_foods', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->nullable();

            $table->string('name', 150);
            $table->string('brand', 150)->nullable();
            $table->string('category', 100)->nullable();

            $table->decimal('serving_size', 10, 2)->default(100);
            $table->string('serving_unit', 50)->default('g');

            $table->decimal('calories', 10, 2)->default(0);
            $table->decimal('protein_g', 10, 2)->default(0);
            $table->decimal('carbs_g', 10, 2)->default(0);
            $table->decimal('fat_g', 10, 2)->default(0);

            $table->decimal('sodium_mg', 10, 2)->default(0);
            $table->decimal('potassium_mg', 10, 2)->default(0);
            $table->decimal('phosphorus_mg', 10, 2)->default(0);

            $table->boolean('is_personal')->default(true);
            $table->boolean('is_global')->default(false);
            $table->boolean('is_ai_recommended')->default(false);

            $table->json('ai_metadata')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->nullOnDelete();

            $table->unique(['user_id', 'name', 'brand']);
            $table->index(['name']);
            $table->index(['category']);
            $table->index(['is_global']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_custom_foods');
    }
};

Run migration:

php artisan migrate
3. Laravel Model

Create the model:

php artisan make:model NutritionCustomFood

Open:

nano app/Models/NutritionCustomFood.php

Use:

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class NutritionCustomFood extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_custom_foods';

    protected $fillable = [
        'user_id',
        'name',
        'brand',
        'category',
        'serving_size',
        'serving_unit',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
        'is_personal',
        'is_global',
        'is_ai_recommended',
        'ai_metadata',
    ];

    protected $casts = [
        'serving_size' => 'decimal:2',
        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',
        'is_personal' => 'boolean',
        'is_global' => 'boolean',
        'is_ai_recommended' => 'boolean',
        'ai_metadata' => 'array',
    ];
}
4. Laravel Controller

Create controller:

php artisan make:controller Api/V1/NutritionCustomFoodController

Open:

nano app/Http/Controllers/Api/V1/NutritionCustomFoodController.php

Use:

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\NutritionCustomFood;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class NutritionCustomFoodController extends Controller
{
    public function index(Request $request)
    {
        $userId = Auth::id();

        $query = NutritionCustomFood::query()
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('is_global', true);
            });

        if ($request->filled('search')) {
            $search = strtolower($request->search);

            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(brand) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(category) LIKE ?', ["%{$search}%"]);
            });
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        $foods = $query
            ->orderBy('name')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'message' => 'Custom foods loaded successfully.',
            'data' => $foods,
        ]);
    }

    public function store(Request $request)
    {
        $userId = Auth::id();

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:150',
                Rule::unique('nutrition_custom_foods')
                    ->where('user_id', $userId)
                    ->where('brand', $request->brand)
                    ->whereNull('deleted_at'),
            ],
            'brand' => ['nullable', 'string', 'max:150'],
            'category' => ['nullable', 'string', 'max:100'],

            'serving_size' => ['required', 'numeric', 'min:0.01', 'max:10000'],
            'serving_unit' => ['required', 'string', 'max:50'],

            'calories' => ['required', 'numeric', 'min:0', 'max:5000'],
            'protein_g' => ['required', 'numeric', 'min:0', 'max:500'],
            'carbs_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'fat_g' => ['nullable', 'numeric', 'min:0', 'max:500'],

            'sodium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'potassium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'phosphorus_mg' => ['required', 'numeric', 'min:0', 'max:10000'],

            'is_personal' => ['boolean'],
            'is_global' => ['boolean'],
        ]);

        $food = NutritionCustomFood::create([
            ...$validated,
            'user_id' => $validated['is_global'] ?? false ? null : $userId,
            'is_personal' => !($validated['is_global'] ?? false),
            'is_global' => $validated['is_global'] ?? false,
            'is_ai_recommended' => false,
            'ai_metadata' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Custom food created successfully.',
            'data' => $food,
        ], 201);
    }

    public function show(string $id)
    {
        $food = $this->findAccessibleFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Custom food loaded successfully.',
            'data' => $food,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $food = $this->findOwnedFood($id);
        $userId = Auth::id();

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:150',
                Rule::unique('nutrition_custom_foods')
                    ->ignore($food->id)
                    ->where('user_id', $userId)
                    ->where('brand', $request->brand)
                    ->whereNull('deleted_at'),
            ],
            'brand' => ['nullable', 'string', 'max:150'],
            'category' => ['nullable', 'string', 'max:100'],

            'serving_size' => ['required', 'numeric', 'min:0.01', 'max:10000'],
            'serving_unit' => ['required', 'string', 'max:50'],

            'calories' => ['required', 'numeric', 'min:0', 'max:5000'],
            'protein_g' => ['required', 'numeric', 'min:0', 'max:500'],
            'carbs_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'fat_g' => ['nullable', 'numeric', 'min:0', 'max:500'],

            'sodium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'potassium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'phosphorus_mg' => ['required', 'numeric', 'min:0', 'max:10000'],

            'is_personal' => ['boolean'],
            'is_global' => ['boolean'],
        ]);

        $food->update([
            ...$validated,
            'user_id' => $validated['is_global'] ?? false ? null : $userId,
            'is_personal' => !($validated['is_global'] ?? false),
            'is_global' => $validated['is_global'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Custom food updated successfully.',
            'data' => $food->fresh(),
        ]);
    }

    public function destroy(string $id)
    {
        $food = $this->findOwnedFood($id);

        $food->delete();

        return response()->json([
            'success' => true,
            'message' => 'Custom food deleted successfully.',
        ]);
    }

    private function findAccessibleFood(string $id): NutritionCustomFood
    {
        $userId = Auth::id();

        return NutritionCustomFood::where('id', $id)
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('is_global', true);
            })
            ->firstOrFail();
    }

    private function findOwnedFood(string $id): NutritionCustomFood
    {
        $userId = Auth::id();

        return NutritionCustomFood::where('id', $id)
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhereNull('user_id');
            })
            ->firstOrFail();
    }
}
5. Laravel API Routes

Open:

nano routes/api.php

Inside your authenticated API v1 group, add:

use App\Http\Controllers\Api\V1\NutritionCustomFoodController;

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/nutrition/custom-foods', [NutritionCustomFoodController::class, 'index']);
    Route::post('/nutrition/custom-foods', [NutritionCustomFoodController::class, 'store']);
    Route::get('/nutrition/custom-foods/{id}', [NutritionCustomFoodController::class, 'show']);
    Route::put('/nutrition/custom-foods/{id}', [NutritionCustomFoodController::class, 'update']);
    Route::delete('/nutrition/custom-foods/{id}', [NutritionCustomFoodController::class, 'destroy']);
});

Then run:

php artisan optimize:clear
php artisan route:list | grep nutrition

Expected routes:

GET       api/v1/nutrition/custom-foods
POST      api/v1/nutrition/custom-foods
GET       api/v1/nutrition/custom-foods/{id}
PUT       api/v1/nutrition/custom-foods/{id}
DELETE    api/v1/nutrition/custom-foods/{id}
6. Connect Custom Foods to Meal Logs

Your meal logs should support choosing a food from:

Nutrition facts database.
Custom foods table.
Manual entry.

If your current nutrition logs table is health_nutrition_logs, add these nullable columns if they do not exist:

php artisan make:migration add_custom_food_id_to_health_nutrition_logs_table

Migration:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('health_nutrition_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('health_nutrition_logs', 'custom_food_id')) {
                $table->uuid('custom_food_id')->nullable()->after('id');

                $table->foreign('custom_food_id')
                    ->references('id')
                    ->on('nutrition_custom_foods')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('health_nutrition_logs', 'food_source')) {
                $table->string('food_source', 50)->default('manual')->after('custom_food_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('health_nutrition_logs', function (Blueprint $table) {
            if (Schema::hasColumn('health_nutrition_logs', 'custom_food_id')) {
                $table->dropForeign(['custom_food_id']);
                $table->dropColumn('custom_food_id');
            }

            if (Schema::hasColumn('health_nutrition_logs', 'food_source')) {
                $table->dropColumn('food_source');
            }
        });
    }
};

Run:

php artisan migrate
7. Meal Log API Logic

When adding a meal log, the backend should accept:

{
  "custom_food_id": "UUID_HERE",
  "serving_multiplier": 1.5,
  "meal_type": "lunch",
  "log_date": "2026-05-10"
}

The backend should:

Load the selected custom food.
Multiply nutrition values by serving multiplier.
Store calculated meal nutrition.
Set food_source = custom_food.

Example calculation:

$calories = $food->calories * $servingMultiplier;
$protein = $food->protein_g * $servingMultiplier;
$sodium = $food->sodium_mg * $servingMultiplier;
$potassium = $food->potassium_mg * $servingMultiplier;
$phosphorus = $food->phosphorus_mg * $servingMultiplier;
8. Vue Screen Design

Create a new screen:

cd /u01/nix-life-os/frontend

nano src/views/health/CustomFoodsView.vue

Recommended screen sections:

Page Header
Custom Food Management
Create and manage your personal nutrition food database.

Buttons:

+ Add Custom Food
Refresh
Search Section

Fields:

Search by name, brand, or category
Filter by category
Personal / Global filter
Food Table

Columns:

Food Name
Brand
Category
Serving
Calories
Protein
Sodium
Potassium
Phosphorus
Scope
Actions

Actions:

Edit
Delete
Use in Meal
Add/Edit Modal Form

Fields:

Food Name
Brand
Category
Serving Size
Serving Unit
Calories
Protein
Carbs
Fat
Sodium
Potassium
Phosphorus
Food Scope: Personal / Global

Validation warnings:

Sodium is high for CKD.
Potassium is high for CKD.
Phosphorus is high for CKD.
Protein should be controlled for CKD.
9. Vue API Service

Create or update:

nano src/services/nutritionCustomFoodService.js

Use:

import api from './api'

export const nutritionCustomFoodService = {
  async getFoods(params = {}) {
    const response = await api.get('/v1/nutrition/custom-foods', { params })
    return response.data
  },

  async getFood(id) {
    const response = await api.get(`/v1/nutrition/custom-foods/${id}`)
    return response.data
  },

  async createFood(payload) {
    const response = await api.post('/v1/nutrition/custom-foods', payload)
    return response.data
  },

  async updateFood(id, payload) {
    const response = await api.put(`/v1/nutrition/custom-foods/${id}`, payload)
    return response.data
  },

  async deleteFood(id) {
    const response = await api.delete(`/v1/nutrition/custom-foods/${id}`)
    return response.data
  }
}
10. Vue Router

Open:

nano src/router/index.js

Import:

import CustomFoodsView from '@/views/health/CustomFoodsView.vue'

Add route:

{
  path: '/health/custom-foods',
  name: 'health-custom-foods',
  component: CustomFoodsView,
  meta: {
    requiresAuth: true,
    title: 'Custom Foods'
  }
}
11. Sidebar Menu

Open your layout/sidebar file, usually:

nano src/layouts/AppLayout.vue

Add under Health section:

<RouterLink
  to="/health/custom-foods"
  class="sidebar-link"
>
  Custom Foods
</RouterLink>

Recommended Health menu order:

Health Dashboard
Steps Tracking
Weight Tracking
Nutrition Tracking
Custom Foods
Hydration Tracking
Sleep Tracking
Mood Tracking
Medication Tracking
Lab Tests
12. CURL Tests

Set token:

export TOKEN="YOUR_TOKEN_HERE"
Test 1 — List Custom Foods
curl -i "http://127.0.0.1:8000/api/v1/nutrition/custom-foods" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Custom foods loaded successfully.",
  "data": {
    "data": []
  }
}
Test 2 — Add Custom Food
curl -i -X POST "http://127.0.0.1:8000/api/v1/nutrition/custom-foods" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "name": "Homemade Labneh Low Salt",
  "brand": "Nix Homemade",
  "category": "Dairy",
  "serving_size": 100,
  "serving_unit": "g",
  "calories": 95,
  "protein_g": 7,
  "carbs_g": 4,
  "fat_g": 5,
  "sodium_mg": 85,
  "potassium_mg": 130,
  "phosphorus_mg": 90,
  "is_personal": true,
  "is_global": false
}'

Expected:

{
  "success": true,
  "message": "Custom food created successfully.",
  "data": {
    "name": "Homemade Labneh Low Salt",
    "calories": "95.00",
    "protein_g": "7.00"
  }
}

Copy the returned food ID:

export FOOD_ID="PASTE_ID_HERE"
Test 3 — Search Custom Foods
curl -i "http://127.0.0.1:8000/api/v1/nutrition/custom-foods?search=labneh" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Custom foods loaded successfully."
}
Test 4 — Show One Food
curl -i "http://127.0.0.1:8000/api/v1/nutrition/custom-foods/$FOOD_ID" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Custom food loaded successfully."
}
Test 5 — Update Food
curl -i -X PUT "http://127.0.0.1:8000/api/v1/nutrition/custom-foods/$FOOD_ID" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "name": "Homemade Labneh Very Low Salt",
  "brand": "Nix Homemade",
  "category": "Dairy",
  "serving_size": 100,
  "serving_unit": "g",
  "calories": 90,
  "protein_g": 7,
  "carbs_g": 4,
  "fat_g": 4,
  "sodium_mg": 60,
  "potassium_mg": 120,
  "phosphorus_mg": 80,
  "is_personal": true,
  "is_global": false
}'

Expected:

{
  "success": true,
  "message": "Custom food updated successfully."
}
Test 6 — Duplicate Prevention

Run the same POST again:

curl -i -X POST "http://127.0.0.1:8000/api/v1/nutrition/custom-foods" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "name": "Homemade Labneh Very Low Salt",
  "brand": "Nix Homemade",
  "category": "Dairy",
  "serving_size": 100,
  "serving_unit": "g",
  "calories": 90,
  "protein_g": 7,
  "carbs_g": 4,
  "fat_g": 4,
  "sodium_mg": 60,
  "potassium_mg": 120,
  "phosphorus_mg": 80,
  "is_personal": true,
  "is_global": false
}'

Expected:

{
  "message": "The name has already been taken."
}

Status should be:

422 Unprocessable Content
Test 7 — Delete Food
curl -i -X DELETE "http://127.0.0.1:8000/api/v1/nutrition/custom-foods/$FOOD_ID" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Custom food deleted successfully."
}
13. PostgreSQL Validation Queries

Connect to database:

docker exec -it nixlifeos-postgres psql -U nixlifeos -d nixlifeos

Or use your current PostgreSQL connection.

Check table exists
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'nutrition_custom_foods';
Check columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'nutrition_custom_foods'
ORDER BY ordinal_position;
View custom foods
SELECT 
    id,
    user_id,
    name,
    brand,
    category,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    is_personal,
    is_global,
    created_at
FROM nutrition_custom_foods
ORDER BY created_at DESC;
Check duplicate rule
SELECT 
    user_id,
    name,
    brand,
    COUNT(*) AS duplicate_count
FROM nutrition_custom_foods
WHERE deleted_at IS NULL
GROUP BY user_id, name, brand
HAVING COUNT(*) > 1;

Expected:

0 rows
Check global foods
SELECT 
    id,
    name,
    brand,
    category,
    is_global,
    user_id
FROM nutrition_custom_foods
WHERE is_global = true;
Check personal foods
SELECT 
    id,
    name,
    brand,
    category,
    is_personal,
    user_id
FROM nutrition_custom_foods
WHERE is_personal = true;
14. CKD Validation Logic

In the Vue form, show warnings when:

const warnings = computed(() => {
  const result = []

  if (Number(form.sodium_mg) > 300) {
    result.push('Sodium is high for CKD. Consider reducing portion size.')
  }

  if (Number(form.potassium_mg) > 250) {
    result.push('Potassium is high for CKD. Use with caution.')
  }

  if (Number(form.phosphorus_mg) > 150) {
    result.push('Phosphorus is high for CKD. Limit frequency.')
  }

  if (Number(form.protein_g) > 15) {
    result.push('Protein is high. Check your daily CKD protein limit.')
  }

  if (Number(form.calories) > 700) {
    result.push('Calories are high for one serving.')
  }

  return result
})

These warnings should not always block saving. They should warn the user and help with kidney-friendly decisions.

15. Future AI Recommendation Support

The table already includes:

is_ai_recommended
ai_metadata

Future AI metadata can store:

{
  "reason": "Low sodium and moderate protein option",
  "ckd_score": 82,
  "recommended_portion": "75g",
  "risk_flags": ["moderate_phosphorus"],
  "alternative_foods": ["low-salt yogurt", "boiled egg white"]
}

This prepares the system for:

AI meal suggestions.
CKD-friendly food scoring.
Portion size recommendations.
High-risk nutrient warnings.
Personalized nutrition planning.
16. Backend Testing Checklist
Test	Expected Result
Migration runs successfully	nutrition_custom_foods table created
Route list shows custom foods APIs	All 5 routes visible
Unauthorized request	Returns 401
Add food with valid data	Returns 201
Add duplicate food	Returns 422
Add negative sodium	Returns 422
Add negative potassium	Returns 422
Add negative phosphorus	Returns 422
Add negative calories	Returns 422
Search by name	Returns matching foods
Search by brand	Returns matching foods
Search by category	Returns matching foods
Edit own food	Returns 200
Delete own food	Returns 200
Global food visible to users	Returns in list
Deleted food hidden	Does not appear in list
17. Frontend Testing Checklist
Screen Area	Expected Result
/health/custom-foods opens	Page loads successfully
Sidebar link exists	Opens Custom Foods screen
Search input works	Filters foods
Empty state works	Shows no foods message
Add food modal opens	Form appears
Required validation works	Missing fields blocked
CKD warnings appear	High sodium/potassium/phosphorus warnings show
Save food works	Food appears in table
Edit food works	Updated values appear
Delete food works	Food removed
Personal/global badge works	Correct badge shown
Use in Meal button works	Sends food to meal log form
API error shown	User sees readable error
Loading state works	Spinner or disabled button visible
18. Final STEP 48 Pass Criteria

STEP 48 is complete when:

✔ nutrition_custom_foods table exists
✔ Laravel model exists
✔ Controller exists
✔ API routes are registered
✔ Add custom food works
✔ Edit custom food works
✔ Delete custom food works
✔ Search custom foods works
✔ Duplicate foods are prevented
✔ Personal/global food scope works
✔ Nutrition facts are stored correctly
✔ CKD nutrient validations work
✔ Custom foods can be connected to meal logs
✔ Vue screen is added
✔ Sidebar link is added
✔ CURL tests pass
✔ SQL validation queries pass
✔ System is ready for future AI recommendations
Recommended Next Step
🔹 STEP 49 — Custom Food Screen Full Vue Implementation

Use this prompt next:

🔹 STEP 49 — Custom Food Screen Full Vue Implementation

You are a Senior Vue.js Frontend Engineer.

Build the full Custom Food Management screen for Nix Life OS.

The screen must support:

1. Load custom foods from API.
2. Search foods by name, brand, and category.
3. Add custom food.
4. Edit custom food.
5. Delete custom food.
6. Show CKD warnings.
7. Show personal/global badges.
8. Show loading, empty, and error states.
9. Use selected custom food in nutrition meal logs.
10. Prepare structure for future AI food recommendations.

Provide the complete Vue component code, API service code, router update, sidebar update, and frontend testing checklist.