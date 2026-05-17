<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_recommendations', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->uuid('rule_id')->nullable();

            $table->string('module', 50);
            $table->string('recommendation_type', 100);

            $table->string('title', 255);
            $table->text('message');
            $table->text('action_text')->nullable();

            $table->string('severity', 50)->default('medium');
            $table->unsignedSmallInteger('priority')->default(3);

            $table->decimal('confidence_score', 5, 2)->default(0);
            $table->decimal('impact_score', 5, 2)->default(0);

            $table->string('status', 50)->default('pending');

            $table->string('period_key', 50)->nullable();
            $table->string('duplicate_key', 255)->nullable();

            $table->jsonb('source_data')->nullable();
            $table->jsonb('score_breakdown')->nullable();
            $table->jsonb('metadata')->nullable();

            $table->timestampTz('generated_at')->useCurrent();
            $table->timestampTz('viewed_at')->nullable();
            $table->timestampTz('accepted_at')->nullable();
            $table->timestampTz('dismissed_at')->nullable();
            $table->timestampTz('completed_at')->nullable();
            $table->timestampTz('expired_at')->nullable();
            $table->timestampTz('expires_at')->nullable();

            $table->timestampsTz();
            $table->softDeletesTz();

            $table->foreign('rule_id', 'fk_ai_recommendations_rule')
                ->references('id')
                ->on('ai_recommendation_rules')
                ->nullOnDelete();

            $table->index('user_id', 'idx_ai_recommendations_user');
            $table->index('rule_id', 'idx_ai_recommendations_rule');
            $table->index('module', 'idx_ai_recommendations_module');
            $table->index('recommendation_type', 'idx_ai_recommendations_type');
            $table->index('status', 'idx_ai_recommendations_status');
            $table->index('severity', 'idx_ai_recommendations_severity');
            $table->index('priority', 'idx_ai_recommendations_priority');
            $table->index('generated_at', 'idx_ai_recommendations_generated_at');
            $table->index('expires_at', 'idx_ai_recommendations_expires_at');

            $table->index(['user_id', 'status'], 'idx_ai_recommendations_user_status');
            $table->index(['user_id', 'module'], 'idx_ai_recommendations_user_module');
            $table->index(['user_id', 'severity', 'status'], 'idx_ai_recommendations_user_severity_status');

            $table->unique(['user_id', 'duplicate_key'], 'uq_ai_recommendations_user_duplicate_key');
        });

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_module
            CHECK (module IN ('finance', 'health', 'productivity', 'life_balance', 'goals', 'habits', 'system'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_severity
            CHECK (severity IN ('critical', 'high', 'medium', 'low', 'positive', 'info'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_priority
            CHECK (priority BETWEEN 1 AND 5)
        ");

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_status
            CHECK (status IN ('pending', 'viewed', 'accepted', 'dismissed', 'completed', 'expired'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_confidence
            CHECK (confidence_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_recommendations
            ADD CONSTRAINT chk_ai_recommendations_impact
            CHECK (impact_score BETWEEN 0 AND 100)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_recommendations');
    }
};