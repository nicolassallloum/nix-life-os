<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_status_updates', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('project_id');
            $table->uuid('task_id')->nullable();
            $table->uuid('milestone_id')->nullable();

            $table->string('update_title');
            $table->text('update_description')->nullable();

            $table->string('old_status')->nullable();
            $table->string('new_status')->nullable();

            $table->unsignedTinyInteger('old_progress_percentage')->nullable();
            $table->unsignedTinyInteger('new_progress_percentage')->nullable();

            $table->enum('update_type', [
                'manual',
                'task_progress',
                'milestone_progress',
                'auto_calculation',
                'status_change'
            ])->default('manual');

            $table->jsonb('metadata')->nullable();

            $table->timestamps();

            $table->foreign('project_id')
                ->references('id')
                ->on('projects')
                ->cascadeOnDelete();

            if (Schema::hasTable('project_tasks')) {
                $table->foreign('task_id')
                    ->references('id')
                    ->on('project_tasks')
                    ->nullOnDelete();
            }

            $table->foreign('milestone_id')
                ->references('id')
                ->on('project_milestones')
                ->nullOnDelete();

            $table->index(['project_id', 'created_at']);
            $table->index(['project_id', 'update_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_status_updates');
    }
};