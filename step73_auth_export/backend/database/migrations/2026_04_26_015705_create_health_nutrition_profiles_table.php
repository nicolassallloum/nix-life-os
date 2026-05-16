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