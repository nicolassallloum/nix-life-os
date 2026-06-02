<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('application_visits')) {
            return;
        }

        Schema::create('application_visits', function (Blueprint $table) {
            $table->id();
            $table->uuid('user_id')->nullable();
            $table->string('ip_address', 100)->nullable();
            $table->text('user_agent')->nullable();
            $table->text('page_url')->nullable();
            $table->string('page_name')->nullable();
            $table->text('referrer')->nullable();
            $table->timestamp('visited_at')->useCurrent();

            $table->index('user_id');
            $table->index('page_name');
            $table->index('visited_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('application_visits');
    }
};
