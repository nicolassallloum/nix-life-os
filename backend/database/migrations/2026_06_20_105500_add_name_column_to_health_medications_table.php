<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medications')) {
            return;
        }

        Schema::table('health_medications', function (Blueprint $table) {
            if (! Schema::hasColumn('health_medications', 'name')) {
                $table->string('name')->nullable()->after('medication_name');
            }
        });

        if (
            Schema::hasColumn('health_medications', 'name') &&
            Schema::hasColumn('health_medications', 'medication_name')
        ) {
            DB::statement("
                UPDATE health_medications
                SET name = medication_name
                WHERE name IS NULL OR name = ''
            ");
        }
    }

    public function down(): void
    {
        // Safe production migration: do not drop compatibility column.
    }
};
