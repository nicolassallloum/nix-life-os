<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nutrition_food_sources', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('food_id');

            $table->string('source_name', 150);
            $table->string('source_food_id', 150)->nullable();
            $table->text('source_url')->nullable();

            $table->timestamp('imported_at')->nullable();

            $table->timestamps();

            $table->foreign('food_id')
                ->references('id')
                ->on('nutrition_foods')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nutrition_food_sources');
    }
};