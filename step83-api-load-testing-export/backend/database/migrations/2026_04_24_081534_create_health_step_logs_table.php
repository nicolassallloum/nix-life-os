<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_step_log', function (Blueprint $table) {
            $table->uuid('id')->primary();

            // IMPORTANT: users.id is UUID, so user_id must be UUID also
            $table->uuid('user_id');

            $table->date('log_date');
            $table->unsignedInteger('steps_count')->default(0);
            $table->decimal('distance_km', 10, 3)->default(0);
            $table->unsignedInteger('goal_steps')->default(8000);
            $table->decimal('goal_percentage', 6, 2)->default(0);
            $table->boolean('goal_completed')->default(false);
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'log_date']);
            $table->index(['user_id', 'log_date']);

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_step_log');
    }
};