<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_profile', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');

            $table->unsignedInteger('daily_steps_goal')->default(8000);
            $table->decimal('stride_length_cm', 6, 2)->default(75.00);
            $table->string('distance_unit', 10)->default('km');

            $table->timestamps();

            $table->unique('user_id');

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_profile');
    }
};