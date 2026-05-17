<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_medication_reminders')) {
            return;
        }

        Schema::create('health_medication_reminders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('medication_id');

            $table->time('reminder_time');
            $table->string('frequency_type')->default('daily');
            $table->json('days_of_week')->nullable();
            $table->unsignedSmallInteger('interval_hours')->nullable();
            $table->string('timezone')->default('Asia/Beirut');

            $table->boolean('is_active')->default(true);
            $table->boolean('notification_enabled')->default(true);

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->foreign('medication_id')
                ->references('id')
                ->on('health_medications')
                ->cascadeOnDelete();

            $table->index(['user_id', 'is_active']);
            $table->index(['medication_id', 'reminder_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_medication_reminders');
    }
};