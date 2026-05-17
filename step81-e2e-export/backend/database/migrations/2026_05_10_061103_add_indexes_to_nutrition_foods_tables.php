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