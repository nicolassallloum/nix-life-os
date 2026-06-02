<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('application_visits', function (Blueprint $table) {
            if (!Schema::hasColumn('application_visits', 'user_id')) {
                $table->uuid('user_id')->nullable()->after('id');
            }

            if (!Schema::hasColumn('application_visits', 'page_url')) {
                $table->string('page_url')->nullable()->after('user_id');
            }

            if (!Schema::hasColumn('application_visits', 'page_name')) {
                $table->string('page_name')->nullable()->after('page_url');
            }

            if (!Schema::hasColumn('application_visits', 'ip_address')) {
                $table->string('ip_address', 100)->nullable()->after('page_name');
            }

            if (!Schema::hasColumn('application_visits', 'user_agent')) {
                $table->text('user_agent')->nullable()->after('ip_address');
            }

            if (!Schema::hasColumn('application_visits', 'referrer')) {
                $table->text('referrer')->nullable()->after('user_agent');
            }

            if (!Schema::hasColumn('application_visits', 'visited_at')) {
                $table->timestamp('visited_at')->nullable()->after('referrer');
            }
        });
    }

    public function down(): void
    {
        Schema::table('application_visits', function (Blueprint $table) {
            foreach ([
                'user_id',
                'page_url',
                'page_name',
                'ip_address',
                'user_agent',
                'referrer',
                'visited_at',
            ] as $column) {
                if (Schema::hasColumn('application_visits', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
