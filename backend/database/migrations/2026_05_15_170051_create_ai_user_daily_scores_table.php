<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_user_daily_scores', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('score_date');

            $table->decimal('finance_score', 5, 2)->default(0);
            $table->decimal('health_score', 5, 2)->default(0);
            $table->decimal('productivity_score', 5, 2)->default(0);
            $table->decimal('goals_score', 5, 2)->default(0);
            $table->decimal('habits_score', 5, 2)->default(0);
            $table->decimal('life_balance_score', 5, 2)->default(0);

            $table->string('classification', 50)->nullable();

            $table->jsonb('score_breakdown')->nullable();
            $table->jsonb('source_summary')->nullable();
            $table->jsonb('metadata')->nullable();

            $table->timestampsTz();
            $table->softDeletesTz();

            $table->unique(['user_id', 'score_date'], 'uq_ai_user_daily_scores_user_date');

            $table->index('user_id', 'idx_ai_daily_scores_user');
            $table->index('score_date', 'idx_ai_daily_scores_date');
            $table->index('classification', 'idx_ai_daily_scores_classification');
            $table->index(['user_id', 'score_date'], 'idx_ai_daily_scores_user_date');
        });

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_finance
            CHECK (finance_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_health
            CHECK (health_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_productivity
            CHECK (productivity_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_goals
            CHECK (goals_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_habits
            CHECK (habits_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_life_balance
            CHECK (life_balance_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_user_daily_scores
            ADD CONSTRAINT chk_ai_daily_scores_classification
            CHECK (
                classification IS NULL OR classification IN (
                    'excellent',
                    'good',
                    'needs_attention',
                    'risk',
                    'critical'
                )
            )
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_user_daily_scores');
    }
};