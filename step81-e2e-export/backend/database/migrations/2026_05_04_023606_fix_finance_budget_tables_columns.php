<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('finance_budgets')) {
            Schema::table('finance_budgets', function (Blueprint $table) {
                if (! Schema::hasColumn('finance_budgets', 'metadata_json')) {
                    $table->json('metadata_json')->nullable();
                }

                if (! Schema::hasColumn('finance_budgets', 'notes')) {
                    $table->text('notes')->nullable();
                }

                if (! Schema::hasColumn('finance_budgets', 'is_active')) {
                    $table->boolean('is_active')->default(true);
                }
            });
        }

        if (Schema::hasTable('finance_budget_lines')) {
            Schema::table('finance_budget_lines', function (Blueprint $table) {
                if (! Schema::hasColumn('finance_budget_lines', 'actual_amount')) {
                    $table->decimal('actual_amount', 15, 2)->default(0);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'spent_amount')) {
                    $table->decimal('spent_amount', 15, 2)->default(0);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'warning_percentage')) {
                    $table->decimal('warning_percentage', 5, 2)->default(80);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'exceeded_percentage')) {
                    $table->decimal('exceeded_percentage', 5, 2)->default(100);
                }

                if (! Schema::hasColumn('finance_budget_lines', 'line_notes')) {
                    $table->text('line_notes')->nullable();
                }

                if (! Schema::hasColumn('finance_budget_lines', 'notes')) {
                    $table->text('notes')->nullable();
                }

                if (! Schema::hasColumn('finance_budget_lines', 'metadata_json')) {
                    $table->json('metadata_json')->nullable();
                }
            });
        }
    }

    public function down(): void
    {
        //
    }
};