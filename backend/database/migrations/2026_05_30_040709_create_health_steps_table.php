<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nix_life_os.health_steps', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->date('entry_date');
            $table->unsignedInteger('steps')->default(0);
            $table->decimal('distance_km', 8, 2)->default(0);
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['user_id', 'entry_date']);
            $table->index(['user_id', 'entry_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_steps');
    }
};