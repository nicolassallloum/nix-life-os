<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('health_nutrition_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('health_nutrition_logs', 'custom_food_id')) {
                $table->uuid('custom_food_id')->nullable()->after('id');

                $table->foreign('custom_food_id')
                    ->references('id')
                    ->on('nutrition_custom_foods')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('health_nutrition_logs', 'food_source')) {
                $table->string('food_source', 50)->default('manual')->after('custom_food_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('health_nutrition_logs', function (Blueprint $table) {
            if (Schema::hasColumn('health_nutrition_logs', 'custom_food_id')) {
                $table->dropForeign(['custom_food_id']);
                $table->dropColumn('custom_food_id');
            }

            if (Schema::hasColumn('health_nutrition_logs', 'food_source')) {
                $table->dropColumn('food_source');
            }
        });
    }
};