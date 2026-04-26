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