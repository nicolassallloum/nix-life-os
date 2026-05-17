<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_predictions', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');

            $table->string('prediction_type');
            // weight_prediction
            // financial_forecast

            $table->date('prediction_date');
            $table->date('target_date')->nullable();

            $table->decimal('current_value', 14, 2)->nullable();
            $table->decimal('predicted_value', 14, 2)->nullable();
            $table->decimal('change_value', 14, 2)->nullable();
            $table->decimal('change_percentage', 8, 2)->nullable();

            $table->jsonb('input_summary')->nullable();
            $table->jsonb('prediction_payload')->nullable();

            $table->string('confidence_level')->default('medium');
            // low, medium, high

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'prediction_type']);
            $table->index(['prediction_date']);
            $table->index(['target_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_predictions');
    }
};