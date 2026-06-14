<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_sleep_logs')) {
            Schema::create('health_sleep_logs', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id')->index();
                $table->date('sleep_date')->index();
                $table->time('bed_time')->nullable();
                $table->time('wake_time')->nullable();
                $table->decimal('duration_hours', 5, 2)->default(0);
                $table->string('quality')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'sleep_date']);
            });
        }
    }

    public function down(): void
    {
        // Safe migration: do not drop existing user health data.
    }
};
