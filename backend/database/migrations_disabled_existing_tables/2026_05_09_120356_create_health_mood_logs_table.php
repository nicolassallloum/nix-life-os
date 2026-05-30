<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_mood_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('mood_date');
            $table->string('mood_label', 50);
            $table->unsignedTinyInteger('mood_score');
            $table->text('notes')->nullable();
            $table->jsonb('tags')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'mood_date']);
            $table->index('mood_score');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_mood_logs');
    }
};