<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('finance_categories')) {
            Schema::create('finance_categories', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id')->nullable();
                $table->string('name');
                $table->string('type', 20)->default('expense');
                $table->string('icon')->nullable();
                $table->string('color', 20)->nullable();
                $table->string('status', 20)->default('active');
                $table->timestamps();
                $table->softDeletes();

                $table->index(['user_id', 'type']);
                $table->index(['user_id', 'status']);

                $table->foreign('user_id')
                    ->references('id')
                    ->on('users')
                    ->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('finance_categories');
    }
};
