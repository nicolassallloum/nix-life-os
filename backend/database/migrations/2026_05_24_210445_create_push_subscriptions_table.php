<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('push_subscriptions')) {
            Schema::create('push_subscriptions', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id')->index();

                $table->text('endpoint')->unique();
                $table->text('public_key')->nullable();
                $table->text('auth_token')->nullable();

                $table->string('browser', 100)->nullable();
                $table->string('platform', 100)->nullable();
                $table->string('device_name', 150)->nullable();

                $table->boolean('is_active')->default(true);
                $table->timestamp('last_used_at')->nullable();

                $table->timestamps();
            });

            return;
        }

        Schema::table('push_subscriptions', function (Blueprint $table) {
            if (! Schema::hasColumn('push_subscriptions', 'public_key')) {
                $table->text('public_key')->nullable();
            }

            if (! Schema::hasColumn('push_subscriptions', 'auth_token')) {
                $table->text('auth_token')->nullable();
            }

            if (! Schema::hasColumn('push_subscriptions', 'browser')) {
                $table->string('browser', 100)->nullable();
            }

            if (! Schema::hasColumn('push_subscriptions', 'platform')) {
                $table->string('platform', 100)->nullable();
            }

            if (! Schema::hasColumn('push_subscriptions', 'device_name')) {
                $table->string('device_name', 150)->nullable();
            }

            if (! Schema::hasColumn('push_subscriptions', 'is_active')) {
                $table->boolean('is_active')->default(true);
            }

            if (! Schema::hasColumn('push_subscriptions', 'last_used_at')) {
                $table->timestamp('last_used_at')->nullable();
            }
        });
    }

    public function down(): void
    {
        // Do not drop this table because it existed before this migration.
    }
};
