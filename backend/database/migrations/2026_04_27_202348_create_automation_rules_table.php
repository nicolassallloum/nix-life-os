<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('automation_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('rule_name');
            $table->string('module'); 
            // health, finance, projects, productivity, system

            $table->string('trigger_type');
            // missing_log, threshold_exceeded, due_today, inactive_period, scheduled_time

            $table->jsonb('conditions')->nullable();
            /*
                Example:
                {
                    "metric": "water_ml",
                    "operator": "<",
                    "value": 1500,
                    "time": "18:00"
                }
            */

            $table->string('action_type')->default('create_notification');
            // create_notification, create_alert, create_reminder

            $table->jsonb('action_payload')->nullable();
            /*
                Example:
                {
                    "title": "Hydration Reminder",
                    "message": "You have not reached your water goal today.",
                    "notification_type": "reminder",
                    "priority": "medium"
                }
            */

            $table->boolean('is_active')->default(true);

            $table->timestamp('last_triggered_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'module']);
            $table->index(['user_id', 'trigger_type']);
            $table->index(['user_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('automation_rules');
    }
};