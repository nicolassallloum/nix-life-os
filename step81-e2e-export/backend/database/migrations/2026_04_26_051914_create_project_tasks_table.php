<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_tasks', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('project_id');
            $table->uuid('user_id');

            $table->string('task_title');
            $table->text('task_description')->nullable();

            $table->string('status')->default('todo');
            /*
                todo
                in_progress
                blocked
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

            $table->integer('task_order')->default(1);

            $table->date('start_date')->nullable();
            $table->date('due_date')->nullable();
            $table->date('completed_date')->nullable();

            $table->decimal('progress_percentage', 5, 2)->default(0);

            $table->jsonb('metadata')->nullable();

            $table->timestamps();

            $table->foreign('project_id')
                ->references('id')
                ->on('projects')
                ->cascadeOnDelete();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['project_id', 'status']);
            $table->index(['user_id', 'status']);
            $table->index(['due_date']);
            $table->index(['priority']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_tasks');
    }
};