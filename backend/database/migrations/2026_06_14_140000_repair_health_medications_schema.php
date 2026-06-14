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
            if (! Schema::hasColumn('health_medications', 'status')) {
                $table->string('status', 30)->default('active')->index();
            }

            if (! Schema::hasColumn('health_medications', 'deleted_at')) {
                $table->timestamp('deleted_at')->nullable()->index();
            }
        });

        if (Schema::hasColumn('health_medications', 'is_active') && Schema::hasColumn('health_medications', 'status')) {
            DB::statement("
                UPDATE health_medications
                SET status = CASE
                    WHEN is_active = true THEN 'active'
                    ELSE 'inactive'
                END
                WHERE status IS NULL OR status = ''
            ");
        }
    }

    public function down(): void
    {
        // Safe migration: do not drop production columns.
    }
};
