<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_weight_logs', function (Blueprint $table) {
            $table->id();

            $table->uuid('user_id');

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->date('log_date');

            $table->decimal('weight_kg', 6, 2);

            $table->decimal('body_fat_percentage', 5, 2)->nullable();
            $table->decimal('muscle_mass_kg', 6, 2)->nullable();
            $table->decimal('bmi', 5, 2)->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'log_date']);

            $table->index(['user_id', 'log_date']);
            $table->index(['user_id', 'weight_kg']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_weight_logs');
    }
};