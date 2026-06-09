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
        if (!Schema::hasTable('health_lab_tests')) {
            Schema::create('health_lab_tests', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->foreignId('category_id')->nullable()->constrained('health_test_categories')->nullOnDelete();
                $table->date('test_date')->nullable();
                $table->string('lab_name')->nullable();
                $table->string('doctor_name')->nullable();
                $table->string('file_path');
                $table->string('file_type')->nullable();
                $table->string('ai_status')->default('uploaded');
                $table->text('notes')->nullable();
                $table->json('extracted_payload')->nullable();
                $table->timestamp('approved_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'test_date']);
                $table->index(['category_id']);
                $table->index(['ai_status']);
            });

            return;
        }

        $this->addColumnIfMissing('health_lab_tests', 'user_id', fn (Blueprint $table) => $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete());
        $this->addColumnIfMissing('health_lab_tests', 'category_id', fn (Blueprint $table) => $table->foreignId('category_id')->nullable()->constrained('health_test_categories')->nullOnDelete());
        $this->addColumnIfMissing('health_lab_tests', 'test_date', fn (Blueprint $table) => $table->date('test_date')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'lab_name', fn (Blueprint $table) => $table->string('lab_name')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'doctor_name', fn (Blueprint $table) => $table->string('doctor_name')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'file_path', fn (Blueprint $table) => $table->string('file_path')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'file_type', fn (Blueprint $table) => $table->string('file_type')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'ai_status', fn (Blueprint $table) => $table->string('ai_status')->default('uploaded'));
        $this->addColumnIfMissing('health_lab_tests', 'notes', fn (Blueprint $table) => $table->text('notes')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'extracted_payload', fn (Blueprint $table) => $table->json('extracted_payload')->nullable());
        $this->addColumnIfMissing('health_lab_tests', 'approved_at', fn (Blueprint $table) => $table->timestamp('approved_at')->nullable());
    }

    public function down(): void
    {
        Schema::dropIfExists('health_lab_tests');
    }
};
