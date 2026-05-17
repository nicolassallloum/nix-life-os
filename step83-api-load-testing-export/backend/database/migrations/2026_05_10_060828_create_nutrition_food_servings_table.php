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