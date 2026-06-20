<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_weight_logs')) {
            return;
        }

        Schema::table('health_weight_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('health_weight_logs', 'height_cm')) {
                $table->decimal('height_cm', 6, 2)->nullable();
            }

            if (! Schema::hasColumn('health_weight_logs', 'length_cm')) {
                $table->decimal('length_cm', 6, 2)->nullable();
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('health_weight_logs')) {
            return;
        }

        Schema::table('health_weight_logs', function (Blueprint $table) {
            if (Schema::hasColumn('health_weight_logs', 'height_cm')) {
                $table->dropColumn('height_cm');
            }

            if (Schema::hasColumn('health_weight_logs', 'length_cm')) {
                $table->dropColumn('length_cm');
            }
        });
    }
};
