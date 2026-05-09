<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('health_lab_tests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');

            $table->string('test_name');
            $table->string('test_category')->nullable();
            $table->decimal('test_value', 12, 3)->nullable();
            $table->string('unit')->nullable();
            $table->decimal('normal_min', 12, 3)->nullable();
            $table->decimal('normal_max', 12, 3)->nullable();
            $table->string('status')->default('normal');

            $table->date('test_date');
            $table->string('lab_name')->nullable();
            $table->string('doctor_name')->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            $table->index(['user_id', 'test_date']);
            $table->index(['user_id', 'test_name']);
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_lab_tests');
    }
};