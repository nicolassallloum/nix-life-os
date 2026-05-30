<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nix_life_os.health_sleep_logs', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('entry_date');
            $table->time('sleep_start')->nullable();
            $table->time('sleep_end')->nullable();
            $table->decimal('duration_hours', 4, 2);
            $table->string('quality', 30)->nullable(); // poor, fair, good, excellent
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'entry_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.health_sleep_logs');
    }
};