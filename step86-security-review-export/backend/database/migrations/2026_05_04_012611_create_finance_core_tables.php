<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('finance_accounts')) {
            Schema::create('finance_accounts', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->nullable()->index();

                $table->string('account_name');
                $table->string('account_type', 50);
                $table->string('currency_code', 10)->default('USD');

                $table->decimal('opening_balance', 15, 2)->default(0);
                $table->decimal('current_balance', 15, 2)->default(0);

                $table->boolean('is_active')->default(true);
                $table->text('notes')->nullable();

                $table->timestamps();

                $table->index(['user_id', 'account_type']);
                $table->index(['user_id', 'is_active']);
            });
        }

        if (! Schema::hasTable('finance_transactions')) {
            Schema::create('finance_transactions', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->nullable()->index();
                $table->uuid('account_id')->nullable()->index();

                $table->string('transaction_type', 50);
                $table->string('category')->nullable();

                $table->decimal('amount', 15, 2);
                $table->string('currency_code', 10)->default('USD');

                $table->date('transaction_date')->nullable();
                $table->string('description')->nullable();
                $table->text('notes')->nullable();

                $table->timestamps();

                $table->index(['user_id', 'transaction_type']);
                $table->index(['user_id', 'transaction_date']);
                $table->index(['account_id', 'transaction_date']);
            });
        }

        if (! Schema::hasTable('finance_budgets')) {
            Schema::create('finance_budgets', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->nullable()->index();

                $table->string('budget_name');
                $table->string('category')->nullable();

                $table->decimal('budget_amount', 15, 2)->default(0);
                $table->decimal('spent_amount', 15, 2)->default(0);

                $table->string('budget_month', 20);
                $table->string('currency_code', 10)->default('USD');

                $table->boolean('is_active')->default(true);
                $table->text('notes')->nullable();

                $table->timestamps();

                $table->index(['user_id', 'budget_month']);
                $table->index(['user_id', 'category']);
                $table->index(['user_id', 'is_active']);
            });
        }

        try {
            DB::statement('
                ALTER TABLE finance_transactions
                ADD CONSTRAINT finance_transactions_account_id_foreign
                FOREIGN KEY (account_id)
                REFERENCES finance_accounts(id)
                ON DELETE SET NULL
            ');
        } catch (\Throwable $e) {
            // Ignore if constraint already exists.
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('finance_transactions');
        Schema::dropIfExists('finance_budgets');
        Schema::dropIfExists('finance_accounts');
    }
};