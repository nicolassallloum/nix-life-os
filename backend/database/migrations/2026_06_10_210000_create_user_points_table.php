<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('user_points')) {
            Schema::create('user_points', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id');
                $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
                $table->integer('points')->default(0);
                $table->integer('level')->default(1);
                $table->integer('total_points')->default(0);
                $table->timestamps();

                $table->unique('user_id');
                $table->index(['level', 'points']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_points');
    }
};
