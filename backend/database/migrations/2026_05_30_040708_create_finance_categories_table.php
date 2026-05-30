<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nix_life_os.finance_categories', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('name', 150);
            $table->string('type', 20); // income, expense
            $table->string('icon', 100)->nullable();
            $table->string('color', 30)->nullable();
            $table->string('status', 30)->default('active'); // active, inactive

            $table->timestamps();

            $table->unique(['user_id', 'name', 'type']);
            $table->index(['user_id', 'type']);
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('finance_categories');
    }
};