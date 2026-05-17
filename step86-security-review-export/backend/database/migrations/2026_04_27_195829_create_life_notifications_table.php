<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('life_notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');

            $table->string('notification_type', 80);
            /*
                meal_reminder
                weight_reminder
                expense_reminder
                finance_alert
                health_alert
                productivity_alert
                life_balance_alert
                system_alert
            */

            $table->string('title', 255);
            $table->text('message');

            $table->string('severity', 30)->default('info');
            /*
                info
                success
                warning
                danger
            */

            $table->string('source_module', 80)->nullable();
            /*
                finance
                health
                productivity
                projects
                life_balance
                ai
            */

            $table->jsonb('metadata')->nullable();

            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();

            $table->timestamp('scheduled_for')->nullable();
            $table->timestamp('triggered_at')->nullable();

            $table->timestamps();

            $table->index('user_id');
            $table->index('notification_type');
            $table->index('severity');
            $table->index('is_read');
            $table->index('scheduled_for');
            $table->index(['user_id', 'is_read']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('life_notifications');
    }
};