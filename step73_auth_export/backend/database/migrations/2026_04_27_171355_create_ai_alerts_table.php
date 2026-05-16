<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_alerts', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('alert_type', 80)->index();
            // budget_risk, health_warning, project_delay, hydration_low, spending_spike

            $table->string('module', 50)->index();
            // finance, health, projects, unified

            $table->string('title');
            $table->text('message');

            $table->string('severity', 30)->default('warning')->index();
            // info, warning, critical

            $table->decimal('risk_score', 8, 2)->nullable();

            $table->jsonb('trigger_data')->nullable();

            $table->date('alert_date')->index();

            $table->boolean('is_resolved')->default(false);
            $table->timestamp('resolved_at')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'alert_date']);
            $table->index(['user_id', 'is_resolved']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_alerts');
    }
};