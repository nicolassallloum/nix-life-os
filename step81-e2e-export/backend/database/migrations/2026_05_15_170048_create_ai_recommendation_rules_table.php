<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_recommendation_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('rule_code', 100)->unique();
            $table->string('rule_name', 255);

            $table->string('module', 50);
            $table->string('recommendation_type', 100);

            $table->string('condition_key', 150)->nullable();
            $table->string('operator', 30)->nullable();
            $table->decimal('threshold_value', 14, 4)->nullable();

            $table->jsonb('condition_payload')->nullable();

            $table->string('severity', 50)->default('medium');
            $table->unsignedSmallInteger('priority')->default(3);

            $table->string('title_template', 255);
            $table->text('message_template');
            $table->text('action_template')->nullable();

            $table->decimal('base_confidence_score', 5, 2)->default(70);
            $table->decimal('base_impact_score', 5, 2)->default(50);

            $table->boolean('is_active')->default(true);

            $table->timestampTz('valid_from')->nullable();
            $table->timestampTz('valid_to')->nullable();

            $table->jsonb('metadata')->nullable();

            $table->timestampsTz();
            $table->softDeletesTz();

            $table->index('module', 'idx_ai_rules_module');
            $table->index('recommendation_type', 'idx_ai_rules_type');
            $table->index('severity', 'idx_ai_rules_severity');
            $table->index('priority', 'idx_ai_rules_priority');
            $table->index('is_active', 'idx_ai_rules_active');
            $table->index(['module', 'is_active'], 'idx_ai_rules_module_active');
        });

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_module
            CHECK (module IN ('finance', 'health', 'productivity', 'life_balance', 'goals', 'habits', 'system'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_severity
            CHECK (severity IN ('critical', 'high', 'medium', 'low', 'positive', 'info'))
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_priority
            CHECK (priority BETWEEN 1 AND 5)
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_base_confidence
            CHECK (base_confidence_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_base_impact
            CHECK (base_impact_score BETWEEN 0 AND 100)
        ");

        DB::statement("
            ALTER TABLE ai_recommendation_rules
            ADD CONSTRAINT chk_ai_rules_operator
            CHECK (
                operator IS NULL OR operator IN (
                    '>', '>=', '<', '<=', '=', '!=',
                    'between', 'not_between',
                    'contains', 'not_contains',
                    'exists', 'not_exists'
                )
            )
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_recommendation_rules');
    }
};