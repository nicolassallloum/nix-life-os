<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_milestones', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('project_id');

            $table->string('milestone_name');
            $table->text('description')->nullable();

            $table->date('target_date')->nullable();
            $table->date('completed_date')->nullable();

            $table->enum('status', [
                'pending',
                'in_progress',
                'completed',
                'blocked',
                'cancelled'
            ])->default('pending');

            $table->unsignedTinyInteger('progress_percentage')->default(0);
            $table->decimal('weight', 8, 2)->default(1);

            $table->jsonb('metadata')->nullable();

            $table->timestamps();

            $table->foreign('project_id')
                ->references('id')
                ->on('projects')
                ->cascadeOnDelete();

            $table->index(['project_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_milestones');
    }
};