<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_reports', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('report_type', 50)->index();
            // daily, weekly, monthly

            $table->date('period_start')->index();
            $table->date('period_end')->index();

            $table->string('title');
            $table->text('summary')->nullable();

            $table->jsonb('finance_summary')->nullable();
            $table->jsonb('health_summary')->nullable();
            $table->jsonb('project_summary')->nullable();
            $table->jsonb('recommendations')->nullable();
            $table->jsonb('raw_metrics')->nullable();

            $table->decimal('overall_score', 8, 2)->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'report_type']);
            $table->index(['user_id', 'period_start', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_reports');
    }
};