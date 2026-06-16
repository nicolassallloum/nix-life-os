<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medication_times')) {
            Schema::create('health_medication_times', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('medication_id')->index();
                $table->time('dosage_time');
                $table->string('dosage_note')->nullable();
                $table->timestamps();

                $table->unique(['medication_id', 'dosage_time']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_medication_times');
    }
};
