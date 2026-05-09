<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('health_lab_tests')) {
            return;
        }

        Schema::create('health_lab_tests', function (Blueprint $table) {
            $table->id();

            $table->uuid('user_id')->nullable();

            $table->date('test_date')->nullable();
            $table->string('test_name');
            $table->string('result_value')->nullable();
            $table->string('unit')->nullable();
            $table->string('reference_range')->nullable();
            $table->string('lab_name')->nullable();
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index('user_id');
            $table->index('test_date');
            $table->index('test_name');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_lab_tests');
    }
};