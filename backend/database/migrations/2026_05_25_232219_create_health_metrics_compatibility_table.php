<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('health_metrics')) {
            Schema::create('health_metrics', function (Blueprint $table) {
                $table->id();
                $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('metric_type')->nullable()->index();
                $table->decimal('value', 12, 2)->nullable();
                $table->string('unit')->nullable();
                $table->date('recorded_date')->nullable()->index();
                $table->timestamp('recorded_at')->nullable()->index();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'metric_type']);
                $table->index(['user_id', 'recorded_date']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_metrics');
    }
};
