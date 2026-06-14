<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_sleep_logs')) {
            Schema::table('health_sleep_logs', function (Blueprint $table) {
                if (! Schema::hasColumn('health_sleep_logs', 'duration_minutes')) {
                    $table->integer('duration_minutes')->default(0)->after('wake_time');
                }

                if (! Schema::hasColumn('health_sleep_logs', 'quality_score')) {
                    $table->unsignedTinyInteger('quality_score')->nullable()->after('duration_minutes');
                }
            });

            if (Schema::hasColumn('health_sleep_logs', 'duration_hours') && Schema::hasColumn('health_sleep_logs', 'duration_minutes')) {
                DB::statement('UPDATE health_sleep_logs SET duration_minutes = COALESCE(duration_minutes, 0) + COALESCE((duration_hours * 60)::integer, 0) WHERE duration_minutes = 0');
            }
        }

        if (Schema::hasTable('health_mood_logs')) {
            Schema::table('health_mood_logs', function (Blueprint $table) {
                if (! Schema::hasColumn('health_mood_logs', 'mood_label')) {
                    $table->string('mood_label', 50)->nullable()->after('mood_date');
                }

                if (! Schema::hasColumn('health_mood_logs', 'tags')) {
                    $table->json('tags')->nullable()->after('notes');
                }
            });

            if (Schema::hasColumn('health_mood_logs', 'mood') && Schema::hasColumn('health_mood_logs', 'mood_label')) {
                DB::statement("UPDATE health_mood_logs SET mood_label = COALESCE(mood_label, mood) WHERE mood_label IS NULL");
            }
        }
    }

    public function down(): void
    {
        // Safe migration: no destructive rollback.
    }
};
