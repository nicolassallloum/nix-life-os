<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_insights', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id')->index();

            $table->string('insight_type', 50)->index();
            // daily_summary, finance, health, project, productivity, recommendation

            $table->string('category', 100)->nullable()->index();
            // finance, health, projects, unified

            $table->string('title');
            $table->text('message');

            $table->string('severity', 30)->default('info')->index();
            // info, success, warning, critical

            $table->decimal('score', 8, 2)->nullable();
            $table->jsonb('metadata')->nullable();

            $table->date('insight_date')->index();

            $table->boolean('is_read')->default(false);
            $table->boolean('is_archived')->default(false);

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'insight_date']);
            $table->index(['user_id', 'severity']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_insights');
    }
};