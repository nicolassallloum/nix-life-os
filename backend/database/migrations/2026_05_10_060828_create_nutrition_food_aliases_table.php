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