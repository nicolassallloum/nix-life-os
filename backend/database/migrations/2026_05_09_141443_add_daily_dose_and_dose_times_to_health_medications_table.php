<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medications')) {
            return;
        }

        Schema::table('health_medications', function (Blueprint $table) {
            if (! Schema::hasColumn('health_medications', 'daily_dose')) {
                $table->string('daily_dose')->nullable()->after('dose');
            }

            if (! Schema::hasColumn('health_medications', 'dose_times')) {
                $table->json('dose_times')->nullable()->after('daily_dose');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('health_medications')) {
            return;
        }

        Schema::table('health_medications', function (Blueprint $table) {
            if (Schema::hasColumn('health_medications', 'dose_times')) {
                $table->dropColumn('dose_times');
            }

            if (Schema::hasColumn('health_medications', 'daily_dose')) {
                $table->dropColumn('daily_dose');
            }
        });
    }
};