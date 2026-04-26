<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');

            $table->string('project_name');
            $table->string('project_code')->nullable();
            $table->text('description')->nullable();

            $table->string('status')->default('not_started');
            /*
                not_started
                in_progress
                on_hold
                completed
                cancelled
            */

            $table->string('priority')->default('medium');
            /*
                low
                medium
                high
                critical
            */

            $table->date('start_date')->nullable();
            $table->date('target_end_date')->nullable();
            $table->date('actual_end_date')->nullable();

            $table->decimal('progress_percentage', 5, 2)->default(0);

            $table->jsonb('metadata')->nullable();

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'priority']);
            $table->index(['start_date']);
            $table->index(['target_end_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('projects');
    }
};