<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nix_life_os.health_medications', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('medication_name', 200);
            $table->string('dosage', 100);
            $table->time('medication_time');
            $table->string('frequency_type', 20); // daily, weekly
            $table->unsignedInteger('quantity')->default(1);
            $table->date('start_date');
            $table->date('stop_date')->nullable();
            $table->string('status', 30)->default('active'); // active, stopped, completed
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'start_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.health_medications');
    }
};