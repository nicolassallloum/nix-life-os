<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('automation_trigger_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('automation_rule_id')
                ->constrained('automation_rules')
                ->cascadeOnDelete();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('status')->default('triggered');
            // triggered, skipped, failed

            $table->jsonb('evaluated_data')->nullable();

            $table->text('message')->nullable();

            $table->timestamps();

            $table->index(['automation_rule_id']);
            $table->index(['user_id']);
            $table->index(['status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('automation_trigger_logs');
    }
};