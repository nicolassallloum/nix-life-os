<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('users')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'height_cm')) {
                $table->decimal('height_cm', 6, 2)->nullable()->after('phone');
            }
        });

        // Current admin test profile height used for BMI auto-calculation.
        DB::table('users')
            ->where('email', 'admin@nixlifeos.com')
            ->whereNull('height_cm')
            ->update([
                'height_cm' => 151,
                'updated_at' => now(),
            ]);

        // Backfill BMI for existing weight logs that do not have BMI.
        if (Schema::hasTable('health_weight_logs')) {
            DB::statement("
                UPDATE health_weight_logs hw
                SET bmi = ROUND((hw.weight_kg / POWER((u.height_cm / 100.0), 2))::numeric, 1),
                    updated_at = NOW()
                FROM users u
                WHERE hw.user_id = u.id
                  AND hw.bmi IS NULL
                  AND u.height_cm IS NOT NULL
                  AND u.height_cm > 0
                  AND hw.weight_kg IS NOT NULL
            ");
        }
    }

    public function down(): void
    {
        // Safe migration: keep production profile data.
    }
};
