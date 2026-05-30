<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nix_life_os.project_tasks', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('project_id')
                ->constrained('projects')
                ->cascadeOnDelete();

            $table->string('title', 200);
            $table->text('description')->nullable();
            $table->string('priority', 30)->default('medium'); // low, medium, high, critical
            $table->string('status', 30)->default('todo'); // todo, in_progress, done, blocked
            $table->date('start_date')->nullable();
            $table->date('due_date')->nullable();
            $table->string('assigned_to', 150)->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'project_id']);
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'due_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.project_tasks');
    }
};