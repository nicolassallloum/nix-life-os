<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_mood_logs')) {
            Schema::create('health_mood_logs', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->index();
                $table->date('mood_date')->index();
                $table->string('mood_label', 100);
                $table->unsignedTinyInteger('mood_score')->nullable();
                $table->text('notes')->nullable();
                $table->json('tags')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'mood_date']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_mood_logs');
    }
};
