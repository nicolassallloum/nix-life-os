<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private function userIdColumn(Blueprint $table): void
    {
        $table->uuid('user_id');
        $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
    }

    public function up(): void
    {
        if (!Schema::hasTable('health_user_goals')) {
            Schema::create('health_user_goals', function (Blueprint $table) {
                $table->id();
                $this->userIdColumn($table);

                $table->integer('daily_steps_goal')->default(8000);
                $table->decimal('target_weight_kg', 8, 2)->nullable();
                $table->integer('daily_calories_goal')->default(1800);
                $table->integer('daily_water_goal_ml')->default(2000);

                $table->decimal('protein_limit_g', 8, 2)->nullable();
                $table->decimal('carbs_limit_g', 8, 2)->nullable();
                $table->decimal('fat_limit_g', 8, 2)->nullable();
                $table->decimal('sugar_limit_g', 8, 2)->nullable();

                $table->decimal('sodium_limit_mg', 10, 2)->nullable();
                $table->decimal('potassium_limit_mg', 10, 2)->nullable();
                $table->decimal('phosphorus_limit_mg', 10, 2)->nullable();

                $table->timestamps();

                $table->unique('user_id');
            });
        }

        if (!Schema::hasTable('health_step_logs')) {
            Schema::create('health_step_logs', function (Blueprint $table) {
                $table->id();
                $this->userIdColumn($table);

                $table->date('log_date');
                $table->integer('steps')->default(0);
                $table->decimal('kilometers', 10, 3)->default(0);
                $table->decimal('calories_burned', 10, 2)->default(0);
                $table->string('source')->default('manual');
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'log_date']);
                $table->index(['user_id', 'log_date']);
            });
        }

        if (!Schema::hasTable('health_medication_times')) {
            Schema::create('health_medication_times', function (Blueprint $table) {
                $table->id();
                $table->uuid('medication_id');
                $table->time('dosage_time');
                $table->string('dosage_note')->nullable();
                $table->timestamps();

                $table->foreign('medication_id')
                    ->references('id')
                    ->on('health_medications')
                    ->cascadeOnDelete();

                $table->index('medication_id');
            });
        }

        if (!Schema::hasTable('health_lab_test_results')) {
            Schema::create('health_lab_test_results', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('lab_test_id');

                $table->string('test_name');
                $table->string('result_value')->nullable();
                $table->string('unit')->nullable();
                $table->string('reference_min')->nullable();
                $table->string('reference_max')->nullable();
                $table->text('reference_text')->nullable();
                $table->string('status')->default('unknown');
                $table->date('result_date')->nullable();
                $table->string('doctor_name')->nullable();
                $table->decimal('ai_confidence', 5, 2)->nullable();
                $table->boolean('user_approved')->default(false);
                $table->timestamps();

                $table->foreign('lab_test_id')
                    ->references('id')
                    ->on('health_lab_tests')
                    ->cascadeOnDelete();

                $table->index('lab_test_id');
                $table->index('status');
            });
        }

        if (Schema::hasTable('health_hydration_logs')) {
            Schema::table('health_hydration_logs', function (Blueprint $table) {
                if (!Schema::hasColumn('health_hydration_logs', 'hydration_type')) {
                    $table->string('hydration_type')->nullable()->after('log_time');
                }

                if (!Schema::hasColumn('health_hydration_logs', 'quantity_ml')) {
                    $table->integer('quantity_ml')->nullable()->after('hydration_type');
                }
            });

            if (Schema::hasColumn('health_hydration_logs', 'drink_type')) {
                DB::table('health_hydration_logs')
                    ->whereNull('hydration_type')
                    ->update(['hydration_type' => DB::raw('drink_type')]);
            }

            if (Schema::hasColumn('health_hydration_logs', 'amount_ml')) {
                DB::table('health_hydration_logs')
                    ->whereNull('quantity_ml')
                    ->update(['quantity_ml' => DB::raw('amount_ml')]);
            }
        }

        if (Schema::hasTable('health_medications')) {
            Schema::table('health_medications', function (Blueprint $table) {
                if (!Schema::hasColumn('health_medications', 'daily_times')) {
                    $table->integer('daily_times')->nullable()->after('dosage');
                }

                if (!Schema::hasColumn('health_medications', 'doctor_name')) {
                    $table->string('doctor_name')->nullable()->after('status');
                }
            });

            DB::table('health_medications')
                ->whereNull('daily_times')
                ->update(['daily_times' => 1]);

            if (Schema::hasColumn('health_medications', 'prescribed_by')) {
                DB::table('health_medications')
                    ->whereNull('doctor_name')
                    ->update(['doctor_name' => DB::raw('prescribed_by')]);
            }
        }

        if (Schema::hasTable('health_lab_tests')) {
            Schema::table('health_lab_tests', function (Blueprint $table) {
                if (!Schema::hasColumn('health_lab_tests', 'doctor_name')) {
                    $table->string('doctor_name')->nullable()->after('lab_name');
                }

                if (!Schema::hasColumn('health_lab_tests', 'file_path')) {
                    $table->string('file_path')->nullable()->after('doctor_name');
                }

                if (!Schema::hasColumn('health_lab_tests', 'file_type')) {
                    $table->string('file_type')->nullable()->after('file_path');
                }

                if (!Schema::hasColumn('health_lab_tests', 'ai_status')) {
                    $table->string('ai_status')->default('pending')->after('file_type');
                }
            });

            if (Schema::hasColumn('health_lab_tests', 'doctor_notes')) {
                DB::table('health_lab_tests')
                    ->whereNull('doctor_name')
                    ->update(['doctor_name' => DB::raw('doctor_notes')]);
            }

            if (Schema::hasColumn('health_lab_tests', 'attachment_path')) {
                DB::table('health_lab_tests')
                    ->whereNull('file_path')
                    ->update(['file_path' => DB::raw('attachment_path')]);
            }
        }

        if (Schema::hasTable('health_nutrition_logs')) {
            Schema::table('health_nutrition_logs', function (Blueprint $table) {
                if (!Schema::hasColumn('health_nutrition_logs', 'protein_g')) {
                    $table->decimal('protein_g', 10, 2)->nullable()->after('calories');
                }

                if (!Schema::hasColumn('health_nutrition_logs', 'carbs_g')) {
                    $table->decimal('carbs_g', 10, 2)->nullable()->after('protein_g');
                }

                if (!Schema::hasColumn('health_nutrition_logs', 'fat_g')) {
                    $table->decimal('fat_g', 10, 2)->nullable()->after('carbs_g');
                }

                if (!Schema::hasColumn('health_nutrition_logs', 'sodium_mg')) {
                    $table->decimal('sodium_mg', 10, 2)->nullable()->after('fat_g');
                }

                if (!Schema::hasColumn('health_nutrition_logs', 'potassium_mg')) {
                    $table->decimal('potassium_mg', 10, 2)->nullable()->after('sodium_mg');
                }

                if (!Schema::hasColumn('health_nutrition_logs', 'phosphorus_mg')) {
                    $table->decimal('phosphorus_mg', 10, 2)->nullable()->after('potassium_mg');
                }
            });

            if (Schema::hasColumn('health_nutrition_logs', 'protein')) {
                DB::table('health_nutrition_logs')
                    ->whereNull('protein_g')
                    ->update(['protein_g' => DB::raw('protein')]);
            }

            if (Schema::hasColumn('health_nutrition_logs', 'sodium')) {
                DB::table('health_nutrition_logs')
                    ->whereNull('sodium_mg')
                    ->update(['sodium_mg' => DB::raw('sodium')]);
            }

            if (Schema::hasColumn('health_nutrition_logs', 'potassium')) {
                DB::table('health_nutrition_logs')
                    ->whereNull('potassium_mg')
                    ->update(['potassium_mg' => DB::raw('potassium')]);
            }

            if (Schema::hasColumn('health_nutrition_logs', 'phosphorus')) {
                DB::table('health_nutrition_logs')
                    ->whereNull('phosphorus_mg')
                    ->update(['phosphorus_mg' => DB::raw('phosphorus')]);
            }
        }

        if (Schema::hasTable('health_weight_logs')) {
            Schema::table('health_weight_logs', function (Blueprint $table) {
                if (!Schema::hasColumn('health_weight_logs', 'body_fat_percent')) {
                    $table->decimal('body_fat_percent', 8, 2)->nullable()->after('weight_kg');
                }
            });

            if (Schema::hasColumn('health_weight_logs', 'body_fat_percentage')) {
                DB::table('health_weight_logs')
                    ->whereNull('body_fat_percent')
                    ->update(['body_fat_percent' => DB::raw('body_fat_percentage')]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_lab_test_results');
        Schema::dropIfExists('health_medication_times');
        Schema::dropIfExists('health_step_logs');
        Schema::dropIfExists('health_user_goals');
    }
};
