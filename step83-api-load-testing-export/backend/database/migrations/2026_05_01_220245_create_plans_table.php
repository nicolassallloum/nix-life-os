<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('code')->unique();
            $table->string('name');

            $table->decimal('monthly_price', 10, 2)->default(0);
            $table->decimal('yearly_price', 10, 2)->default(0);

            $table->integer('max_finance_accounts')->default(3);
            $table->integer('max_projects')->default(3);
            $table->integer('max_ai_insights_per_month')->default(30);
            $table->integer('max_notifications_per_month')->default(100);

            $table->boolean('finance_module_enabled')->default(true);
            $table->boolean('health_module_enabled')->default(true);
            $table->boolean('projects_module_enabled')->default(true);
            $table->boolean('ai_module_enabled')->default(false);
            $table->boolean('automation_module_enabled')->default(false);
            $table->boolean('monitoring_module_enabled')->default(false);

            $table->jsonb('features')->nullable();

            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};