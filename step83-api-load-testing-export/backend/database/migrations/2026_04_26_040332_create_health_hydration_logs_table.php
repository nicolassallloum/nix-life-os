<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_hydration_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();

            /*
            |--------------------------------------------------------------------------
            | User Relation
            |--------------------------------------------------------------------------
            | IMPORTANT:
            | Your users.id is UUID, so user_id must be UUID also.
            */
            $table->uuid('user_id');

            /*
            |--------------------------------------------------------------------------
            | Hydration Data
            |--------------------------------------------------------------------------
            */
            $table->date('log_date');
            $table->time('log_time')->nullable();

            $table->string('drink_type', 50)->default('water');
            $table->decimal('amount_ml', 8, 2);

            /*
            |--------------------------------------------------------------------------
            | Optional Health Fields
            |--------------------------------------------------------------------------
            */
            $table->boolean('is_ckd_safe')->default(true);
            $table->string('source', 50)->default('manual'); 
            // manual, quick_add, import, wearable

            $table->text('notes')->nullable();

            $table->timestamps();

            /*
            |--------------------------------------------------------------------------
            | Constraints / Indexes
            |--------------------------------------------------------------------------
            */
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'log_date']);
            $table->index(['user_id', 'drink_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_hydration_logs');
    }
};