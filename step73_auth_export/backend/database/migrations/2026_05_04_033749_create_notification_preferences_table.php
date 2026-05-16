<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('notification_preferences')) {
            Schema::create('notification_preferences', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->index();

                $table->boolean('meal_reminders_enabled')->default(true);
                $table->time('breakfast_time')->nullable();
                $table->time('lunch_time')->nullable();
                $table->time('dinner_time')->nullable();

                $table->boolean('weight_reminders_enabled')->default(true);
                $table->time('weight_reminder_time')->nullable();

                $table->boolean('expense_reminders_enabled')->default(true);
                $table->time('expense_reminder_time')->nullable();

                $table->boolean('finance_alerts_enabled')->default(true);
                $table->boolean('health_alerts_enabled')->default(true);
                $table->boolean('life_balance_alerts_enabled')->default(true);

                $table->decimal('daily_expense_warning_limit', 15, 2)->nullable();
                $table->integer('life_balance_warning_score')->default(60);

                $table->timestamps();

                $table->unique('user_id');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};