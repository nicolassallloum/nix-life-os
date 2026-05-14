<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('productivity_habit_check_ins', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('habit_id');
            $table->date('check_in_date');
            $table->string('status')->default('completed'); // completed, missed, skipped
            $table->unsignedInteger('count')->default(1);
            $table->text('notes')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('habit_id')->references('id')->on('productivity_habits')->cascadeOnDelete();
            $table->unique(['habit_id', 'check_in_date']);
            $table->index(['user_id', 'check_in_date']);
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('productivity_habit_check_ins');
    }
};
