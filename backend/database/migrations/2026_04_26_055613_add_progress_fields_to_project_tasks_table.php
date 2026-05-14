<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('project_tasks')) {
            return;
        }

        Schema::table('project_tasks', function (Blueprint $table) {
            if (!Schema::hasColumn('project_tasks', 'progress_percentage')) {
                $table->decimal('progress_percentage', 5, 2)->default(0)->after('completed_date');
            }

            if (!Schema::hasColumn('project_tasks', 'weight')) {
                $table->decimal('weight', 8, 2)->default(1)->after('progress_percentage');
            }

            /*
             |--------------------------------------------------------------------------
             | Important:
             |--------------------------------------------------------------------------
             | project_tasks has due_date and completed_date.
             | It does not have target_end_date.
             */
            if (!Schema::hasColumn('project_tasks', 'completed_at')) {
                $table->timestamp('completed_at')->nullable()->after('completed_date');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('project_tasks')) {
            return;
        }

        Schema::table('project_tasks', function (Blueprint $table) {
            if (Schema::hasColumn('project_tasks', 'completed_at')) {
                $table->dropColumn('completed_at');
            }

            if (Schema::hasColumn('project_tasks', 'weight')) {
                $table->dropColumn('weight');
            }

            if (Schema::hasColumn('project_tasks', 'progress_percentage')) {
                $table->dropColumn('progress_percentage');
            }
        });
    }
};
