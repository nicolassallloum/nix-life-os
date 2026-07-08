<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('todo_tasks', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('project_id')
                ->nullable()
                ->constrained('todo_projects')
                ->nullOnDelete();

            $table->string('title');
            $table->text('description')->nullable();

            $table->string('task_type')->default('general');
            $table->string('status')->default('pending');
            $table->string('priority')->default('medium');

            $table->unsignedInteger('points')->default(0);

            $table->date('due_date')->nullable();
            $table->timestamp('completed_at')->nullable();

            $table->unsignedInteger('sort_order')->default(0);

            $table->longText('notes')->nullable();

            $table->timestamps();

            $table->index('user_id');
            $table->index('project_id');
            $table->index('status');
            $table->index('task_type');
            $table->index('sort_order');

            $table->index(['user_id', 'status'], 'todo_tasks_user_status_idx');
            $table->index(['user_id', 'task_type'], 'todo_tasks_user_type_idx');
            $table->index(['user_id', 'task_type', 'sort_order'], 'todo_tasks_user_type_sort_idx');
            $table->index(['project_id', 'status'], 'todo_tasks_project_status_idx');
            $table->index(['due_date'], 'todo_tasks_due_date_idx');
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("
                ALTER TABLE todo_tasks
                ADD CONSTRAINT todo_tasks_type_check
                CHECK (task_type IN ('general', 'monthly', 'weekly', 'daily'))
            ");

            DB::statement("
                ALTER TABLE todo_tasks
                ADD CONSTRAINT todo_tasks_status_check
                CHECK (status IN ('pending', 'in_progress', 'finished'))
            ");

            DB::statement("
                ALTER TABLE todo_tasks
                ADD CONSTRAINT todo_tasks_priority_check
                CHECK (priority IN ('low', 'medium', 'high'))
            ");

            DB::statement("
                ALTER TABLE todo_tasks
                ADD CONSTRAINT todo_tasks_points_check
                CHECK (points >= 0)
            ");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('todo_tasks');
    }
};