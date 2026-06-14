<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medications')) {
            return;
        }

        Schema::table('health_medications', function (Blueprint $table) {
            if (! Schema::hasColumn('health_medications', 'medication_name')) {
                $table->string('medication_name')->nullable()->index();
            }

            if (! Schema::hasColumn('health_medications', 'daily_dose')) {
                $table->string('daily_dose')->nullable();
            }

            if (! Schema::hasColumn('health_medications', 'prescribed_by')) {
                $table->string('prescribed_by')->nullable();
            }

            if (! Schema::hasColumn('health_medications', 'notes')) {
                $table->text('notes')->nullable();
            }
        });

        if (Schema::hasColumn('health_medications', 'name') && Schema::hasColumn('health_medications', 'medication_name')) {
            DB::statement("
                UPDATE health_medications
                SET medication_name = COALESCE(medication_name, name)
                WHERE medication_name IS NULL OR medication_name = ''
            ");
        }

        if (Schema::hasColumn('health_medications', 'dosage') && Schema::hasColumn('health_medications', 'daily_dose')) {
            DB::statement("
                UPDATE health_medications
                SET daily_dose = COALESCE(daily_dose, dosage)
                WHERE daily_dose IS NULL OR daily_dose = ''
            ");
        }

        if (Schema::hasColumn('health_medications', 'doctor_name') && Schema::hasColumn('health_medications', 'prescribed_by')) {
            DB::statement("
                UPDATE health_medications
                SET prescribed_by = COALESCE(prescribed_by, doctor_name)
                WHERE prescribed_by IS NULL OR prescribed_by = ''
            ");
        }

        if (Schema::hasColumn('health_medications', 'instructions') && Schema::hasColumn('health_medications', 'notes')) {
            DB::statement("
                UPDATE health_medications
                SET notes = COALESCE(notes, instructions)
                WHERE notes IS NULL OR notes = ''
            ");
        }
    }

    public function down(): void
    {
        // Safe migration: do not drop production columns.
    }
};
