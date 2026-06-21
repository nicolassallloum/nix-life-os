<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private array $levels = [
        1 => 0,
        2 => 50000,
        3 => 125000,
        4 => 225000,
        5 => 350000,
        6 => 500000,
        7 => 650000,
        8 => 800000,
        9 => 950000,
        10 => 1000000,
    ];

    public function up(): void
    {
        if (Schema::hasTable('project_goals')) {
            Schema::table('project_goals', function (Blueprint $table) {
                if (! Schema::hasColumn('project_goals', 'target_value')) {
                    $table->decimal('target_value', 14, 3)->nullable()->after('progress_percentage');
                }

                if (! Schema::hasColumn('project_goals', 'current_value')) {
                    $table->decimal('current_value', 14, 3)->default(0)->after('target_value');
                }

                if (! Schema::hasColumn('project_goals', 'unit')) {
                    $table->string('unit', 50)->nullable()->after('current_value');
                }

                if (! Schema::hasColumn('project_goals', 'linked_module')) {
                    $table->string('linked_module', 100)->nullable()->after('unit');
                }

                if (! Schema::hasColumn('project_goals', 'linked_metric')) {
                    $table->string('linked_metric', 100)->nullable()->after('linked_module');
                }

                if (! Schema::hasColumn('project_goals', 'last_progress_sync_at')) {
                    $table->timestamp('last_progress_sync_at')->nullable()->after('linked_metric');
                }
            });
        }

        if (! Schema::hasTable('admin_point_ideas')) {
            Schema::create('admin_point_ideas', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->nullable();

                $table->string('name');
                $table->text('description')->nullable();

                $table->integer('points')->default(0);
                $table->integer('target_points')->nullable();
                $table->integer('level')->nullable();

                $table->string('status')->default('active');
                $table->json('metadata')->nullable();

                $table->timestamps();

                $table->foreign('user_id')->references('id')->on('users')->nullOnDelete();

                $table->index(['status', 'level']);
                $table->index(['target_points']);
                $table->index(['user_id']);
            });
        }

        if (! Schema::hasTable('admin_point_levels')) {
            Schema::create('admin_point_levels', function (Blueprint $table) {
                $table->id();
                $table->integer('level')->unique();
                $table->integer('required_points');
                $table->string('label')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['required_points']);
            });
        }

        foreach ($this->levels as $level => $requiredPoints) {
            $exists = DB::table('admin_point_levels')
                ->where('level', $level)
                ->exists();

            DB::table('admin_point_levels')->updateOrInsert(
                ['level' => $level],
                [
                    'required_points' => $requiredPoints,
                    'label' => "Level {$level}",
                    'metadata' => json_encode([
                        'source' => 'nix_life_os_admin_points',
                    ]),
                    'updated_at' => now(),
                    'created_at' => $exists ? DB::raw('created_at') : now(),
                ]
            );
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_point_ideas');
        Schema::dropIfExists('admin_point_levels');

        if (Schema::hasTable('project_goals')) {
            Schema::table('project_goals', function (Blueprint $table) {
                foreach ([
                    'last_progress_sync_at',
                    'linked_metric',
                    'linked_module',
                    'unit',
                    'current_value',
                    'target_value',
                ] as $column) {
                    if (Schema::hasColumn('project_goals', $column)) {
                        $table->dropColumn($column);
                    }
                }
            });
        }
    }
};
