<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('todo_tasks')) {
            return;
        }

        Schema::table('todo_tasks', function (Blueprint $table) {
            if (! Schema::hasColumn('todo_tasks', 'task_type')) {
                $table->string('task_type', 20)->default('general');
            }

            if (! Schema::hasColumn('todo_tasks', 'sort_order')) {
                $table->integer('sort_order')->default(0);
            }

            if (! Schema::hasColumn('todo_tasks', 'points')) {
                $table->integer('points')->default(0);
            }

            if (! Schema::hasColumn('todo_tasks', 'status')) {
                $table->string('status', 30)->default('pending');
            }

            if (! Schema::hasColumn('todo_tasks', 'completed_at')) {
                $table->timestamp('completed_at')->nullable();
            }

            if (! Schema::hasColumn('todo_tasks', 'due_date')) {
                $table->date('due_date')->nullable();
            }

            if (! Schema::hasColumn('todo_tasks', 'project_id')) {
                $table->unsignedBigInteger('project_id')->nullable();
            }
        });

        DB::statement("UPDATE todo_tasks SET task_type = 'general' WHERE task_type IS NULL OR task_type = ''");
        DB::statement("UPDATE todo_tasks SET sort_order = 0 WHERE sort_order IS NULL");
        DB::statement("UPDATE todo_tasks SET points = 0 WHERE points IS NULL");
        DB::statement("UPDATE todo_tasks SET status = 'pending' WHERE status IS NULL OR status = ''");

        if (Schema::hasTable('todo_projects') && Schema::hasColumn('todo_tasks', 'project_id')) {
            DB::statement(<<<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'todo_tasks_project_id_foreign'
          AND table_name = 'todo_tasks'
    ) THEN
        ALTER TABLE todo_tasks
        ADD CONSTRAINT todo_tasks_project_id_foreign
        FOREIGN KEY (project_id) REFERENCES todo_projects(id)
        ON DELETE SET NULL;
    END IF;
END $$;
SQL);
        }

        DB::statement('CREATE INDEX IF NOT EXISTS todo_tasks_user_type_sort_idx ON todo_tasks (user_id, task_type, sort_order)');
        DB::statement('CREATE INDEX IF NOT EXISTS todo_tasks_project_id_idx ON todo_tasks (project_id)');
        DB::statement('CREATE INDEX IF NOT EXISTS todo_tasks_status_idx ON todo_tasks (status)');
        DB::statement('CREATE INDEX IF NOT EXISTS todo_tasks_due_date_idx ON todo_tasks (due_date)');
        DB::statement('CREATE INDEX IF NOT EXISTS todo_tasks_created_at_idx ON todo_tasks (created_at)');
    }

    public function down(): void
    {
        if (! Schema::hasTable('todo_tasks')) {
            return;
        }

        DB::statement('DROP INDEX IF EXISTS todo_tasks_user_type_sort_idx');
        DB::statement('DROP INDEX IF EXISTS todo_tasks_project_id_idx');
        DB::statement('DROP INDEX IF EXISTS todo_tasks_status_idx');
        DB::statement('DROP INDEX IF EXISTS todo_tasks_due_date_idx');
        DB::statement('DROP INDEX IF EXISTS todo_tasks_created_at_idx');

        if (Schema::hasColumn('todo_tasks', 'project_id')) {
            DB::statement('ALTER TABLE todo_tasks DROP CONSTRAINT IF EXISTS todo_tasks_project_id_foreign');
        }
    }
};
