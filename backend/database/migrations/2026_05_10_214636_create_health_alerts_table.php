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
        Schema::create('health_alerts', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->foreignUuid('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('alert_type', 100);
            $table->string('category', 100);

            $table->string('severity', 50)->default('warning');
            $table->string('status', 50)->default('active');

            $table->string('title');
            $table->text('message')->nullable();

            $table->date('alert_date')->nullable();

            $table->string('source_table')->nullable();
            $table->uuid('source_id')->nullable();

            $table->json('metadata')->nullable();

            $table->timestamp('read_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('dismissed_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'category']);
            $table->index(['user_id', 'severity']);
            $table->index(['user_id', 'alert_date']);
            $table->index(['alert_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_alerts');
    }
};
