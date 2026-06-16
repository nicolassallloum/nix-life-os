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
                $table->uuid('id')->primary();
                $table->uuid('user_id')->index();

                $table->date('sleep_date')->index();
                $table->date('wake_date')->nullable();
                $table->timestamp('bed_time')->nullable();
                $table->timestamp('wake_time')->nullable();

                $table->unsignedInteger('duration_minutes')->default(0);
                $table->decimal('duration_hours', 5, 2)->default(0);
                $table->unsignedTinyInteger('quality_score')->nullable();
                $table->string('quality', 50)->nullable();

                $table->text('notes')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'sleep_date']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_sleep_logs');
    }
};
