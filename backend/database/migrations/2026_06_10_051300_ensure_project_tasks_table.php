<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('project_tasks')) {
            Schema::create('project_tasks', function (Blueprint $table) {
                $table->uuid('id')->primary();

                $table->uuid('user_id');
                $table->uuid('project_id');

                $table->string('title');
                $table->text('description')->nullable();

                $table->string('priority')->default('medium');
                $table->string('status')->default('todo');

                $table->date('start_date')->nullable();
                $table->date('due_date')->nullable();
                $table->timestamp('completed_at')->nullable();

                $table->uuid('assigned_to')->nullable();
                $table->text('notes')->nullable();

                $table->unsignedInteger('task_order')->default(0);
                $table->decimal('progress_percentage', 5, 2)->default(0);
                $table->decimal('weight', 8, 2)->default(1);

                $table->timestamps();

                $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
                $table->foreign('project_id')->references('id')->on('projects')->cascadeOnDelete();

                $table->index(['user_id', 'status']);
                $table->index(['project_id', 'status']);
                $table->index(['due_date']);
                $table->index(['task_order']);
            });
        } else {
            Schema::table('project_tasks', function (Blueprint $table) {
                if (! Schema::hasColumn('project_tasks', 'progress_percentage')) {
                    $table->decimal('progress_percentage', 5, 2)->default(0);
                }

                if (! Schema::hasColumn('project_tasks', 'weight')) {
                    $table->decimal('weight', 8, 2)->default(1);
                }

                if (! Schema::hasColumn('project_tasks', 'completed_at')) {
                    $table->timestamp('completed_at')->nullable();
                }

                if (! Schema::hasColumn('project_tasks', 'task_order')) {
                    $table->unsignedInteger('task_order')->default(0);
                }
            });
        }
    }

    public function down(): void
    {
        // Safe repair migration: do not drop production data.
    }
};
