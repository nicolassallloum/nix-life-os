<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('website_usage_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('user_id')->nullable();
            $table->string('session_id')->nullable();
            $table->string('page_url')->nullable();
            $table->string('page_name')->nullable();
            $table->string('module_name')->nullable();
            $table->string('ip_address')->nullable();
            $table->string('browser')->nullable();
            $table->string('device')->nullable();
            $table->string('method')->nullable();
            $table->string('endpoint')->nullable();
            $table->integer('response_status')->nullable();
            $table->integer('response_time_ms')->nullable();
            $table->timestamps();

            $table->index('user_id');
            $table->index('module_name');
            $table->index('page_name');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('website_usage_logs');
    }
};