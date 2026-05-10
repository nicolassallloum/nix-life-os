<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_medication_dose_logs')) {
            return;
        }

        Schema::create('health_medication_dose_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('medication_id');
            $table->uuid('reminder_id')->nullable();

            $table->timestamp('scheduled_for');
            $table->timestamp('taken_at')->nullable();

            $table->string('status')->default('pending');
            $table->string('skip_reason')->nullable();
            $table->text('notes')->nullable();

            $table->timestamp('notification_sent_at')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->foreign('medication_id')
                ->references('id')
                ->on('health_medications')
                ->cascadeOnDelete();

            $table->foreign('reminder_id')
                ->references('id')
                ->on('health_medication_reminders')
                ->nullOnDelete();

            $table->unique(['user_id', 'medication_id', 'reminder_id', 'scheduled_for'], 'unique_medication_dose_schedule');

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'scheduled_for']);
            $table->index(['medication_id', 'scheduled_for']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_medication_dose_logs');
    }
};