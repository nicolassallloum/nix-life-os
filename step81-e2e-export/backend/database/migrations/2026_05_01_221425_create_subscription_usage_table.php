<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_usage', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('user_id');
            $table->uuid('subscription_id');

            $table->integer('finance_accounts_count')->default(0);
            $table->integer('projects_count')->default(0);
            $table->integer('ai_insights_used')->default(0);
            $table->integer('notifications_sent')->default(0);

            $table->date('period_start');
            $table->date('period_end');

            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->foreign('subscription_id')
                ->references('id')
                ->on('subscriptions')
                ->cascadeOnDelete();

            $table->index('user_id');
            $table->index('subscription_id');

            $table->unique(['user_id', 'subscription_id', 'period_start', 'period_end']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_usage');
    }
};