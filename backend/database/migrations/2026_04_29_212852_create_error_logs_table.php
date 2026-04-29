<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('error_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->nullable();

            $table->string('level')->default('error');
            $table->string('module')->nullable();
            $table->string('exception_class')->nullable();

            $table->text('message');
            $table->text('file')->nullable();
            $table->integer('line')->nullable();

            $table->string('request_method')->nullable();
            $table->text('request_url')->nullable();
            $table->jsonb('request_payload')->nullable();

            $table->text('trace')->nullable();
            $table->jsonb('metadata')->nullable();

            $table->string('ip_address')->nullable();
            $table->string('user_agent')->nullable();

            $table->timestamp('created_at')->useCurrent();

            $table->index('user_id');
            $table->index('level');
            $table->index('module');
            $table->index('exception_class');
            $table->index('created_at');
        });

        DB::statement('ALTER TABLE error_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()');
    }

    public function down(): void
    {
        Schema::dropIfExists('error_logs');
    }
};