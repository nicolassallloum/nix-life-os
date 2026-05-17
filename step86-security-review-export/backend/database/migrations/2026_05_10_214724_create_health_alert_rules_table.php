<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('health_alert_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->string('code')->unique();
            $table->string('name');

            $table->string('category', 100);
            $table->string('severity', 50)->default('warning');

            $table->decimal('warning_threshold', 12, 2)->nullable();
            $table->decimal('critical_threshold', 12, 2)->nullable();

            $table->string('operator', 20)->nullable();
            $table->string('unit', 50)->nullable();

            $table->boolean('is_active')->default(true);

            $table->json('metadata')->nullable();

            $table->timestamps();

            $table->index(['category', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_alert_rules');
    }
};
