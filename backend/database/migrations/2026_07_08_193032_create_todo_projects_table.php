<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('todo_projects', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->string('name');
            $table->text('description')->nullable();

            $table->string('status')->default('active');

            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();

            $table->timestamps();

            $table->index('user_id');
            $table->index('status');
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'start_date']);
            $table->index(['user_id', 'end_date']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("
                ALTER TABLE todo_projects
                ADD CONSTRAINT todo_projects_status_check
                CHECK (status IN ('active', 'completed', 'paused'))
            ");

            DB::statement("
                ALTER TABLE todo_projects
                ADD CONSTRAINT todo_projects_date_check
                CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
            ");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('todo_projects');
    }
};