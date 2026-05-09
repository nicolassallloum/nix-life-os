<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_monitoring_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('service_name');
            $table->string('status')->default('healthy');

            $table->integer('response_time_ms')->nullable();

            if (DB::getDriverName() === 'pgsql') {
                $table->jsonb('metrics')->nullable();
            } else {
                $table->json('metrics')->nullable();
            }

            $table->text('message')->nullable();

            $table->timestamp('checked_at')->useCurrent();

            $table->index('service_name');
            $table->index('status');
            $table->index('checked_at');
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE system_monitoring_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('system_monitoring_logs');
    }
};