<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('productivity_happy_wins')) {
            Schema::create('productivity_happy_wins', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id');
                $table->string('title');
                $table->text('description')->nullable();
                $table->date('win_date');
                $table->string('mood')->nullable();
                $table->unsignedTinyInteger('score')->default(1);
                $table->jsonb('metadata')->nullable();
                $table->timestamps();

                $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
                $table->index(['user_id', 'win_date']);
                $table->index(['user_id', 'mood']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('productivity_happy_wins');
    }
};
