<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('notification_preferences')) {
            Schema::create('notification_preferences', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id')->nullable()->index();
                $table->string('notification_type', 100)->nullable()->index();

                $table->boolean('web_push_enabled')->default(true);
                $table->boolean('email_enabled')->default(false);
                $table->boolean('sms_enabled')->default(false);
                $table->boolean('in_app_enabled')->default(true);

                $table->boolean('quiet_hours_enabled')->default(false);
                $table->time('quiet_hours_start')->nullable();
                $table->time('quiet_hours_end')->nullable();

                $table->string('frequency', 50)->nullable();
                $table->decimal('threshold_value', 12, 2)->nullable();

                $table->timestamps();

                $table->unique(['user_id', 'notification_type'], 'notification_preferences_user_type_unique');
            });

            return;
        }

        Schema::table('notification_preferences', function (Blueprint $table) {
            if (! Schema::hasColumn('notification_preferences', 'user_id')) {
                $table->uuid('user_id')->nullable()->index();
            }

            if (! Schema::hasColumn('notification_preferences', 'notification_type')) {
                $table->string('notification_type', 100)->nullable()->index();
            }

            if (! Schema::hasColumn('notification_preferences', 'web_push_enabled')) {
                $table->boolean('web_push_enabled')->default(true);
            }

            if (! Schema::hasColumn('notification_preferences', 'email_enabled')) {
                $table->boolean('email_enabled')->default(false);
            }

            if (! Schema::hasColumn('notification_preferences', 'sms_enabled')) {
                $table->boolean('sms_enabled')->default(false);
            }

            if (! Schema::hasColumn('notification_preferences', 'in_app_enabled')) {
                $table->boolean('in_app_enabled')->default(true);
            }

            if (! Schema::hasColumn('notification_preferences', 'quiet_hours_enabled')) {
                $table->boolean('quiet_hours_enabled')->default(false);
            }

            if (! Schema::hasColumn('notification_preferences', 'quiet_hours_start')) {
                $table->time('quiet_hours_start')->nullable();
            }

            if (! Schema::hasColumn('notification_preferences', 'quiet_hours_end')) {
                $table->time('quiet_hours_end')->nullable();
            }

            if (! Schema::hasColumn('notification_preferences', 'frequency')) {
                $table->string('frequency', 50)->nullable();
            }

            if (! Schema::hasColumn('notification_preferences', 'threshold_value')) {
                $table->decimal('threshold_value', 12, 2)->nullable();
            }
        });
    }

    public function down(): void
    {
        // Do not drop this table because it existed before STEP 104.
    }
};
