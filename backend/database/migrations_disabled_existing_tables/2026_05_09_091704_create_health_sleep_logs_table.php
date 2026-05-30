<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_sleep_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('sleep_date');
            $table->timestamp('bed_time');
            $table->timestamp('wake_time');

            $table->integer('duration_minutes')->default(0);
            $table->unsignedTinyInteger('quality_score')->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'sleep_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_sleep_logs');
    }
};