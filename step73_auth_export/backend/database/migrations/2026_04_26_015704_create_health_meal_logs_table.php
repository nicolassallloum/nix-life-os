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