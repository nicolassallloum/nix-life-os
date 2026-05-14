<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('project_tasks')) {
            Schema::table('project_tasks', function (Blueprint $table) {
                if (!Schema::hasColumn('project_tasks', 'progress_percentage')) {
                    $table->unsignedTinyInteger('progress_percentage')->default(0)->after('status');
                }

                if (!Schema::hasColumn('project_tasks', 'weight')) {
                    $table->decimal('weight', 8, 2)->default(1)->after('progress_percentage');
                }

                if (!Schema::hasColumn('project_tasks', 'completed_at')) {
                    $table->timestamp('completed_at')->nullable()->after('target_end_date');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('project_tasks')) {
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
    }
};