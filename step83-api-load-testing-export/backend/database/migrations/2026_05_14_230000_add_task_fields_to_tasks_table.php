<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tasks')) {
            Schema::create('tasks', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id');
                $table->string('title');
                $table->text('description')->nullable();
                $table->string('status')->default('pending');
                $table->string('priority')->default('medium');
                $table->date('due_date')->nullable();
                $table->timestamp('completed_at')->nullable();
                $table->softDeletes();
                $table->timestamps();

                $table->foreign('user_id')
                    ->references('id')
                    ->on('users')
                    ->cascadeOnDelete();

                $table->index(['user_id', 'status']);
                $table->index(['user_id', 'priority']);
                $table->index(['due_date']);
            });

            return;
        }

        Schema::table('tasks', function (Blueprint $table) {
            if (!Schema::hasColumn('tasks', 'user_id')) {
                $table->uuid('user_id')->nullable()->after('id');
            }

            if (!Schema::hasColumn('tasks', 'title')) {
                $table->string('title')->nullable()->after('user_id');
            }

            if (!Schema::hasColumn('tasks', 'description')) {
                $table->text('description')->nullable()->after('title');
            }

            if (!Schema::hasColumn('tasks', 'status')) {
                $table->string('status')->default('pending')->after('description');
            }

            if (!Schema::hasColumn('tasks', 'priority')) {
                $table->string('priority')->default('medium')->after('status');
            }

            if (!Schema::hasColumn('tasks', 'due_date')) {
                $table->date('due_date')->nullable()->after('priority');
            }

            if (!Schema::hasColumn('tasks', 'completed_at')) {
                $table->timestamp('completed_at')->nullable()->after('due_date');
            }

            if (!Schema::hasColumn('tasks', 'deleted_at')) {
                $table->softDeletes();
            }
        });

        Schema::table('tasks', function (Blueprint $table) {
            try {
                $table->foreign('user_id')
                    ->references('id')
                    ->on('users')
                    ->cascadeOnDelete();
            } catch (\Throwable $e) {
                // Ignore if constraint already exists.
            }

            try {
                $table->index(['user_id', 'status']);
                $table->index(['user_id', 'priority']);
                $table->index(['due_date']);
            } catch (\Throwable $e) {
                // Ignore duplicate index errors.
            }
        });
    }

    public function down(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            if (Schema::hasColumn('tasks', 'deleted_at')) {
                $table->dropSoftDeletes();
            }

            foreach ([
                'completed_at',
                'due_date',
                'priority',
                'status',
                'description',
                'title',
                'user_id',
            ] as $column) {
                if (Schema::hasColumn('tasks', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
