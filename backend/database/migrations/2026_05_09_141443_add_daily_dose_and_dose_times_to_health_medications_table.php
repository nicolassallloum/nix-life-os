<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_medications')) {
            Schema::create('health_medications', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id');
                $table->string('medication_name');
                $table->string('dosage')->nullable();
                $table->string('daily_dose')->nullable();
                $table->unsignedSmallInteger('daily_times')->nullable();
                $table->json('dose_times')->nullable();
                $table->string('frequency')->nullable();
                $table->date('start_date')->nullable();
                $table->date('end_date')->nullable();
                $table->string('status')->default('active');
                $table->string('prescribed_by')->nullable();
                $table->string('doctor_name')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
                $table->softDeletes();

                $table->foreign('user_id')
                    ->references('id')
                    ->on('users')
                    ->cascadeOnDelete();

                $table->index(['user_id', 'status']);
                $table->index('start_date');
            });

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