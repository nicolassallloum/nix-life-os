<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return;
        }

        Schema::table('health_lab_tests', function (Blueprint $table) {
            if (! Schema::hasColumn('health_lab_tests', 'creatinine')) {
                $table->decimal('creatinine', 8, 2)->nullable()->after('lab_name');
            }

            if (! Schema::hasColumn('health_lab_tests', 'urea')) {
                $table->decimal('urea', 8, 2)->nullable()->after('creatinine');
            }

            if (! Schema::hasColumn('health_lab_tests', 'egfr')) {
                $table->decimal('egfr', 8, 2)->nullable()->after('urea');
            }

            if (! Schema::hasColumn('health_lab_tests', 'hemoglobin')) {
                $table->decimal('hemoglobin', 8, 2)->nullable()->after('egfr');
            }

            if (! Schema::hasColumn('health_lab_tests', 'sodium')) {
                $table->decimal('sodium', 8, 2)->nullable()->after('hemoglobin');
            }

            if (! Schema::hasColumn('health_lab_tests', 'potassium')) {
                $table->decimal('potassium', 8, 2)->nullable()->after('sodium');
            }

            if (! Schema::hasColumn('health_lab_tests', 'phosphorus')) {
                $table->decimal('phosphorus', 8, 2)->nullable()->after('potassium');
            }

            if (! Schema::hasColumn('health_lab_tests', 'source_type')) {
                $table->string('source_type', 50)->default('manual')->after('phosphorus');
            }

            if (! Schema::hasColumn('health_lab_tests', 'attachment_path')) {
                $table->string('attachment_path')->nullable()->after('source_type');
            }
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_user_date ON health_lab_tests(user_id, test_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_creatinine ON health_lab_tests(creatinine)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_egfr ON health_lab_tests(egfr)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_potassium ON health_lab_tests(potassium)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_phosphorus ON health_lab_tests(phosphorus)');
        }
    }

    public function down(): void
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return;
        }

        Schema::table('health_lab_tests', function (Blueprint $table) {
            foreach ([
                'attachment_path',
                'source_type',
                'phosphorus',
                'potassium',
                'sodium',
                'hemoglobin',
                'egfr',
                'urea',
                'creatinine',
            ] as $column) {
                if (Schema::hasColumn('health_lab_tests', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
