<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('finance_budget_lines')) {
            Schema::create('finance_budget_lines', function (Blueprint $table) {
                $table->uuid('id')->primary();

                $table->uuid('budget_id')->index();
                $table->uuid('user_id')->nullable()->index();

                $table->uuid('account_id')->nullable()->index();
                $table->uuid('category_id')->nullable()->index();

                $table->string('category')->nullable();

                $table->decimal('planned_amount', 15, 2)->default(0);
                $table->decimal('actual_amount', 15, 2)->default(0);
                $table->decimal('spent_amount', 15, 2)->default(0);

                $table->text('notes')->nullable();

                $table->timestamps();

                $table->index(['budget_id', 'account_id']);
                $table->index(['budget_id', 'category_id']);
            });
        }

        if (Schema::hasTable('finance_budget_lines')) {
            Schema::table('finance_budget_lines', function (Blueprint $table) {
                if (! Schema::hasColumn('finance_budget_lines', 'user_id')) {
                    $table->uuid('user_id')->nullable()->after('budget_id')->index();
                }

                if (! Schema::hasColumn('finance_budget_lines', 'account_id')) {
                    $table->uuid('account_id')->nullable()->after('user_id')->index();
                }

                if (! Schema::hasColumn('finance_budget_lines', 'category_id')) {
                    $table->uuid('category_id')->nullable()->after('account_id')->index();
                }

                if (! Schema::hasColumn('finance_budget_lines', 'category')) {
                    $table->string('category')->nullable()->after('category_id');
                }

                if (! Schema::hasColumn('finance_budget_lines', 'planned_amount')) {
                    $table->decimal('planned_amount', 15, 2)->default(0);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'actual_amount')) {
                    $table->decimal('actual_amount', 15, 2)->default(0);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'spent_amount')) {
                    $table->decimal('spent_amount', 15, 2)->default(0);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'notes')) {
                    $table->text('notes')->nullable();
                }
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('finance_budget_lines');
    }
};