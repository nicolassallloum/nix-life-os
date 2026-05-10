🔹 STEP 46 — Nutrition Facts Database Design & Implementation
Nix Life OS — Nutrition Facts Database + Food Search Autofill

You are now adding a Nutrition Facts Database that will support:

Nutrition Tracking screen autofill
CKD-friendly food recommendations
Sodium / potassium / phosphorus control
Food search by name/category
Serving size conversion
Future barcode / nutrition API integration
1. Database Design Overview
Main Tables
Table	Purpose
nutrition_food_categories	Stores food categories such as Fruits, Vegetables, Grains, Dairy
nutrition_foods	Main food master table
nutrition_food_servings	Stores serving sizes for each food
nutrition_food_aliases	Stores alternative names/search keywords
nutrition_food_sources	Optional table to track source of food data
health_nutrition_logs	Existing or future meal log table that can link to nutrition_foods
2. PostgreSQL Schema
2.1 Food Categories Table
CREATE TABLE IF NOT EXISTS nutrition_food_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(150) NOT NULL UNIQUE,
    slug VARCHAR(180) NOT NULL UNIQUE,
    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);
2.2 Food Master Table
CREATE TABLE IF NOT EXISTS nutrition_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    category_id UUID NULL REFERENCES nutrition_food_categories(id) ON DELETE SET NULL,

    food_code VARCHAR(100) UNIQUE,
    name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255),
    description TEXT,

    default_serving_label VARCHAR(100) DEFAULT '100 g',
    default_serving_grams NUMERIC(10,2) DEFAULT 100,

    calories NUMERIC(10,2) NOT NULL DEFAULT 0,
    protein_g NUMERIC(10,2) NOT NULL DEFAULT 0,
    carbs_g NUMERIC(10,2) NOT NULL DEFAULT 0,
    fat_g NUMERIC(10,2) NOT NULL DEFAULT 0,
    fiber_g NUMERIC(10,2) DEFAULT 0,
    sugar_g NUMERIC(10,2) DEFAULT 0,

    sodium_mg NUMERIC(10,2) DEFAULT 0,
    potassium_mg NUMERIC(10,2) DEFAULT 0,
    phosphorus_mg NUMERIC(10,2) DEFAULT 0,

    calcium_mg NUMERIC(10,2) DEFAULT 0,
    iron_mg NUMERIC(10,2) DEFAULT 0,
    cholesterol_mg NUMERIC(10,2) DEFAULT 0,

    is_ckd_friendly BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_sodium BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_potassium BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_phosphorus BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_protein BOOLEAN NOT NULL DEFAULT FALSE,

    ckd_warning_level VARCHAR(30) NOT NULL DEFAULT 'medium',
    ckd_notes TEXT,

    source VARCHAR(100) DEFAULT 'manual',
    source_reference TEXT,

    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,

    CONSTRAINT chk_nutrition_foods_ckd_warning_level
        CHECK (ckd_warning_level IN ('low', 'medium', 'high', 'avoid')),

    CONSTRAINT chk_nutrition_foods_default_serving_grams
        CHECK (default_serving_grams > 0),

    CONSTRAINT chk_nutrition_foods_macros_non_negative
        CHECK (
            calories >= 0
            AND protein_g >= 0
            AND carbs_g >= 0
            AND fat_g >= 0
            AND sodium_mg >= 0
            AND potassium_mg >= 0
            AND phosphorus_mg >= 0
        )
);
2.3 Serving Size Table
CREATE TABLE IF NOT EXISTS nutrition_food_servings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    food_id UUID NOT NULL REFERENCES nutrition_foods(id) ON DELETE CASCADE,

    serving_label VARCHAR(150) NOT NULL,
    serving_grams NUMERIC(10,2) NOT NULL,

    calories NUMERIC(10,2),
    protein_g NUMERIC(10,2),
    carbs_g NUMERIC(10,2),
    fat_g NUMERIC(10,2),

    sodium_mg NUMERIC(10,2),
    potassium_mg NUMERIC(10,2),
    phosphorus_mg NUMERIC(10,2),

    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    display_order INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_nutrition_food_servings_grams
        CHECK (serving_grams > 0)
);
2.4 Food Aliases Table

This helps search for foods using local names or alternative spellings.

Examples:

zucchini
kousa
courgette
rice
riz
chicken breast
breast chicken
CREATE TABLE IF NOT EXISTS nutrition_food_aliases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    food_id UUID NOT NULL REFERENCES nutrition_foods(id) ON DELETE CASCADE,

    alias_name VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) DEFAULT 'en',

    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_nutrition_food_alias
        UNIQUE (food_id, alias_name)
);
2.5 Food Sources Table

Optional but useful for future integrations.

CREATE TABLE IF NOT EXISTS nutrition_food_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    food_id UUID NOT NULL REFERENCES nutrition_foods(id) ON DELETE CASCADE,

    source_name VARCHAR(150) NOT NULL,
    source_food_id VARCHAR(150),
    source_url TEXT,

    imported_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,

    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);
3. Search Indexes
3.1 Required PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
3.2 Indexes
CREATE INDEX IF NOT EXISTS idx_nutrition_foods_category_id
ON nutrition_foods(category_id);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_active
ON nutrition_foods(is_active);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_ckd_friendly
ON nutrition_foods(is_ckd_friendly);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_sodium
ON nutrition_foods(is_low_sodium);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_potassium
ON nutrition_foods(is_low_potassium);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_phosphorus
ON nutrition_foods(is_low_phosphorus);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_warning_level
ON nutrition_foods(ckd_warning_level);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_name_trgm
ON nutrition_foods
USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_nutrition_foods_brand_trgm
ON nutrition_foods
USING gin (brand_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_nutrition_food_aliases_alias_trgm
ON nutrition_food_aliases
USING gin (alias_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_nutrition_food_servings_food_id
ON nutrition_food_servings(food_id);
4. Laravel Migration Files
4.1 Create Migration
cd /u01/nix-life-os/backend

php artisan make:migration create_nutrition_food_categories_table
php artisan make:migration create_nutrition_foods_table
php artisan make:migration create_nutrition_food_servings_table
php artisan make:migration create_nutrition_food_aliases_table
php artisan make:migration create_nutrition_food_sources_table
4.2 Migration: Food Categories

File:

database/migrations/xxxx_xx_xx_xxxxxx_create_nutrition_food_categories_table.php

Code:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_food_categories', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('name', 150)->unique();
            $table->string('slug', 180)->unique();
            $table->text('description')->nullable();

            $table->boolean('is_active')->default(true);

            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_food_categories');
    }
};
4.3 Migration: Foods
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_foods', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('category_id')->nullable();

            $table->string('food_code', 100)->nullable()->unique();
            $table->string('name', 255);
            $table->string('brand_name', 255)->nullable();
            $table->text('description')->nullable();

            $table->string('default_serving_label', 100)->default('100 g');
            $table->decimal('default_serving_grams', 10, 2)->default(100);

            $table->decimal('calories', 10, 2)->default(0);
            $table->decimal('protein_g', 10, 2)->default(0);
            $table->decimal('carbs_g', 10, 2)->default(0);
            $table->decimal('fat_g', 10, 2)->default(0);
            $table->decimal('fiber_g', 10, 2)->default(0);
            $table->decimal('sugar_g', 10, 2)->default(0);

            $table->decimal('sodium_mg', 10, 2)->default(0);
            $table->decimal('potassium_mg', 10, 2)->default(0);
            $table->decimal('phosphorus_mg', 10, 2)->default(0);

            $table->decimal('calcium_mg', 10, 2)->default(0);
            $table->decimal('iron_mg', 10, 2)->default(0);
            $table->decimal('cholesterol_mg', 10, 2)->default(0);

            $table->boolean('is_ckd_friendly')->default(false);
            $table->boolean('is_low_sodium')->default(false);
            $table->boolean('is_low_potassium')->default(false);
            $table->boolean('is_low_phosphorus')->default(false);
            $table->boolean('is_low_protein')->default(false);

            $table->string('ckd_warning_level', 30)->default('medium');
            $table->text('ckd_notes')->nullable();

            $table->string('source', 100)->default('manual');
            $table->text('source_reference')->nullable();

            $table->boolean('is_verified')->default(false);
            $table->boolean('is_active')->default(true);

            $table->timestamps();
            $table->softDeletes();

            $table->foreign('category_id')
                ->references('id')
                ->on('nutrition_food_categories')
                ->nullOnDelete();
        });

        DB::statement("
            ALTER TABLE nutrition_foods
            ADD CONSTRAINT chk_nutrition_foods_ckd_warning_level
            CHECK (ckd_warning_level IN ('low', 'medium', 'high', 'avoid'))
        ");

        DB::statement("
            ALTER TABLE nutrition_foods
            ADD CONSTRAINT chk_nutrition_foods_default_serving_grams
            CHECK (default_serving_grams > 0)
        ");

        DB::statement("
            ALTER TABLE nutrition_foods
            ADD CONSTRAINT chk_nutrition_foods_values_non_negative
            CHECK (
                calories >= 0
                AND protein_g >= 0
                AND carbs_g >= 0
                AND fat_g >= 0
                AND sodium_mg >= 0
                AND potassium_mg >= 0
                AND phosphorus_mg >= 0
            )
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_foods');
    }
};
4.4 Migration: Food Servings
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_food_servings', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('food_id');

            $table->string('serving_label', 150);
            $table->decimal('serving_grams', 10, 2);

            $table->decimal('calories', 10, 2)->nullable();
            $table->decimal('protein_g', 10, 2)->nullable();
            $table->decimal('carbs_g', 10, 2)->nullable();
            $table->decimal('fat_g', 10, 2)->nullable();

            $table->decimal('sodium_mg', 10, 2)->nullable();
            $table->decimal('potassium_mg', 10, 2)->nullable();
            $table->decimal('phosphorus_mg', 10, 2)->nullable();

            $table->boolean('is_default')->default(false);
            $table->integer('display_order')->default(1);

            $table->timestamps();

            $table->foreign('food_id')
                ->references('id')
                ->on('nutrition_foods')
                ->cascadeOnDelete();
        });

        DB::statement("
            ALTER TABLE nutrition_food_servings
            ADD CONSTRAINT chk_nutrition_food_servings_grams
            CHECK (serving_grams > 0)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_food_servings');
    }
};
4.5 Migration: Food Aliases
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_food_aliases', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('food_id');

            $table->string('alias_name', 255);
            $table->string('language_code', 10)->default('en');

            $table->timestamps();

            $table->foreign('food_id')
                ->references('id')
                ->on('nutrition_foods')
                ->cascadeOnDelete();

            $table->unique(['food_id', 'alias_name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_food_aliases');
    }
};
4.6 Migration: Food Sources
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_food_sources', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('food_id');

            $table->string('source_name', 150);
            $table->string('source_food_id', 150)->nullable();
            $table->text('source_url')->nullable();

            $table->timestamp('imported_at')->nullable();

            $table->timestamps();

            $table->foreign('food_id')
                ->references('id')
                ->on('nutrition_foods')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_food_sources');
    }
};
5. Migration for Search Indexes

Create:

php artisan make:migration add_indexes_to_nutrition_foods_tables

Code:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS pg_trgm');

        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_category_id ON nutrition_foods(category_id)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_active ON nutrition_foods(is_active)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_ckd_friendly ON nutrition_foods(is_ckd_friendly)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_sodium ON nutrition_foods(is_low_sodium)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_potassium ON nutrition_foods(is_low_potassium)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_low_phosphorus ON nutrition_foods(is_low_phosphorus)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_warning_level ON nutrition_foods(ckd_warning_level)');

        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_name_trgm ON nutrition_foods USING gin (name gin_trgm_ops)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_foods_brand_trgm ON nutrition_foods USING gin (brand_name gin_trgm_ops)');
        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_food_aliases_alias_trgm ON nutrition_food_aliases USING gin (alias_name gin_trgm_ops)');

        DB::statement('CREATE INDEX IF NOT EXISTS idx_nutrition_food_servings_food_id ON nutrition_food_servings(food_id)');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_category_id');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_active');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_ckd_friendly');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_low_sodium');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_low_potassium');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_low_phosphorus');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_warning_level');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_name_trgm');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_foods_brand_trgm');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_food_aliases_alias_trgm');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_food_servings_food_id');
    }
};
6. Laravel Models

Create:

php artisan make:model NutritionFoodCategory
php artisan make:model NutritionFood
php artisan make:model NutritionFoodServing
php artisan make:model NutritionFoodAlias
php artisan make:model NutritionFoodSource
6.1 NutritionFoodCategory.php

Path:

app/Models/NutritionFoodCategory.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodCategory extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_food_categories';

    protected $fillable = [
        'name',
        'slug',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function foods()
    {
        return $this->hasMany(NutritionFood::class, 'category_id');
    }
}
6.2 NutritionFood.php

Path:

app/Models/NutritionFood.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFood extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_foods';

    protected $fillable = [
        'category_id',
        'food_code',
        'name',
        'brand_name',
        'description',
        'default_serving_label',
        'default_serving_grams',

        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'fiber_g',
        'sugar_g',

        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
        'calcium_mg',
        'iron_mg',
        'cholesterol_mg',

        'is_ckd_friendly',
        'is_low_sodium',
        'is_low_potassium',
        'is_low_phosphorus',
        'is_low_protein',

        'ckd_warning_level',
        'ckd_notes',

        'source',
        'source_reference',
        'is_verified',
        'is_active',
    ];

    protected $casts = [
        'default_serving_grams' => 'decimal:2',

        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'fiber_g' => 'decimal:2',
        'sugar_g' => 'decimal:2',

        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',
        'calcium_mg' => 'decimal:2',
        'iron_mg' => 'decimal:2',
        'cholesterol_mg' => 'decimal:2',

        'is_ckd_friendly' => 'boolean',
        'is_low_sodium' => 'boolean',
        'is_low_potassium' => 'boolean',
        'is_low_phosphorus' => 'boolean',
        'is_low_protein' => 'boolean',
        'is_verified' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function category()
    {
        return $this->belongsTo(NutritionFoodCategory::class, 'category_id');
    }

    public function servings()
    {
        return $this->hasMany(NutritionFoodServing::class, 'food_id');
    }

    public function aliases()
    {
        return $this->hasMany(NutritionFoodAlias::class, 'food_id');
    }

    public function sources()
    {
        return $this->hasMany(NutritionFoodSource::class, 'food_id');
    }
}
6.3 NutritionFoodServing.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodServing extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_servings';

    protected $fillable = [
        'food_id',
        'serving_label',
        'serving_grams',

        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',

        'is_default',
        'display_order',
    ];

    protected $casts = [
        'serving_grams' => 'decimal:2',

        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',

        'is_default' => 'boolean',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
6.4 NutritionFoodAlias.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodAlias extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_aliases';

    protected $fillable = [
        'food_id',
        'alias_name',
        'language_code',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
6.5 NutritionFoodSource.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodSource extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_sources';

    protected $fillable = [
        'food_id',
        'source_name',
        'source_food_id',
        'source_url',
        'imported_at',
    ];

    protected $casts = [
        'imported_at' => 'datetime',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
7. Seed Data

Create seeder:

php artisan make:seeder NutritionFoodDatabaseSeeder

Path:

database/seeders/NutritionFoodDatabaseSeeder.php

Code:

<?php

namespace Database\Seeders;

use App\Models\NutritionFood;
use App\Models\NutritionFoodAlias;
use App\Models\NutritionFoodCategory;
use App\Models\NutritionFoodServing;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class NutritionFoodDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            'Fruits',
            'Vegetables',
            'Grains',
            'Protein',
            'Dairy',
            'Legumes',
            'Beverages',
            'Prepared Meals',
        ];

        $categoryMap = [];

        foreach ($categories as $categoryName) {
            $category = NutritionFoodCategory::updateOrCreate(
                ['slug' => Str::slug($categoryName)],
                [
                    'name' => $categoryName,
                    'description' => $categoryName . ' category',
                    'is_active' => true,
                ]
            );

            $categoryMap[$categoryName] = $category->id;
        }

        $foods = [
            [
                'category' => 'Protein',
                'food_code' => 'FOOD-CHICKEN-BREAST-100G',
                'name' => 'Chicken Breast, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 165,
                'protein_g' => 31,
                'carbs_g' => 0,
                'fat_g' => 3.6,
                'sodium_mg' => 74,
                'potassium_mg' => 256,
                'phosphorus_mg' => 228,
                'is_ckd_friendly' => false,
                'is_low_sodium' => true,
                'is_low_potassium' => false,
                'is_low_phosphorus' => false,
                'is_low_protein' => false,
                'ckd_warning_level' => 'medium',
                'ckd_notes' => 'High protein and phosphorus. Use limited quantity for CKD diet.',
                'aliases' => ['chicken', 'chicken breast', 'grilled chicken'],
                'servings' => [
                    ['serving_label' => '50 g', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                    ['serving_label' => '1 small piece', 'serving_grams' => 75],
                ],
            ],
            [
                'category' => 'Grains',
                'food_code' => 'FOOD-WHITE-RICE-100G',
                'name' => 'White Rice, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 130,
                'protein_g' => 2.7,
                'carbs_g' => 28,
                'fat_g' => 0.3,
                'sodium_mg' => 1,
                'potassium_mg' => 35,
                'phosphorus_mg' => 43,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'Generally CKD-friendly when portion is controlled.',
                'aliases' => ['rice', 'white rice', 'riz'],
                'servings' => [
                    ['serving_label' => '1/2 cup cooked', 'serving_grams' => 80],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                    ['serving_label' => '1 cup cooked', 'serving_grams' => 160],
                ],
            ],
            [
                'category' => 'Vegetables',
                'food_code' => 'FOOD-CUCUMBER-100G',
                'name' => 'Cucumber, Raw',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 15,
                'protein_g' => 0.7,
                'carbs_g' => 3.6,
                'fat_g' => 0.1,
                'sodium_mg' => 2,
                'potassium_mg' => 147,
                'phosphorus_mg' => 24,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'Good low-calorie CKD-friendly vegetable.',
                'aliases' => ['cucumber', 'khiyar', 'خيار'],
                'servings' => [
                    ['serving_label' => '1/2 cucumber', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
            [
                'category' => 'Fruits',
                'food_code' => 'FOOD-APPLE-100G',
                'name' => 'Apple, Raw',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 52,
                'protein_g' => 0.3,
                'carbs_g' => 14,
                'fat_g' => 0.2,
                'sodium_mg' => 1,
                'potassium_mg' => 107,
                'phosphorus_mg' => 11,
                'is_ckd_friendly' => true,
                'is_low_sodium' => true,
                'is_low_potassium' => true,
                'is_low_phosphorus' => true,
                'is_low_protein' => true,
                'ckd_warning_level' => 'low',
                'ckd_notes' => 'CKD-friendly fruit when portion is controlled.',
                'aliases' => ['apple', 'تفاح'],
                'servings' => [
                    ['serving_label' => '1 small apple', 'serving_grams' => 120],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
            [
                'category' => 'Legumes',
                'food_code' => 'FOOD-LENTILS-100G',
                'name' => 'Lentils, Cooked',
                'default_serving_label' => '100 g',
                'default_serving_grams' => 100,
                'calories' => 116,
                'protein_g' => 9,
                'carbs_g' => 20,
                'fat_g' => 0.4,
                'sodium_mg' => 2,
                'potassium_mg' => 369,
                'phosphorus_mg' => 180,
                'is_ckd_friendly' => false,
                'is_low_sodium' => true,
                'is_low_potassium' => false,
                'is_low_phosphorus' => false,
                'is_low_protein' => false,
                'ckd_warning_level' => 'high',
                'ckd_notes' => 'High potassium and phosphorus. Use only if approved by dietitian.',
                'aliases' => ['lentils', 'adas', 'عدس'],
                'servings' => [
                    ['serving_label' => '1/4 cup cooked', 'serving_grams' => 50],
                    ['serving_label' => '100 g', 'serving_grams' => 100],
                ],
            ],
        ];

        foreach ($foods as $item) {
            $food = NutritionFood::updateOrCreate(
                ['food_code' => $item['food_code']],
                [
                    'category_id' => $categoryMap[$item['category']],
                    'name' => $item['name'],
                    'default_serving_label' => $item['default_serving_label'],
                    'default_serving_grams' => $item['default_serving_grams'],

                    'calories' => $item['calories'],
                    'protein_g' => $item['protein_g'],
                    'carbs_g' => $item['carbs_g'],
                    'fat_g' => $item['fat_g'],

                    'sodium_mg' => $item['sodium_mg'],
                    'potassium_mg' => $item['potassium_mg'],
                    'phosphorus_mg' => $item['phosphorus_mg'],

                    'is_ckd_friendly' => $item['is_ckd_friendly'],
                    'is_low_sodium' => $item['is_low_sodium'],
                    'is_low_potassium' => $item['is_low_potassium'],
                    'is_low_phosphorus' => $item['is_low_phosphorus'],
                    'is_low_protein' => $item['is_low_protein'],

                    'ckd_warning_level' => $item['ckd_warning_level'],
                    'ckd_notes' => $item['ckd_notes'],
                    'source' => 'manual',
                    'is_verified' => true,
                    'is_active' => true,
                ]
            );

            foreach ($item['aliases'] as $alias) {
                NutritionFoodAlias::updateOrCreate(
                    [
                        'food_id' => $food->id,
                        'alias_name' => $alias,
                    ],
                    [
                        'language_code' => 'en',
                    ]
                );
            }

            foreach ($item['servings'] as $index => $serving) {
                $ratio = $serving['serving_grams'] / $item['default_serving_grams'];

                NutritionFoodServing::updateOrCreate(
                    [
                        'food_id' => $food->id,
                        'serving_label' => $serving['serving_label'],
                    ],
                    [
                        'serving_grams' => $serving['serving_grams'],

                        'calories' => round($item['calories'] * $ratio, 2),
                        'protein_g' => round($item['protein_g'] * $ratio, 2),
                        'carbs_g' => round($item['carbs_g'] * $ratio, 2),
                        'fat_g' => round($item['fat_g'] * $ratio, 2),

                        'sodium_mg' => round($item['sodium_mg'] * $ratio, 2),
                        'potassium_mg' => round($item['potassium_mg'] * $ratio, 2),
                        'phosphorus_mg' => round($item['phosphorus_mg'] * $ratio, 2),

                        'is_default' => $serving['serving_grams'] == $item['default_serving_grams'],
                        'display_order' => $index + 1,
                    ]
                );
            }
        }
    }
}
7.1 Register Seeder

In:

database/seeders/DatabaseSeeder.php

Add:

$this->call([
    NutritionFoodDatabaseSeeder::class,
]);

Then run:

php artisan db:seed --class=NutritionFoodDatabaseSeeder
8. API Design
8.1 Endpoints
Method	Endpoint	Purpose
GET	/api/v1/nutrition/foods	List foods
GET	/api/v1/nutrition/foods/search?q=rice	Search foods
GET	/api/v1/nutrition/foods/{id}	Get food details
GET	/api/v1/nutrition/foods/{id}/servings	Get serving sizes
GET	/api/v1/nutrition/categories	Get food categories
POST	/api/v1/nutrition/foods/autofill	Calculate nutrition values by serving
9. Laravel Service

Create:

mkdir -p app/Services/Nutrition
nano app/Services/Nutrition/NutritionFoodService.php

Code:

<?php

namespace App\Services\Nutrition;

use App\Models\NutritionFood;
use App\Models\NutritionFoodCategory;
use Illuminate\Support\Facades\DB;

class NutritionFoodService
{
    public function categories()
    {
        return NutritionFoodCategory::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    public function search(array $filters)
    {
        $query = NutritionFood::query()
            ->with(['category', 'servings'])
            ->where('nutrition_foods.is_active', true);

        if (!empty($filters['q'])) {
            $search = trim($filters['q']);

            $query->where(function ($q) use ($search) {
                $q->where('nutrition_foods.name', 'ILIKE', "%{$search}%")
                    ->orWhere('nutrition_foods.brand_name', 'ILIKE', "%{$search}%")
                    ->orWhereExists(function ($sub) use ($search) {
                        $sub->select(DB::raw(1))
                            ->from('nutrition_food_aliases')
                            ->whereColumn('nutrition_food_aliases.food_id', 'nutrition_foods.id')
                            ->where('nutrition_food_aliases.alias_name', 'ILIKE', "%{$search}%");
                    });
            });
        }

        if (!empty($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }

        if (isset($filters['ckd_friendly'])) {
            $query->where('is_ckd_friendly', filter_var($filters['ckd_friendly'], FILTER_VALIDATE_BOOLEAN));
        }

        if (!empty($filters['warning_level'])) {
            $query->where('ckd_warning_level', $filters['warning_level']);
        }

        return $query
            ->orderBy('is_ckd_friendly', 'desc')
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 15);
    }

    public function findFood(string $id): NutritionFood
    {
        return NutritionFood::query()
            ->with(['category', 'servings', 'aliases'])
            ->where('is_active', true)
            ->findOrFail($id);
    }

    public function calculateAutofill(string $foodId, float $quantityGrams): array
    {
        $food = $this->findFood($foodId);

        $baseGrams = (float) $food->default_serving_grams;

        if ($baseGrams <= 0) {
            $baseGrams = 100;
        }

        $ratio = $quantityGrams / $baseGrams;

        return [
            'food_id' => $food->id,
            'food_name' => $food->name,
            'quantity_grams' => round($quantityGrams, 2),

            'calories' => round((float) $food->calories * $ratio, 2),
            'protein_g' => round((float) $food->protein_g * $ratio, 2),
            'carbs_g' => round((float) $food->carbs_g * $ratio, 2),
            'fat_g' => round((float) $food->fat_g * $ratio, 2),

            'sodium_mg' => round((float) $food->sodium_mg * $ratio, 2),
            'potassium_mg' => round((float) $food->potassium_mg * $ratio, 2),
            'phosphorus_mg' => round((float) $food->phosphorus_mg * $ratio, 2),

            'is_ckd_friendly' => $food->is_ckd_friendly,
            'ckd_warning_level' => $food->ckd_warning_level,
            'ckd_notes' => $food->ckd_notes,
        ];
    }
}
10. Laravel Controller

Create:

php artisan make:controller Api/V1/NutritionFoodController

Path:

app/Http/Controllers/Api/V1/NutritionFoodController.php

Code:

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Nutrition\NutritionFoodService;
use Illuminate\Http\Request;

class NutritionFoodController extends Controller
{
    public function __construct(
        private readonly NutritionFoodService $nutritionFoodService
    ) {}

    public function categories()
    {
        return response()->json([
            'success' => true,
            'message' => 'Nutrition food categories loaded successfully.',
            'data' => $this->nutritionFoodService->categories(),
        ]);
    }

    public function index(Request $request)
    {
        $foods = $this->nutritionFoodService->search($request->only([
            'q',
            'category_id',
            'ckd_friendly',
            'warning_level',
            'per_page',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Nutrition foods loaded successfully.',
            'data' => $foods,
        ]);
    }

    public function search(Request $request)
    {
        $request->validate([
            'q' => ['nullable', 'string', 'max:255'],
            'category_id' => ['nullable', 'uuid'],
            'ckd_friendly' => ['nullable'],
            'warning_level' => ['nullable', 'in:low,medium,high,avoid'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $foods = $this->nutritionFoodService->search($request->only([
            'q',
            'category_id',
            'ckd_friendly',
            'warning_level',
            'per_page',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Food search completed successfully.',
            'data' => $foods,
        ]);
    }

    public function show(string $id)
    {
        $food = $this->nutritionFoodService->findFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition food loaded successfully.',
            'data' => $food,
        ]);
    }

    public function servings(string $id)
    {
        $food = $this->nutritionFoodService->findFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Food servings loaded successfully.',
            'data' => $food->servings,
        ]);
    }

    public function autofill(Request $request)
    {
        $validated = $request->validate([
            'food_id' => ['required', 'uuid', 'exists:nutrition_foods,id'],
            'quantity_grams' => ['required', 'numeric', 'min:1', 'max:5000'],
        ]);

        $result = $this->nutritionFoodService->calculateAutofill(
            $validated['food_id'],
            (float) $validated['quantity_grams']
        );

        return response()->json([
            'success' => true,
            'message' => 'Nutrition autofill calculated successfully.',
            'data' => $result,
        ]);
    }
}
11. API Routes

Open:

nano routes/api.php

Add inside your api/v1 route group:

use App\Http\Controllers\Api\V1\NutritionFoodController;

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::prefix('nutrition')->group(function () {
        Route::get('/categories', [NutritionFoodController::class, 'categories']);

        Route::get('/foods', [NutritionFoodController::class, 'index']);
        Route::get('/foods/search', [NutritionFoodController::class, 'search']);
        Route::get('/foods/{id}', [NutritionFoodController::class, 'show']);
        Route::get('/foods/{id}/servings', [NutritionFoodController::class, 'servings']);

        Route::post('/foods/autofill', [NutritionFoodController::class, 'autofill']);
    });
});

If you already have this structure:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // existing routes
});

Then add only this inside it:

Route::prefix('nutrition')->group(function () {
    Route::get('/categories', [NutritionFoodController::class, 'categories']);

    Route::get('/foods', [NutritionFoodController::class, 'index']);
    Route::get('/foods/search', [NutritionFoodController::class, 'search']);
    Route::get('/foods/{id}', [NutritionFoodController::class, 'show']);
    Route::get('/foods/{id}/servings', [NutritionFoodController::class, 'servings']);

    Route::post('/foods/autofill', [NutritionFoodController::class, 'autofill']);
});
12. Run Migration and Seeder
cd /u01/nix-life-os/backend

php artisan optimize:clear
php artisan migrate
php artisan db:seed --class=NutritionFoodDatabaseSeeder
php artisan route:list | grep nutrition

Expected routes:

GET|HEAD  api/v1/nutrition/categories
GET|HEAD  api/v1/nutrition/foods
GET|HEAD  api/v1/nutrition/foods/search
GET|HEAD  api/v1/nutrition/foods/{id}
GET|HEAD  api/v1/nutrition/foods/{id}/servings
POST      api/v1/nutrition/foods/autofill
13. CURL Testing Commands
13.1 Login
cd /u01/nix-life-os/backend

curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-d '{
  "email": "test@nixlifeos.com",
  "password": "password"
}' | jq

Export token:

export TOKEN="PASTE_TOKEN_HERE"
13.2 Test Categories
curl -i "http://127.0.0.1:8000/api/v1/nutrition/categories" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Nutrition food categories loaded successfully.",
  "data": [
    {
      "id": "...",
      "name": "Fruits",
      "slug": "fruits"
    }
  ]
}
13.3 Test Food List
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Nutrition foods loaded successfully.",
  "data": {
    "data": [
      {
        "name": "White Rice, Cooked",
        "calories": "130.00",
        "protein_g": "2.70",
        "sodium_mg": "1.00",
        "potassium_mg": "35.00",
        "phosphorus_mg": "43.00",
        "is_ckd_friendly": true
      }
    ]
  }
}
13.4 Search Rice
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/search?q=rice" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected food:

"White Rice, Cooked"
13.5 Search CKD-Friendly Foods
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/search?ckd_friendly=true" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected:

{
  "success": true,
  "message": "Food search completed successfully."
}
13.6 Search High Warning Foods
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/search?warning_level=high" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"

Expected result should include:

"Lentils, Cooked"
13.7 Get Food ID
export FOOD_ID=$(curl -s "http://127.0.0.1:8000/api/v1/nutrition/foods/search?q=rice" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN" | jq -r '.data.data[0].id')

echo $FOOD_ID
13.8 Get Food Details
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/$FOOD_ID" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
13.9 Get Serving Sizes
curl -i "http://127.0.0.1:8000/api/v1/nutrition/foods/$FOOD_ID/servings" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
13.10 Autofill Nutrition Values
curl -i -X POST "http://127.0.0.1:8000/api/v1/nutrition/foods/autofill" \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d "{
  \"food_id\": \"$FOOD_ID\",
  \"quantity_grams\": 160
}"

Expected for cooked white rice, 160g:

{
  "success": true,
  "message": "Nutrition autofill calculated successfully.",
  "data": {
    "food_name": "White Rice, Cooked",
    "quantity_grams": 160,
    "calories": 208,
    "protein_g": 4.32,
    "carbs_g": 44.8,
    "fat_g": 0.48,
    "sodium_mg": 1.6,
    "potassium_mg": 56,
    "phosphorus_mg": 68.8,
    "is_ckd_friendly": true,
    "ckd_warning_level": "low"
  }
}
14. PostgreSQL Validation Queries

Enter PostgreSQL:

docker exec -it nixlifeos-postgres psql -U postgres -d nix_life_os

Or use your DB credentials.

14.1 Check Tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'nutrition_food%'
ORDER BY table_name;

Expected:

nutrition_food_aliases
nutrition_food_categories
nutrition_food_servings
nutrition_food_sources
nutrition_foods
14.2 Count Seeded Foods
SELECT COUNT(*) FROM nutrition_foods;

Expected:

5
14.3 View Foods
SELECT
    name,
    calories,
    protein_g,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    is_ckd_friendly,
    ckd_warning_level
FROM nutrition_foods
ORDER BY name;
14.4 CKD-Friendly Foods
SELECT
    name,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    ckd_warning_level
FROM nutrition_foods
WHERE is_ckd_friendly = true
ORDER BY name;
14.5 High-Risk Foods
SELECT
    name,
    sodium_mg,
    potassium_mg,
    phosphorus_mg,
    ckd_notes
FROM nutrition_foods
WHERE ckd_warning_level IN ('high', 'avoid')
ORDER BY name;
14.6 Search Index Test
EXPLAIN ANALYZE
SELECT *
FROM nutrition_foods
WHERE name ILIKE '%rice%';
15. Vue Frontend Integration Idea

In your Nutrition Tracking page, add:

Food Search Field
Search Food: rice

When user selects a food:

Call:
GET /api/v1/nutrition/foods/search?q=rice
Display dropdown:
White Rice, Cooked — 130 kcal / 100g
User enters quantity:
160 g
Call:
POST /api/v1/nutrition/foods/autofill
Auto-fill meal form:
Calories: 208
Protein: 4.32 g
Carbs: 44.8 g
Fat: 0.48 g
Sodium: 1.6 mg
Potassium: 56 mg
Phosphorus: 68.8 mg
16. Recommended Vue Service

Path:

/u01/nix-life-os/frontend/src/services/nutritionFoodService.js

Code:

import api from "./api";

export default {
  getCategories() {
    return api.get("/nutrition/categories");
  },

  getFoods(params = {}) {
    return api.get("/nutrition/foods", { params });
  },

  searchFoods(params = {}) {
    return api.get("/nutrition/foods/search", { params });
  },

  getFood(id) {
    return api.get(`/nutrition/foods/${id}`);
  },

  getFoodServings(id) {
    return api.get(`/nutrition/foods/${id}/servings`);
  },

  autofillFood(payload) {
    return api.post("/nutrition/foods/autofill", payload);
  },
};
17. Common Problems and Fixes
Problem 1 — gen_random_uuid() does not exist

Fix:

CREATE EXTENSION IF NOT EXISTS pgcrypto;

Or in Laravel migration:

DB::statement('CREATE EXTENSION IF NOT EXISTS pgcrypto');
Problem 2 — UUID columns not auto-generating

Because Laravel $table->uuid('id')->primary() does not automatically add DB default.

Use model trait:

use Illuminate\Database\Eloquent\Concerns\HasUuids;

This is already included in the models above.

Problem 3 — API route returns 404

Run:

php artisan route:list | grep nutrition
php artisan optimize:clear

Also check that route is inside:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    //
});
Problem 4 — API returns 401 Unauthorized

Login again and export token:

export TOKEN="PASTE_TOKEN_HERE"

Then test:

curl -i "http://127.0.0.1:8000/api/v1/auth/me" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TOKEN"
Problem 5 — Search is slow

Confirm indexes:

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename IN (
    'nutrition_foods',
    'nutrition_food_aliases',
    'nutrition_food_servings'
)
ORDER BY tablename, indexname;
18. Final Validation Checklist
Check	Status
Food category table created	⬜
Food master table created	⬜
Serving size table created	⬜
Food alias table created	⬜
Food source table created	⬜
CKD flags added	⬜
Sodium/potassium/phosphorus fields added	⬜
Search indexes created	⬜
Seed data inserted	⬜
/api/v1/nutrition/categories works	⬜
/api/v1/nutrition/foods works	⬜
/api/v1/nutrition/foods/search?q=rice works	⬜
/api/v1/nutrition/foods/{id} works	⬜
/api/v1/nutrition/foods/{id}/servings works	⬜
/api/v1/nutrition/foods/autofill works	⬜
Nutrition Tracking page can use autofill	⬜
19. STEP 46 Completion Definition

STEP 46 is complete when:

php artisan migrate
php artisan db:seed --class=NutritionFoodDatabaseSeeder
php artisan route:list | grep nutrition

works successfully, and these endpoints return 200 OK:

/api/v1/nutrition/categories
/api/v1/nutrition/foods
/api/v1/nutrition/foods/search?q=rice
/api/v1/nutrition/foods/{id}
/api/v1/nutrition/foods/{id}/servings
/api/v1/nutrition/foods/autofill

Final result:

Nutrition Facts Database implemented successfully.
Food search is ready.
Serving size calculation is ready.
CKD-friendly flags are ready.
Nutrition screen autofill API is ready.