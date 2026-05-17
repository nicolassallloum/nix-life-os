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