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
            if (! Schema::hasColumn('health_lab_tests', 'category')) {
                $table->string('category')->nullable()->after('test_name');
            }

            if (! Schema::hasColumn('health_lab_tests', 'doctor_notes')) {
                $table->text('doctor_notes')->nullable()->after('notes');
            }

            if (! Schema::hasColumn('health_lab_tests', 'is_abnormal')) {
                $table->boolean('is_abnormal')->default(false)->after('doctor_notes');
            }

            if (! Schema::hasColumn('health_lab_tests', 'abnormal_reason')) {
                $table->text('abnormal_reason')->nullable()->after('is_abnormal');
            }

            if (! Schema::hasColumn('health_lab_tests', 'comparison_status')) {
                $table->string('comparison_status', 50)->nullable()->after('abnormal_reason');
            }

            if (! Schema::hasColumn('health_lab_tests', 'previous_result_id')) {
                $table->unsignedBigInteger('previous_result_id')->nullable()->after('comparison_status');
            }
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_category ON health_lab_tests(category)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_abnormal ON health_lab_tests(is_abnormal)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_lab_tests_user_category_date ON health_lab_tests(user_id, category, test_date)');
        }
    }

    public function down(): void
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return;
        }

        Schema::table('health_lab_tests', function (Blueprint $table) {
            foreach ([
                'previous_result_id',
                'comparison_status',
                'abnormal_reason',
                'is_abnormal',
                'doctor_notes',
                'category',
            ] as $column) {
                if (Schema::hasColumn('health_lab_tests', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};