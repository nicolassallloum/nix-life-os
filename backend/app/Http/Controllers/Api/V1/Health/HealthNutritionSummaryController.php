<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMealLog;
use App\Models\HealthNutritionProfile;
use Illuminate\Http\Request;

class HealthNutritionSummaryController extends Controller
{
    public function daily(Request $request)
    {
        $date = $request->query('date', now()->toDateString());

        $summary = HealthMealLog::where('user_id', $request->user()->id)
            ->whereDate('meal_date', $date)
            ->selectRaw('
                COALESCE(SUM(total_calories), 0) as calories,
                COALESCE(SUM(total_protein_g), 0) as protein_g,
                COALESCE(SUM(total_carbs_g), 0) as carbs_g,
                COALESCE(SUM(total_fat_g), 0) as fat_g,
                COALESCE(SUM(total_sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(total_potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(total_phosphorus_mg), 0) as phosphorus_mg
            ')
            ->first();

        $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        $warnings = [];

        if ($profile) {
            $warnings = $this->buildWarnings($summary, $profile);
        }

        return response()->json([
            'success' => true,
            'date' => $date,
            'summary' => [
                'calories' => (float) $summary->calories,
                'protein_g' => (float) $summary->protein_g,
                'carbs_g' => (float) $summary->carbs_g,
                'fat_g' => (float) $summary->fat_g,
                'sodium_mg' => (float) $summary->sodium_mg,
                'potassium_mg' => (float) $summary->potassium_mg,
                'phosphorus_mg' => (float) $summary->phosphorus_mg,
            ],
            'profile' => $profile,
            'warnings' => $warnings,
        ]);
    }

    private function buildWarnings($summary, HealthNutritionProfile $profile): array
    {
        $warnings = [];

        $checks = [
            'protein_g' => ['value' => $summary->protein_g, 'limit' => $profile->daily_protein_max_g, 'label' => 'Protein'],
            'sodium_mg' => ['value' => $summary->sodium_mg, 'limit' => $profile->daily_sodium_max_mg, 'label' => 'Sodium'],
            'potassium_mg' => ['value' => $summary->potassium_mg, 'limit' => $profile->daily_potassium_max_mg, 'label' => 'Potassium'],
            'phosphorus_mg' => ['value' => $summary->phosphorus_mg, 'limit' => $profile->daily_phosphorus_max_mg, 'label' => 'Phosphorus'],
        ];

        foreach ($checks as $key => $check) {
            if (!$check['limit'] || $check['limit'] <= 0) {
                continue;
            }

            $percentage = ($check['value'] / $check['limit']) * 100;

            if ($percentage >= 100) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $check['label'],
                    'status' => 'exceeded',
                    'message' => "{$check['label']} limit exceeded.",
                    'percentage' => round($percentage, 2),
                ];
            } elseif ($percentage >= 80) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $check['label'],
                    'status' => 'warning',
                    'message' => "{$check['label']} is close to daily limit.",
                    'percentage' => round($percentage, 2),
                ];
            }
        }

        return $warnings;
    }
}