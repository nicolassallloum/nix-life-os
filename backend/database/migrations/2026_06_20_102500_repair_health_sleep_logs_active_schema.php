<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
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

            return;
        }

        Schema::table('health_sleep_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('health_sleep_logs', 'wake_date')) {
                $table->date('wake_date')->nullable()->after('sleep_date');
            }

            if (! Schema::hasColumn('health_sleep_logs', 'duration_minutes')) {
                $table->unsignedInteger('duration_minutes')->default(0)->after('wake_time');
            }

            if (! Schema::hasColumn('health_sleep_logs', 'duration_hours')) {
                $table->decimal('duration_hours', 5, 2)->default(0)->after('duration_minutes');
            }

            if (! Schema::hasColumn('health_sleep_logs', 'quality_score')) {
                $table->unsignedTinyInteger('quality_score')->nullable()->after('duration_hours');
            }

            if (! Schema::hasColumn('health_sleep_logs', 'quality')) {
                $table->string('quality', 50)->nullable()->after('quality_score');
            }
        });

        DB::statement("
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_name = 'health_sleep_logs'
                      AND column_name = 'bed_time'
                      AND data_type = 'time without time zone'
                ) THEN
                    ALTER TABLE health_sleep_logs
                    ALTER COLUMN bed_time TYPE timestamp(0) without time zone
                    USING CASE
                        WHEN bed_time IS NULL THEN NULL
                        ELSE (sleep_date::timestamp + bed_time)
                    END;
                END IF;
            END $$;
        ");

        DB::statement("
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_name = 'health_sleep_logs'
                      AND column_name = 'wake_time'
                      AND data_type = 'time without time zone'
                ) THEN
                    ALTER TABLE health_sleep_logs
                    ALTER COLUMN wake_time TYPE timestamp(0) without time zone
                    USING CASE
                        WHEN wake_time IS NULL THEN NULL
                        ELSE (COALESCE(wake_date, sleep_date)::timestamp + wake_time)
                    END;
                END IF;
            END $$;
        ");

        if (Schema::hasColumn('health_sleep_logs', 'duration_hours') && Schema::hasColumn('health_sleep_logs', 'duration_minutes')) {
            DB::statement("
                UPDATE health_sleep_logs
                SET duration_hours = ROUND((COALESCE(duration_minutes, 0)::numeric / 60), 2)
                WHERE duration_hours IS NULL OR duration_hours = 0
            ");
        }

        if (Schema::hasColumn('health_sleep_logs', 'wake_date') && Schema::hasColumn('health_sleep_logs', 'wake_time')) {
            DB::statement("
                UPDATE health_sleep_logs
                SET wake_date = wake_time::date
                WHERE wake_date IS NULL
                  AND wake_time IS NOT NULL
            ");
        }
    }

    public function down(): void
    {
        // Safe production migration: no destructive rollback.
    }
};
