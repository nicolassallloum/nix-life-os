<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('finance_accounts') && ! Schema::hasColumn('finance_accounts', 'description')) {
            Schema::table('finance_accounts', function (Blueprint $table) {
                $table->text('description')->nullable()->after('current_balance');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('finance_accounts') && Schema::hasColumn('finance_accounts', 'description')) {
            Schema::table('finance_accounts', function (Blueprint $table) {
                $table->dropColumn('description');
            });
        }
    }
};