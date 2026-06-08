<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_hydration_logs')) {
            Schema::create('health_hydration_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('hydration_type', 50)->default('Water');
                $table->unsignedInteger('quantity_ml')->default(0);
                $table->date('log_date');
                $table->time('log_time')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'log_date']);
                $table->index(['user_id', 'hydration_type']);
            });

            return;
        }

        Schema::table('health_hydration_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('health_hydration_logs', 'user_id')) {
                $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            }

            if (! Schema::hasColumn('health_hydration_logs', 'hydration_type')) {
                $table->string('hydration_type', 50)->default('Water');
            }

            if (! Schema::hasColumn('health_hydration_logs', 'quantity_ml')) {
                $table->unsignedInteger('quantity_ml')->default(0);
            }

            if (! Schema::hasColumn('health_hydration_logs', 'log_date')) {
                $table->date('log_date')->nullable();
            }

            if (! Schema::hasColumn('health_hydration_logs', 'log_time')) {
                $table->time('log_time')->nullable();
            }

            if (! Schema::hasColumn('health_hydration_logs', 'notes')) {
                $table->text('notes')->nullable();
            }

            if (! Schema::hasColumn('health_hydration_logs', 'created_at')) {
                $table->timestamps();
            }
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_hydration_logs');
    }
};
