<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('health_test_categories')) {
            Schema::create('health_test_categories', function (Blueprint $table) {
                $table->id();
                $table->string('name')->unique();
                $table->string('slug')->unique();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }

        $categories = [
            ['name' => 'Urine Test', 'slug' => 'urine-test'],
            ['name' => 'Blood Test', 'slug' => 'blood-test'],
            ['name' => 'Image', 'slug' => 'image'],
        ];

        foreach ($categories as $category) {
            DB::table('health_test_categories')->updateOrInsert(
                ['slug' => $category['slug']],
                [
                    'name' => $category['name'],
                    'is_active' => true,
                    'updated_at' => now(),
                    'created_at' => DB::raw('COALESCE(created_at, NOW())'),
                ]
            );
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('health_test_categories');
    }
};
