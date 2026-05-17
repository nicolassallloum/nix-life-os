<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_recommendation_feedback', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('recommendation_id')
                ->constrained('ai_recommendations')
                ->cascadeOnDelete();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('feedback_type', 50);
            $table->unsignedSmallInteger('feedback_value')->nullable();
            $table->text('feedback_comment')->nullable();

            $table->jsonb('metadata')->nullable();

            $table->timestampsTz();
            $table->softDeletesTz();

            $table->index('recommendation_id', 'idx_ai_feedback_recommendation');
            $table->index('user_id', 'idx_ai_feedback_user');
            $table->index('feedback_type', 'idx_ai_feedback_type');
            $table->index('created_at', 'idx_ai_feedback_created_at');
            $table->index(['user_id', 'feedback_type'], 'idx_ai_feedback_user_type');
        });

        DB::statement("
            ALTER TABLE ai_recommendation_feedback
            ADD CONSTRAINT chk_ai_feedback_type
            CHECK (feedback_type IN ('useful', 'not_useful', 'too_late', 'not_relevant', 'accepted', 'dismissed', 'completed', 'rating'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_feedback
            ADD CONSTRAINT chk_ai_feedback_value
            CHECK (feedback_value IS NULL OR feedback_value BETWEEN 1 AND 5)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_recommendation_feedback');
    }
};