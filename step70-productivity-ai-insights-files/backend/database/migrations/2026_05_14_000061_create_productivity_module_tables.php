<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('productivity_tasks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('todo'); // todo, in_progress, completed, cancelled
            $table->string('priority')->default('medium'); // low, medium, high, critical
            $table->decimal('progress_percentage', 5, 2)->default(0);
            $table->date('start_date')->nullable();
            $table->date('due_date')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'due_date']);
            $table->index(['user_id', 'priority']);
        });

        Schema::create('productivity_habits', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('status')->default('active'); // active, paused, archived
            $table->string('frequency')->default('daily'); // daily, weekly, monthly
            $table->unsignedInteger('target_count')->default(1);
            $table->unsignedInteger('completed_count_today')->default(0);
            $table->unsignedInteger('current_streak')->default(0);
            $table->unsignedInteger('best_streak')->default(0);
            $table->timestamp('last_completed_at')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'frequency']);
            $table->index(['user_id', 'last_completed_at']);
        });

        Schema::create('productivity_goals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('active'); // active, completed, on_hold, cancelled
            $table->string('category')->nullable();
            $table->string('priority')->default('medium');
            $table->decimal('progress_percentage', 5, 2)->default(0);
            $table->date('target_date')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'target_date']);
            $table->index(['user_id', 'category']);
        });

        Schema::create('productivity_calendar_events', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('event_type')->default('task'); // task, focus, meeting, reminder, personal
            $table->string('status')->default('scheduled'); // scheduled, completed, cancelled
            $table->timestamp('start_time');
            $table->timestamp('end_time')->nullable();
            $table->string('location')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'start_time']);
            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'event_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('productivity_calendar_events');
        Schema::dropIfExists('productivity_goals');
        Schema::dropIfExists('productivity_habits');
        Schema::dropIfExists('productivity_tasks');
    }
};
