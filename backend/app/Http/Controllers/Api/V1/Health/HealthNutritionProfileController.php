<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthNutritionProfileResource;
use App\Models\HealthNutritionProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Throwable;

class HealthNutritionProfileController extends Controller
{
    public function index(Request $request)
    {
        $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        if (! $profile) {
            $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
                ->latest('updated_at')
                ->first();
        }

        return response()->json([
            'success' => true,
            'data' => $profile ? new HealthNutritionProfileResource($profile) : null,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'profile_name' => ['nullable', 'string', 'max:255'],
            'daily_calories_min' => ['nullable', 'integer', 'min:0'],
            'daily_calories_max' => ['nullable', 'integer', 'min:0'],
            'daily_protein_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_carbs_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_fat_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_sodium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_potassium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_phosphorus_max_mg' => ['nullable', 'numeric', 'min:0'],
            'is_ckd_safe_mode' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        $userId = $request->user()->id;

        try {
            $profile = DB::transaction(function () use ($data, $userId) {
                $profile = HealthNutritionProfile::where('user_id', $userId)
                    ->where('is_active', true)
                    ->lockForUpdate()
                    ->first();

                if (! $profile) {
                    $profile = HealthNutritionProfile::where('user_id', $userId)
                        ->latest('updated_at')
                        ->lockForUpdate()
                        ->first();
                }

                $payload = [
                    ...$data,
                    'user_id' => $userId,
                    'profile_name' => $data['profile_name'] ?? 'CKD Daily Nutrition Profile',
                    'is_active' => true,
                    'is_ckd_safe_mode' => $data['is_ckd_safe_mode'] ?? true,
                ];

                if ($profile) {
                    $profile->fill($payload);
                    $profile->save();
                } else {
                    $profile = HealthNutritionProfile::create($payload);
                }

                $this->syncHealthGoals($userId, $profile);

                return $profile->fresh();
            });

            return response()->json([
                'success' => true,
                'message' => 'Nutrition goals updated successfully.',
                'data' => new HealthNutritionProfileResource($profile),
            ]);
        } catch (Throwable $exception) {
            Log::error('Nutrition goals update failed', [
                'user_id' => $userId,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to save nutrition goals.',
                'error' => config('app.debug') ? $exception->getMessage() : null,
            ], 500);
        }
    }

    private function syncHealthGoals(string $userId, HealthNutritionProfile $profile): void
    {
        if (! Schema::hasTable('health_user_goals') || ! Schema::hasColumn('health_user_goals', 'user_id')) {
            return;
        }

        $now = now();

        $payload = [];

        $columnMap = [
            'daily_calories_goal' => $profile->daily_calories_max,
            'protein_limit_g' => $profile->daily_protein_max_g,
            'carbs_limit_g' => $profile->daily_carbs_max_g,
            'fat_limit_g' => $profile->daily_fat_max_g,
            'sodium_limit_mg' => $profile->daily_sodium_max_mg,
            'potassium_limit_mg' => $profile->daily_potassium_max_mg,
            'phosphorus_limit_mg' => $profile->daily_phosphorus_max_mg,
        ];

        foreach ($columnMap as $column => $value) {
            if (Schema::hasColumn('health_user_goals', $column)) {
                $payload[$column] = $value;
            }
        }

        if (Schema::hasColumn('health_user_goals', 'updated_at')) {
            $payload['updated_at'] = $now;
        }

        $existing = DB::table('health_user_goals')
            ->where('user_id', $userId)
            ->first();

        if ($existing) {
            if (! empty($payload)) {
                DB::table('health_user_goals')
                    ->where('user_id', $userId)
                    ->update($payload);
            }

            return;
        }

        $payload['user_id'] = $userId;

        if (Schema::hasColumn('health_user_goals', 'created_at')) {
            $payload['created_at'] = $now;
        }

        if (Schema::hasColumn('health_user_goals', 'daily_steps_goal')) {
            $payload['daily_steps_goal'] = 8000;
        }

        if (Schema::hasColumn('health_user_goals', 'daily_water_goal_ml')) {
            $payload['daily_water_goal_ml'] = 2000;
        }

        $idColumn = $this->columnMetadata('health_user_goals', 'id');

        if ($idColumn && ($idColumn->data_type ?? null) === 'uuid') {
            $payload['id'] = (string) \Illuminate\Support\Str::uuid();
        }

        DB::table('health_user_goals')->insert($payload);
    }

    private function columnMetadata(string $table, string $column): ?object
    {
        return DB::table('information_schema.columns')
            ->where('table_schema', 'public')
            ->where('table_name', $table)
            ->where('column_name', $column)
            ->first(['data_type', 'column_default', 'is_nullable']);
    }
}
