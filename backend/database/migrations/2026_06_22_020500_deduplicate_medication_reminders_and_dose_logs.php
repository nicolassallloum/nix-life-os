<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_medication_dose_logs')) {
            DB::statement("
                DELETE FROM health_medication_dose_logs d
                USING (
                    SELECT id
                    FROM (
                        SELECT
                            id,
                            ROW_NUMBER() OVER (
                                PARTITION BY user_id, medication_id, scheduled_for
                                ORDER BY
                                    CASE status
                                        WHEN 'taken' THEN 1
                                        WHEN 'skipped' THEN 2
                                        WHEN 'pending' THEN 3
                                        WHEN 'missed' THEN 4
                                        ELSE 5
                                    END,
                                    updated_at DESC,
                                    created_at DESC,
                                    id DESC
                            ) AS rn
                        FROM health_medication_dose_logs
                    ) ranked
                    WHERE rn > 1
                ) duplicates
                WHERE d.id = duplicates.id
            ");

            DB::statement("
                CREATE UNIQUE INDEX IF NOT EXISTS health_med_dose_unique_user_med_time
                ON health_medication_dose_logs (user_id, medication_id, scheduled_for)
            ");
        }

        if (Schema::hasTable('health_medication_reminders')) {
            DB::statement("
                UPDATE health_medication_dose_logs dose
                SET reminder_id = keeper.keep_id
                FROM (
                    SELECT
                        user_id,
                        medication_id,
                        reminder_time,
                        COALESCE(frequency_type, 'daily') AS frequency_type,
                        COALESCE(timezone, 'Asia/Beirut') AS timezone,
                        MAX(id::text)::uuid AS keep_id
                    FROM health_medication_reminders
                    GROUP BY user_id, medication_id, reminder_time, COALESCE(frequency_type, 'daily'), COALESCE(timezone, 'Asia/Beirut')
                ) keeper
                JOIN health_medication_reminders reminder
                    ON reminder.user_id = keeper.user_id
                    AND reminder.medication_id = keeper.medication_id
                    AND reminder.reminder_time = keeper.reminder_time
                    AND COALESCE(reminder.frequency_type, 'daily') = keeper.frequency_type
                    AND COALESCE(reminder.timezone, 'Asia/Beirut') = keeper.timezone
                WHERE dose.reminder_id = reminder.id
                  AND reminder.id <> keeper.keep_id
            ");

            DB::statement("
                DELETE FROM health_medication_reminders r
                USING (
                    SELECT id
                    FROM (
                        SELECT
                            id,
                            ROW_NUMBER() OVER (
                                PARTITION BY user_id, medication_id, reminder_time, COALESCE(frequency_type, 'daily'), COALESCE(timezone, 'Asia/Beirut')
                                ORDER BY updated_at DESC, created_at DESC, id DESC
                            ) AS rn
                        FROM health_medication_reminders
                    ) ranked
                    WHERE rn > 1
                ) duplicates
                WHERE r.id = duplicates.id
            ");

            DB::statement("
                CREATE UNIQUE INDEX IF NOT EXISTS health_med_reminder_unique_user_med_time
                ON health_medication_reminders (
                    user_id,
                    medication_id,
                    reminder_time,
                    COALESCE(frequency_type, 'daily'),
                    COALESCE(timezone, 'Asia/Beirut')
                )
            ");
        }
    }

    public function down(): void
    {
        DB::statement("DROP INDEX IF EXISTS health_med_dose_unique_user_med_time");
        DB::statement("DROP INDEX IF EXISTS health_med_reminder_unique_user_med_time");
    }
};
