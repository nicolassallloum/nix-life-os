<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('life_balance_scores', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');
            $table->date('target_date');

            $table->unsignedTinyInteger('finance_score')->default(0);
            $table->unsignedTinyInteger('health_score')->default(0);
            $table->unsignedTinyInteger('productivity_score')->default(0);
            $table->unsignedTinyInteger('overall_score')->default(0);

            $table->string('status')->default('unknown');

            $table->jsonb('finance_breakdown')->nullable();
            $table->jsonb('health_breakdown')->nullable();
            $table->jsonb('productivity_breakdown')->nullable();
            $table->jsonb('recommendations')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'target_date']);

            $table->index(['user_id', 'target_date']);
            $table->index(['user_id', 'overall_score']);
            $table->index(['status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('life_balance_scores');
    }
};