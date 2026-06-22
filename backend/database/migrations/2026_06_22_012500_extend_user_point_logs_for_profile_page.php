<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('user_point_logs')) {
            return;
        }

        Schema::table('user_point_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('user_point_logs', 'action_type')) {
                $table->string('action_type', 150)->nullable()->after('action_name');
            }

            if (! Schema::hasColumn('user_point_logs', 'description')) {
                $table->text('description')->nullable()->after('points');
            }

            if (! Schema::hasColumn('user_point_logs', 'related_id')) {
                $table->string('related_id')->nullable()->after('reference_id');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('user_point_logs')) {
            return;
        }

        Schema::table('user_point_logs', function (Blueprint $table) {
            if (Schema::hasColumn('user_point_logs', 'related_id')) {
                $table->dropColumn('related_id');
            }

            if (Schema::hasColumn('user_point_logs', 'description')) {
                $table->dropColumn('description');
            }

            if (Schema::hasColumn('user_point_logs', 'action_type')) {
                $table->dropColumn('action_type');
            }
        });
    }
};
