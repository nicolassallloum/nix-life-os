STEP 10 — Health Nutrition Tracking Module

NIX LIFE OS — CKD-Safe Nutrition System

This step will add:

Meal logging
Food item database
Nutrition per meal
Daily nutrition summary
CKD-safe daily limits
Warnings for sodium, potassium, phosphorus, protein
API endpoints
Vue frontend pages
1. Module Structure

We will create these backend tables:

health_nutrition_profiles
health_food_items
health_meal_logs
health_meal_log_items
Purpose
Table	Purpose
health_nutrition_profiles	Stores daily CKD nutrition limits per user
health_food_items	Stores food nutrition facts per 100g
health_meal_logs	Stores breakfast/lunch/dinner/snack logs
health_meal_log_items	Stores foods inside each meal with quantity
2. Generate Laravel Files

Run inside backend:

cd /u01/nix-life-os/backend

php artisan make:model HealthNutritionProfile -m
php artisan make:model HealthFoodItem -m
php artisan make:model HealthMealLog -m
php artisan make:model HealthMealLogItem -m

php artisan make:controller Api/V1/Health/HealthNutritionProfileController --api
php artisan make:controller Api/V1/Health/HealthFoodItemController --api
php artisan make:controller Api/V1/Health/HealthMealLogController --api
php artisan make:controller Api/V1/Health/HealthNutritionSummaryController

php artisan make:resource HealthNutritionProfileResource
php artisan make:resource HealthFoodItemResource
php artisan make:resource HealthMealLogResource
php artisan make:resource HealthMealLogItemResource
3. Migration: health_nutrition_profiles

Open the generated migration:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_nutrition_profiles_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_nutrition_profiles', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('profile_name')->default('CKD Daily Nutrition Profile');

            $table->unsignedInteger('daily_calories_min')->nullable();
            $table->unsignedInteger('daily_calories_max')->nullable();

            $table->decimal('daily_protein_max_g', 8, 2)->nullable();
            $table->decimal('daily_carbs_max_g', 8, 2)->nullable();
            $table->decimal('daily_fat_max_g', 8, 2)->nullable();

            $table->decimal('daily_sodium_max_mg', 8, 2)->nullable();
            $table->decimal('daily_potassium_max_mg', 8, 2)->nullable();
            $table->decimal('daily_phosphorus_max_mg', 8, 2)->nullable();

            $table->boolean('is_ckd_safe_mode')->default(true);
            $table->boolean('is_active')->default(true);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'is_active']);
            $table->index(['user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_nutrition_profiles');
    }
};
4. Migration: health_food_items

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_food_items_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_food_items', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->string('food_name');
            $table->string('brand_name')->nullable();
            $table->string('category')->nullable();

            /*
             * Nutrients are stored per 100 grams.
             */
            $table->decimal('calories_per_100g', 10, 2)->default(0);
            $table->decimal('protein_per_100g', 10, 2)->default(0);
            $table->decimal('carbs_per_100g', 10, 2)->default(0);
            $table->decimal('fat_per_100g', 10, 2)->default(0);

            $table->decimal('sodium_per_100g_mg', 10, 2)->default(0);
            $table->decimal('potassium_per_100g_mg', 10, 2)->default(0);
            $table->decimal('phosphorus_per_100g_mg', 10, 2)->default(0);

            $table->boolean('is_ckd_friendly')->default(false);
            $table->boolean('is_custom')->default(false);
            $table->boolean('is_active')->default(true);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['food_name']);
            $table->index(['category']);
            $table->index(['is_ckd_friendly']);
            $table->index(['user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_food_items');
    }
};
5. Migration: health_meal_logs

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_meal_logs_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_meal_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('meal_date');
            $table->string('meal_type'); 
            // breakfast, lunch, dinner, snack

            $table->string('meal_name')->nullable();
            $table->text('notes')->nullable();

            /*
             * Stored summary for faster dashboard loading.
             */
            $table->decimal('total_calories', 10, 2)->default(0);
            $table->decimal('total_protein_g', 10, 2)->default(0);
            $table->decimal('total_carbs_g', 10, 2)->default(0);
            $table->decimal('total_fat_g', 10, 2)->default(0);

            $table->decimal('total_sodium_mg', 10, 2)->default(0);
            $table->decimal('total_potassium_mg', 10, 2)->default(0);
            $table->decimal('total_phosphorus_mg', 10, 2)->default(0);

            $table->timestamps();

            $table->index(['user_id', 'meal_date']);
            $table->index(['meal_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_meal_logs');
    }
};
6. Migration: health_meal_log_items

Open:

nano database/migrations/xxxx_xx_xx_xxxxxx_create_health_meal_log_items_table.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_meal_log_items', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('meal_log_id')
                ->constrained('health_meal_logs')
                ->cascadeOnDelete();

            $table->foreignUuid('food_item_id')
                ->constrained('health_food_items')
                ->restrictOnDelete();

            $table->decimal('quantity_g', 10, 2);

            /*
             * Snapshot values at logging time.
             */
            $table->decimal('calories', 10, 2)->default(0);
            $table->decimal('protein_g', 10, 2)->default(0);
            $table->decimal('carbs_g', 10, 2)->default(0);
            $table->decimal('fat_g', 10, 2)->default(0);

            $table->decimal('sodium_mg', 10, 2)->default(0);
            $table->decimal('potassium_mg', 10, 2)->default(0);
            $table->decimal('phosphorus_mg', 10, 2)->default(0);

            $table->timestamps();

            $table->index(['meal_log_id']);
            $table->index(['food_item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_meal_log_items');
    }
};
7. Run Migration
php artisan migrate

If you get UUID errors, make sure your users.id is UUID, not bigint.

8. Models
app/Models/HealthNutritionProfile.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthNutritionProfile extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'profile_name',
        'daily_calories_min',
        'daily_calories_max',
        'daily_protein_max_g',
        'daily_carbs_max_g',
        'daily_fat_max_g',
        'daily_sodium_max_mg',
        'daily_potassium_max_mg',
        'daily_phosphorus_max_mg',
        'is_ckd_safe_mode',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'is_ckd_safe_mode' => 'boolean',
        'is_active' => 'boolean',
    ];
}
app/Models/HealthFoodItem.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthFoodItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'food_name',
        'brand_name',
        'category',
        'calories_per_100g',
        'protein_per_100g',
        'carbs_per_100g',
        'fat_per_100g',
        'sodium_per_100g_mg',
        'potassium_per_100g_mg',
        'phosphorus_per_100g_mg',
        'is_ckd_friendly',
        'is_custom',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'is_ckd_friendly' => 'boolean',
        'is_custom' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function calculateForQuantity(float $quantityG): array
    {
        $factor = $quantityG / 100;

        return [
            'calories' => round($this->calories_per_100g * $factor, 2),
            'protein_g' => round($this->protein_per_100g * $factor, 2),
            'carbs_g' => round($this->carbs_per_100g * $factor, 2),
            'fat_g' => round($this->fat_per_100g * $factor, 2),
            'sodium_mg' => round($this->sodium_per_100g_mg * $factor, 2),
            'potassium_mg' => round($this->potassium_per_100g_mg * $factor, 2),
            'phosphorus_mg' => round($this->phosphorus_per_100g_mg * $factor, 2),
        ];
    }
}
app/Models/HealthMealLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthMealLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'meal_date',
        'meal_type',
        'meal_name',
        'notes',
        'total_calories',
        'total_protein_g',
        'total_carbs_g',
        'total_fat_g',
        'total_sodium_mg',
        'total_potassium_mg',
        'total_phosphorus_mg',
    ];

    public function items()
    {
        return $this->hasMany(HealthMealLogItem::class, 'meal_log_id');
    }

    public function recalculateTotals(): void
    {
        $totals = $this->items()
            ->selectRaw('
                COALESCE(SUM(calories), 0) as calories,
                COALESCE(SUM(protein_g), 0) as protein_g,
                COALESCE(SUM(carbs_g), 0) as carbs_g,
                COALESCE(SUM(fat_g), 0) as fat_g,
                COALESCE(SUM(sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(phosphorus_mg), 0) as phosphorus_mg
            ')
            ->first();

        $this->update([
            'total_calories' => $totals->calories,
            'total_protein_g' => $totals->protein_g,
            'total_carbs_g' => $totals->carbs_g,
            'total_fat_g' => $totals->fat_g,
            'total_sodium_mg' => $totals->sodium_mg,
            'total_potassium_mg' => $totals->potassium_mg,
            'total_phosphorus_mg' => $totals->phosphorus_mg,
        ]);
    }
}
app/Models/HealthMealLogItem.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthMealLogItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'meal_log_id',
        'food_item_id',
        'quantity_g',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
    ];

    public function food()
    {
        return $this->belongsTo(HealthFoodItem::class, 'food_item_id');
    }

    public function mealLog()
    {
        return $this->belongsTo(HealthMealLog::class, 'meal_log_id');
    }
}
9. Resources
app/Http/Resources/HealthFoodItemResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthFoodItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'food_name' => $this->food_name,
            'brand_name' => $this->brand_name,
            'category' => $this->category,
            'calories_per_100g' => (float) $this->calories_per_100g,
            'protein_per_100g' => (float) $this->protein_per_100g,
            'carbs_per_100g' => (float) $this->carbs_per_100g,
            'fat_per_100g' => (float) $this->fat_per_100g,
            'sodium_per_100g_mg' => (float) $this->sodium_per_100g_mg,
            'potassium_per_100g_mg' => (float) $this->potassium_per_100g_mg,
            'phosphorus_per_100g_mg' => (float) $this->phosphorus_per_100g_mg,
            'is_ckd_friendly' => (bool) $this->is_ckd_friendly,
            'is_custom' => (bool) $this->is_custom,
            'notes' => $this->notes,
        ];
    }
}
app/Http/Resources/HealthMealLogItemResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthMealLogItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'food_item_id' => $this->food_item_id,
            'food' => new HealthFoodItemResource($this->whenLoaded('food')),
            'quantity_g' => (float) $this->quantity_g,
            'calories' => (float) $this->calories,
            'protein_g' => (float) $this->protein_g,
            'carbs_g' => (float) $this->carbs_g,
            'fat_g' => (float) $this->fat_g,
            'sodium_mg' => (float) $this->sodium_mg,
            'potassium_mg' => (float) $this->potassium_mg,
            'phosphorus_mg' => (float) $this->phosphorus_mg,
        ];
    }
}
app/Http/Resources/HealthMealLogResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthMealLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'meal_date' => $this->meal_date,
            'meal_type' => $this->meal_type,
            'meal_name' => $this->meal_name,
            'notes' => $this->notes,

            'totals' => [
                'calories' => (float) $this->total_calories,
                'protein_g' => (float) $this->total_protein_g,
                'carbs_g' => (float) $this->total_carbs_g,
                'fat_g' => (float) $this->total_fat_g,
                'sodium_mg' => (float) $this->total_sodium_mg,
                'potassium_mg' => (float) $this->total_potassium_mg,
                'phosphorus_mg' => (float) $this->total_phosphorus_mg,
            ],

            'items' => HealthMealLogItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
app/Http/Resources/HealthNutritionProfileResource.php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthNutritionProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'profile_name' => $this->profile_name,
            'daily_calories_min' => $this->daily_calories_min,
            'daily_calories_max' => $this->daily_calories_max,
            'daily_protein_max_g' => (float) $this->daily_protein_max_g,
            'daily_carbs_max_g' => (float) $this->daily_carbs_max_g,
            'daily_fat_max_g' => (float) $this->daily_fat_max_g,
            'daily_sodium_max_mg' => (float) $this->daily_sodium_max_mg,
            'daily_potassium_max_mg' => (float) $this->daily_potassium_max_mg,
            'daily_phosphorus_max_mg' => (float) $this->daily_phosphorus_max_mg,
            'is_ckd_safe_mode' => (bool) $this->is_ckd_safe_mode,
            'is_active' => (bool) $this->is_active,
            'notes' => $this->notes,
        ];
    }
}
10. Controllers
HealthNutritionProfileController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthNutritionProfileResource;
use App\Models\HealthNutritionProfile;
use Illuminate\Http\Request;

class HealthNutritionProfileController extends Controller
{
    public function index(Request $request)
    {
        $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        return response()->json([
            'success' => true,
            'data' => $profile ? new HealthNutritionProfileResource($profile) : null,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'profile_name' => ['nullable', 'string', 'max:255'],
            'daily_calories_min' => ['nullable', 'integer', 'min:0'],
            'daily_calories_max' => ['nullable', 'integer', 'min:0'],
            'daily_protein_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_carbs_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_fat_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_sodium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_potassium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_phosphorus_max_mg' => ['nullable', 'numeric', 'min:0'],
            'is_ckd_safe_mode' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        HealthNutritionProfile::where('user_id', $request->user()->id)
            ->update(['is_active' => false]);

        $profile = HealthNutritionProfile::create([
            ...$data,
            'user_id' => $request->user()->id,
            'profile_name' => $data['profile_name'] ?? 'CKD Daily Nutrition Profile',
            'is_active' => true,
            'is_ckd_safe_mode' => $data['is_ckd_safe_mode'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition profile saved successfully.',
            'data' => new HealthNutritionProfileResource($profile),
        ], 201);
    }
}
HealthFoodItemController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthFoodItemResource;
use App\Models\HealthFoodItem;
use Illuminate\Http\Request;

class HealthFoodItemController extends Controller
{
    public function index(Request $request)
    {
        $query = HealthFoodItem::query()
            ->where('is_active', true)
            ->where(function ($q) use ($request) {
                $q->whereNull('user_id')
                  ->orWhere('user_id', $request->user()->id);
            });

        if ($request->filled('search')) {
            $query->where('food_name', 'ILIKE', '%' . $request->search . '%');
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->boolean('ckd_friendly')) {
            $query->where('is_ckd_friendly', true);
        }

        $foods = $query->orderBy('food_name')->paginate(20);

        return HealthFoodItemResource::collection($foods);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'food_name' => ['required', 'string', 'max:255'],
            'brand_name' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],

            'calories_per_100g' => ['required', 'numeric', 'min:0'],
            'protein_per_100g' => ['required', 'numeric', 'min:0'],
            'carbs_per_100g' => ['required', 'numeric', 'min:0'],
            'fat_per_100g' => ['required', 'numeric', 'min:0'],

            'sodium_per_100g_mg' => ['required', 'numeric', 'min:0'],
            'potassium_per_100g_mg' => ['required', 'numeric', 'min:0'],
            'phosphorus_per_100g_mg' => ['required', 'numeric', 'min:0'],

            'is_ckd_friendly' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        $food = HealthFoodItem::create([
            ...$data,
            'user_id' => $request->user()->id,
            'is_custom' => true,
            'is_ckd_friendly' => $data['is_ckd_friendly'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Food item created successfully.',
            'data' => new HealthFoodItemResource($food),
        ], 201);
    }

    public function show(Request $request, HealthFoodItem $healthFoodItem)
    {
        abort_if(
            $healthFoodItem->user_id !== null && $healthFoodItem->user_id !== $request->user()->id,
            403
        );

        return new HealthFoodItemResource($healthFoodItem);
    }
}
HealthMealLogController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthMealLogResource;
use App\Models\HealthFoodItem;
use App\Models\HealthMealLog;
use App\Models\HealthMealLogItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class HealthMealLogController extends Controller
{
    public function index(Request $request)
    {
        $date = $request->query('date', now()->toDateString());

        $meals = HealthMealLog::with(['items.food'])
            ->where('user_id', $request->user()->id)
            ->whereDate('meal_date', $date)
            ->orderBy('created_at')
            ->get();

        return HealthMealLogResource::collection($meals);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'meal_date' => ['required', 'date'],
            'meal_type' => ['required', Rule::in(['breakfast', 'lunch', 'dinner', 'snack'])],
            'meal_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.food_item_id' => ['required', 'uuid', 'exists:health_food_items,id'],
            'items.*.quantity_g' => ['required', 'numeric', 'min:1'],
        ]);

        $meal = DB::transaction(function () use ($request, $data) {
            $meal = HealthMealLog::create([
                'user_id' => $request->user()->id,
                'meal_date' => $data['meal_date'],
                'meal_type' => $data['meal_type'],
                'meal_name' => $data['meal_name'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($data['items'] as $item) {
                $food = HealthFoodItem::where('id', $item['food_item_id'])
                    ->where(function ($q) use ($request) {
                        $q->whereNull('user_id')
                          ->orWhere('user_id', $request->user()->id);
                    })
                    ->firstOrFail();

                $calculated = $food->calculateForQuantity((float) $item['quantity_g']);

                HealthMealLogItem::create([
                    'meal_log_id' => $meal->id,
                    'food_item_id' => $food->id,
                    'quantity_g' => $item['quantity_g'],
                    ...$calculated,
                ]);
            }

            $meal->recalculateTotals();

            return $meal->fresh(['items.food']);
        });

        return response()->json([
            'success' => true,
            'message' => 'Meal logged successfully.',
            'data' => new HealthMealLogResource($meal),
        ], 201);
    }

    public function destroy(Request $request, HealthMealLog $healthMealLog)
    {
        abort_if($healthMealLog->user_id !== $request->user()->id, 403);

        $healthMealLog->delete();

        return response()->json([
            'success' => true,
            'message' => 'Meal deleted successfully.',
        ]);
    }
}
HealthNutritionSummaryController.php
<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMealLog;
use App\Models\HealthNutritionProfile;
use Illuminate\Http\Request;

class HealthNutritionSummaryController extends Controller
{
    public function daily(Request $request)
    {
        $date = $request->query('date', now()->toDateString());

        $summary = HealthMealLog::where('user_id', $request->user()->id)
            ->whereDate('meal_date', $date)
            ->selectRaw('
                COALESCE(SUM(total_calories), 0) as calories,
                COALESCE(SUM(total_protein_g), 0) as protein_g,
                COALESCE(SUM(total_carbs_g), 0) as carbs_g,
                COALESCE(SUM(total_fat_g), 0) as fat_g,
                COALESCE(SUM(total_sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(total_potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(total_phosphorus_mg), 0) as phosphorus_mg
            ')
            ->first();

        $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        $warnings = [];

        if ($profile) {
            $warnings = $this->buildWarnings($summary, $profile);
        }

        return response()->json([
            'success' => true,
            'date' => $date,
            'summary' => [
                'calories' => (float) $summary->calories,
                'protein_g' => (float) $summary->protein_g,
                'carbs_g' => (float) $summary->carbs_g,
                'fat_g' => (float) $summary->fat_g,
                'sodium_mg' => (float) $summary->sodium_mg,
                'potassium_mg' => (float) $summary->potassium_mg,
                'phosphorus_mg' => (float) $summary->phosphorus_mg,
            ],
            'profile' => $profile,
            'warnings' => $warnings,
        ]);
    }

    private function buildWarnings($summary, HealthNutritionProfile $profile): array
    {
        $warnings = [];

        $checks = [
            'protein_g' => ['value' => $summary->protein_g, 'limit' => $profile->daily_protein_max_g, 'label' => 'Protein'],
            'sodium_mg' => ['value' => $summary->sodium_mg, 'limit' => $profile->daily_sodium_max_mg, 'label' => 'Sodium'],
            'potassium_mg' => ['value' => $summary->potassium_mg, 'limit' => $profile->daily_potassium_max_mg, 'label' => 'Potassium'],
            'phosphorus_mg' => ['value' => $summary->phosphorus_mg, 'limit' => $profile->daily_phosphorus_max_mg, 'label' => 'Phosphorus'],
        ];

        foreach ($checks as $key => $check) {
            if (!$check['limit'] || $check['limit'] <= 0) {
                continue;
            }

            $percentage = ($check['value'] / $check['limit']) * 100;

            if ($percentage >= 100) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $check['label'],
                    'status' => 'exceeded',
                    'message' => "{$check['label']} limit exceeded.",
                    'percentage' => round($percentage, 2),
                ];
            } elseif ($percentage >= 80) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $check['label'],
                    'status' => 'warning',
                    'message' => "{$check['label']} is close to daily limit.",
                    'percentage' => round($percentage, 2),
                ];
            }
        }

        return $warnings;
    }
}
11. API Routes

Open:

nano routes/api.php

Add inside your authenticated API group:

use App\Http\Controllers\Api\V1\Health\HealthNutritionProfileController;
use App\Http\Controllers\Api\V1\Health\HealthFoodItemController;
use App\Http\Controllers\Api\V1\Health\HealthMealLogController;
use App\Http\Controllers\Api\V1\Health\HealthNutritionSummaryController;

Then inside:

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {

    Route::prefix('health/nutrition')->group(function () {
        Route::get('/profile', [HealthNutritionProfileController::class, 'index']);
        Route::post('/profile', [HealthNutritionProfileController::class, 'store']);

        Route::get('/foods', [HealthFoodItemController::class, 'index']);
        Route::post('/foods', [HealthFoodItemController::class, 'store']);
        Route::get('/foods/{healthFoodItem}', [HealthFoodItemController::class, 'show']);

        Route::get('/meals', [HealthMealLogController::class, 'index']);
        Route::post('/meals', [HealthMealLogController::class, 'store']);
        Route::delete('/meals/{healthMealLog}', [HealthMealLogController::class, 'destroy']);

        Route::get('/summary/daily', [HealthNutritionSummaryController::class, 'daily']);
    });

});
12. Test API
Create CKD Nutrition Profile
curl -X POST http://127.0.0.1:8000/api/v1/health/nutrition/profile \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "profile_name": "CKD Stage 4 Nutrition Profile",
    "daily_calories_min": 1600,
    "daily_calories_max": 1800,
    "daily_protein_max_g": 45,
    "daily_carbs_max_g": 220,
    "daily_fat_max_g": 60,
    "daily_sodium_max_mg": 2000,
    "daily_potassium_max_mg": 2000,
    "daily_phosphorus_max_mg": 800,
    "is_ckd_safe_mode": true,
    "notes": "Default CKD-safe profile. Values should be adjusted by doctor or dietitian."
  }'
Add Food Item
curl -X POST http://127.0.0.1:8000/api/v1/health/nutrition/foods \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "food_name": "Cooked White Rice",
    "category": "Carbohydrates",
    "calories_per_100g": 130,
    "protein_per_100g": 2.7,
    "carbs_per_100g": 28,
    "fat_per_100g": 0.3,
    "sodium_per_100g_mg": 1,
    "potassium_per_100g_mg": 35,
    "phosphorus_per_100g_mg": 43,
    "is_ckd_friendly": true,
    "notes": "Nutrition values are approximate."
  }'
List Foods
curl http://127.0.0.1:8000/api/v1/health/nutrition/foods \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"
Log Meal

Replace FOOD_UUID_HERE with the food ID from the previous response.

curl -X POST http://127.0.0.1:8000/api/v1/health/nutrition/meals \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108" \
  -d '{
    "meal_date": "2026-04-26",
    "meal_type": "lunch",
    "meal_name": "Rice Lunch",
    "items": [
      {
        "food_item_id": "019dc79e-849a-735c-989a-5a00f786a1b9",
        "quantity_g": 150
      }
    ],
    "notes": "First nutrition meal test"
  }'
Daily Summary
curl "http://127.0.0.1:8000/api/v1/health/nutrition/summary/daily?date=2026-04-26" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 10|sOYzZHarB8HyP8YKoi2AC6lkhoOAwZHEZYZvwaoGd3793108"

Expected response structure:

{
  "success": true,
  "date": "2026-04-26",
  "summary": {
    "calories": 195,
    "protein_g": 4.05,
    "carbs_g": 42,
    "fat_g": 0.45,
    "sodium_mg": 1.5,
    "potassium_mg": 52.5,
    "phosphorus_mg": 64.5
  },
  "warnings": []
}
13. Frontend Structure

Inside frontend:

cd /u01/nix-life-os/frontend

Create:

mkdir -p src/views/health/nutrition
touch src/views/health/nutrition/NutritionDashboardView.vue
touch src/views/health/nutrition/FoodItemsView.vue
touch src/views/health/nutrition/MealLoggerView.vue
14. Add Routes

Open:

nano src/router/index.js

Add imports:

import NutritionDashboardView from "@/views/health/nutrition/NutritionDashboardView.vue";
import FoodItemsView from "@/views/health/nutrition/FoodItemsView.vue";
import MealLoggerView from "@/views/health/nutrition/MealLoggerView.vue";

Add routes:

{
  path: "/health/nutrition",
  name: "health-nutrition",
  component: NutritionDashboardView,
},
{
  path: "/health/nutrition/foods",
  name: "health-nutrition-foods",
  component: FoodItemsView,
},
{
  path: "/health/nutrition/meals",
  name: "health-nutrition-meals",
  component: MealLoggerView,
},
15. Update App.vue

Use this layout:

<script setup>
import { RouterLink, RouterView } from "vue-router";
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <aside class="fixed left-0 top-0 h-full w-72 bg-white border-r border-gray-200 p-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-8">
        NIX LIFE OS
      </h1>

      <nav class="space-y-2">
        <RouterLink
          to="/health/weight"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Weight Tracking
        </RouterLink>

        <RouterLink
          to="/health/nutrition"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Nutrition Dashboard
        </RouterLink>

        <RouterLink
          to="/health/nutrition/meals"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Meal Logger
        </RouterLink>

        <RouterLink
          to="/health/nutrition/foods"
          class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Food Items
        </RouterLink>
      </nav>
    </aside>

    <main class="ml-72 p-8">
      <RouterView />
    </main>
  </div>
</template>
16. NutritionDashboardView.vue
<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "http://127.0.0.1:8000/api/v1";
const token = localStorage.getItem("token");

const selectedDate = ref(new Date().toISOString().substring(0, 10));
const summary = ref(null);
const warnings = ref([]);

async function loadSummary() {
  const response = await fetch(
    `${API_BASE}/health/nutrition/summary/daily?date=${selectedDate.value}`,
    {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  summary.value = data.summary;
  warnings.value = data.warnings || [];
}

onMounted(loadSummary);
</script>

<template>
  <div>
    <div class="mb-8 flex items-center justify-between">
      <div>
        <h2 class="text-3xl font-bold text-gray-900">Nutrition Dashboard</h2>
        <p class="text-gray-500 mt-1">
          Daily CKD-safe nutrient monitoring
        </p>
      </div>

      <input
        v-model="selectedDate"
        @change="loadSummary"
        type="date"
        class="rounded-xl border border-gray-300 px-4 py-2"
      />
    </div>

    <div v-if="summary" class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Calories</p>
        <h3 class="text-3xl font-bold">{{ summary.calories }}</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Protein</p>
        <h3 class="text-3xl font-bold">{{ summary.protein_g }}g</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Sodium</p>
        <h3 class="text-3xl font-bold">{{ summary.sodium_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Potassium</p>
        <h3 class="text-3xl font-bold">{{ summary.potassium_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Phosphorus</p>
        <h3 class="text-3xl font-bold">{{ summary.phosphorus_mg }}mg</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Carbs</p>
        <h3 class="text-3xl font-bold">{{ summary.carbs_g }}g</h3>
      </div>

      <div class="bg-white rounded-2xl shadow p-6">
        <p class="text-gray-500">Fat</p>
        <h3 class="text-3xl font-bold">{{ summary.fat_g }}g</h3>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow p-6">
      <h3 class="text-xl font-bold mb-4">CKD Safety Warnings</h3>

      <div v-if="warnings.length === 0" class="text-green-700 bg-green-50 p-4 rounded-xl">
        No nutrient limits exceeded for this day.
      </div>

      <div
        v-for="warning in warnings"
        :key="warning.nutrient"
        class="mb-3 rounded-xl p-4"
        :class="warning.status === 'exceeded' ? 'bg-red-50 text-red-700' : 'bg-yellow-50 text-yellow-700'"
      >
        <strong>{{ warning.label }}:</strong>
        {{ warning.message }}
        <span>({{ warning.percentage }}%)</span>
      </div>
    </div>
  </div>
</template>
17. FoodItemsView.vue
<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "http://127.0.0.1:8000/api/v1";
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
18. MealLoggerView.vue
<script setup>
import { ref, onMounted } from "vue";

const API_BASE = "http://127.0.0.1:8000/api/v1";
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
19. Verify Backend

Run:

php artisan route:list | grep nutrition

You should see:

GET       api/v1/health/nutrition/profile
POST      api/v1/health/nutrition/profile
GET       api/v1/health/nutrition/foods
POST      api/v1/health/nutrition/foods
GET       api/v1/health/nutrition/meals
POST      api/v1/health/nutrition/meals
DELETE    api/v1/health/nutrition/meals/{healthMealLog}
GET       api/v1/health/nutrition/summary/daily
20. Final Module Result

After this step, NIX LIFE OS will have:

STEP 10 — Health Nutrition Tracking Module
├── CKD nutrition profile
├── Food items database
├── Custom food creation
├── Meal logging
├── Automatic nutrient calculation
├── Calories tracking
├── Protein tracking
├── Carbs tracking
├── Fat tracking
├── Sodium tracking
├── Potassium tracking
├── Phosphorus tracking
├── Daily nutrition summary
├── CKD-safe warnings
└── Vue frontend screens

Important: the CKD limits should stay configurable because your doctor or renal dietitian may change your sodium, potassium, phosphorus, protein, and fluid targets based on your latest lab results.