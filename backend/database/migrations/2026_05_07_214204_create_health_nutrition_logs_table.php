<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_nutrition_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->nullable()->index();

            $table->date('meal_date')->index();
            $table->string('meal_type', 50)->nullable()->index();

            $table->string('food_name');
            $table->decimal('quantity', 10, 2)->default(1);
            $table->string('unit', 50)->nullable();

            $table->decimal('calories', 10, 2)->default(0);
            $table->decimal('protein', 10, 2)->default(0);
            $table->decimal('sodium', 10, 2)->default(0);
            $table->decimal('potassium', 10, 2)->default(0);
            $table->decimal('phosphorus', 10, 2)->default(0);

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_nutrition_logs');
    }
};