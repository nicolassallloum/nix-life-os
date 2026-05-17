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