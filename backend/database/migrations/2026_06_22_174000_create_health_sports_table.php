<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_sports')) {
            return;
        }

        Schema::create('health_sports', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');

            $table->string('sport_type', 100);
            $table->decimal('calories_burned', 10, 2)->default(0);
            $table->unsignedInteger('duration_minutes');
            $table->date('activity_date');
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'activity_date']);
            $table->index(['user_id', 'sport_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_sports');
    }
};
