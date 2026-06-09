<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private function addColumnIfMissing(string $table, string $column, callable $callback): void
    {
        if (!Schema::hasColumn($table, $column)) {
            Schema::table($table, function (Blueprint $blueprint) use ($callback) {
                $callback($blueprint);
            });
        }
    }

    public function up(): void
    {
        if (!Schema::hasTable('health_lab_test_results')) {
            Schema::create('health_lab_test_results', function (Blueprint $table) {
                $table->id();
                $table->foreignId('lab_test_id')->constrained('health_lab_tests')->cascadeOnDelete();
                $table->string('test_name');
                $table->decimal('result_value', 12, 4)->nullable();
                $table->string('unit')->nullable();
                $table->decimal('reference_min', 12, 4)->nullable();
                $table->decimal('reference_max', 12, 4)->nullable();
                $table->text('reference_text')->nullable();
                $table->string('status')->nullable();
                $table->date('result_date')->nullable();
                $table->string('doctor_name')->nullable();
                $table->unsignedTinyInteger('ai_confidence')->nullable();
                $table->boolean('user_approved')->default(false);
                $table->timestamps();

                $table->index(['lab_test_id']);
                $table->index(['status']);
                $table->index(['user_approved']);
            });

            return;
        }

        $this->addColumnIfMissing('health_lab_test_results', 'lab_test_id', fn (Blueprint $table) => $table->foreignId('lab_test_id')->nullable()->constrained('health_lab_tests')->cascadeOnDelete());
        $this->addColumnIfMissing('health_lab_test_results', 'test_name', fn (Blueprint $table) => $table->string('test_name')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'result_value', fn (Blueprint $table) => $table->decimal('result_value', 12, 4)->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'unit', fn (Blueprint $table) => $table->string('unit')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'reference_min', fn (Blueprint $table) => $table->decimal('reference_min', 12, 4)->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'reference_max', fn (Blueprint $table) => $table->decimal('reference_max', 12, 4)->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'reference_text', fn (Blueprint $table) => $table->text('reference_text')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'status', fn (Blueprint $table) => $table->string('status')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'result_date', fn (Blueprint $table) => $table->date('result_date')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'doctor_name', fn (Blueprint $table) => $table->string('doctor_name')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'ai_confidence', fn (Blueprint $table) => $table->unsignedTinyInteger('ai_confidence')->nullable());
        $this->addColumnIfMissing('health_lab_test_results', 'user_approved', fn (Blueprint $table) => $table->boolean('user_approved')->default(false));
    }

    public function down(): void
    {
        Schema::dropIfExists('health_lab_test_results');
    }
};
