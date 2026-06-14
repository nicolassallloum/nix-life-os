<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        foreach (['health_sleep_logs', 'health_mood_logs'] as $tableName) {
            if (! Schema::hasTable($tableName)) {
                continue;
            }

            $count = DB::table($tableName)->count();

            if ($count === 0) {
                Schema::drop($tableName);
            }
        }

        if (! Schema::hasTable('health_sleep_logs')) {
            Schema::create('health_sleep_logs', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->index();
                $table->date('sleep_date')->index();
                $table->time('bed_time')->nullable();
                $table->time('wake_time')->nullable();
                $table->integer('duration_minutes')->default(0);
                $table->unsignedTinyInteger('quality_score')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'sleep_date']);
            });
        }

        if (! Schema::hasTable('health_mood_logs')) {
            Schema::create('health_mood_logs', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->index();
                $table->date('mood_date')->index();
                $table->string('mood_label', 50);
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
        // Safe migration: no destructive rollback.
    }
};
