<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('project_task_steps')) {
            Schema::create('project_task_steps', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id');
                $table->uuid('project_id');
                $table->uuid('project_task_id');

                $table->string('title');
                $table->text('description')->nullable();

                $table->string('status')->default('todo');
                $table->unsignedInteger('step_order')->default(0);
                $table->decimal('progress_percentage', 5, 2)->default(0);

                $table->date('due_date')->nullable();
                $table->timestamp('completed_at')->nullable();

                $table->json('metadata')->nullable();

                $table->timestamps();

                $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('project_id')->references('id')->on('projects')->cascadeOnDelete();
                $table->foreign('project_task_id')->references('id')->on('project_tasks')->cascadeOnDelete();

                $table->index(['user_id', 'project_id']);
                $table->index(['project_task_id', 'status']);
                $table->index(['due_date']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('project_task_steps');
    }
};
