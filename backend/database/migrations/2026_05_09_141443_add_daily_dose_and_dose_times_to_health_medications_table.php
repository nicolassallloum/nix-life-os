<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('health_medications', function (Blueprint $table) {
            $table->string('daily_dose')->nullable()->after('dosage');
            $table->json('dose_times')->nullable()->after('daily_dose');
        });
    }

    public function down(): void
    {
        Schema::table('health_medications', function (Blueprint $table) {
            $table->dropColumn(['daily_dose', 'dose_times']);
        });
    }
};