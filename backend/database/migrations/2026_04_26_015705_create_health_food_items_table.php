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