<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('user_point_logs')) {
            Schema::create('user_point_logs', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id');
                $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
                $table->string('module', 100);
                $table->string('action_name', 150);
                $table->integer('points');
                $table->string('reference_id')->nullable();
                $table->timestamp('created_at')->useCurrent();

                $table->index(['user_id', 'created_at']);
                $table->index(['module', 'action_name']);
                $table->index('reference_id');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_point_logs');
    }
};
