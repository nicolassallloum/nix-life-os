<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('finance_transactions')) {
            Schema::table('finance_transactions', function (Blueprint $table) {
                if (! Schema::hasColumn('finance_transactions', 'transfer_account_id')) {
                    $table->uuid('transfer_account_id')->nullable()->after('account_id')->index();
                }

                if (! Schema::hasColumn('finance_transactions', 'category_id')) {
                    $table->uuid('category_id')->nullable()->after('transfer_account_id')->index();
                }

                if (! Schema::hasColumn('finance_transactions', 'reference_no')) {
                    $table->string('reference_no')->nullable()->after('description');
                }

                if (! Schema::hasColumn('finance_transactions', 'metadata_json')) {
                    $table->json('metadata_json')->nullable()->after('notes');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('finance_transactions')) {
            Schema::table('finance_transactions', function (Blueprint $table) {
                if (Schema::hasColumn('finance_transactions', 'metadata_json')) {
                    $table->dropColumn('metadata_json');
                }

                if (Schema::hasColumn('finance_transactions', 'reference_no')) {
                    $table->dropColumn('reference_no');
                }

                if (Schema::hasColumn('finance_transactions', 'category_id')) {
                    $table->dropColumn('category_id');
                }

                if (Schema::hasColumn('finance_transactions', 'transfer_account_id')) {
                    $table->dropColumn('transfer_account_id');
                }
            });
        }
    }
};