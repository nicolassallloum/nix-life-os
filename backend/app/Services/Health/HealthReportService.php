<?php

namespace App\Services\Health;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HealthReportService
{
    public function dailyReport(string $userId, string $date): array
    {
        return [
            'period' => [
                'type' => 'daily',
                'date' => $date,
            ],
            'summary' => $this->summary($userId, $date, $date),
            'nutrition' => $this->nutritionTotals($userId, $date, $date),
            'hydration' => $this->hydrationTotals($userId, $date, $date),
            'weight' => $this->weightTrend($userId, $date, $date),
            'steps' => $this->stepsTrend($userId, $date, $date),
            'lab_results' => $this->labResultsTrend($userId, $date, $date),
            'medication_adherence' => $this->medicationAdherence($userId, $date, $date),
            'export_ready' => true,
        ];
    }

    public function weeklyReport(string $userId, string $startDate, string $endDate): array
    {
        return [
            'period' => [
                'type' => 'weekly',
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'summary' => $this->summary($userId, $startDate, $endDate),
            'nutrition' => $this->nutritionTotals($userId, $startDate, $endDate),
            'hydration' => $this->hydrationTotals($userId, $startDate, $endDate),
            'weight' => $this->weightTrend($userId, $startDate, $endDate),
            'steps' => $this->stepsTrend($userId, $startDate, $endDate),
            'lab_results' => $this->labResultsTrend($userId, $startDate, $endDate),
            'medication_adherence' => $this->medicationAdherence($userId, $startDate, $endDate),
            'export_ready' => true,
        ];
    }

    public function monthlyReport(string $userId, string $month): array
    {
        $startDate = Carbon::parse($month . '-01')->startOfMonth()->toDateString();
        $endDate = Carbon::parse($month . '-01')->endOfMonth()->toDateString();

        return [
            'period' => [
                'type' => 'monthly',
                'month' => $month,
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'summary' => $this->summary($userId, $startDate, $endDate),
            'nutrition' => $this->nutritionTotals($userId, $startDate, $endDate),
            'hydration' => $this->hydrationTotals($userId, $startDate, $endDate),
            'weight' => $this->weightTrend($userId, $startDate, $endDate),
            'steps' => $this->stepsTrend($userId, $startDate, $endDate),
            'lab_results' => $this->labResultsTrend($userId, $startDate, $endDate),
            'medication_adherence' => $this->medicationAdherence($userId, $startDate, $endDate),
            'export_ready' => true,
        ];
    }

    public function exportPreview(string $userId, string $period, string $date, string $month): array
    {
        if ($period === 'daily') {
            $report = $this->dailyReport($userId, $date);
        } elseif ($period === 'weekly') {
            $startDate = Carbon::parse($date)->startOfWeek()->toDateString();
            $endDate = Carbon::parse($date)->endOfWeek()->toDateString();
            $report = $this->weeklyReport($userId, $startDate, $endDate);
        } else {
            $report = $this->monthlyReport($userId, $month);
        }

        return [
            'report_title' => 'Nix Life OS Health Report',
            'generated_at' => now()->toDateTimeString(),
            'prepared_for_user_id' => $userId,
            'report' => $report,
            'pdf_sections' => [
                'cover',
                'health_summary',
                'nutrition_summary',
                'hydration_summary',
                'weight_trend',
                'steps_trend',
                'lab_results_trend',
                'medication_adherence',
                'doctor_notes_placeholder',
            ],
        ];
    }

    private function summary(string $userId, string $startDate, string $endDate): array
    {
        $nutrition = $this->nutritionTotals($userId, $startDate, $endDate);
        $hydration = $this->hydrationTotals($userId, $startDate, $endDate);
        $medication = $this->medicationAdherence($userId, $startDate, $endDate);

        return [
            'total_calories' => $nutrition['totals']['calories'],
            'total_water_ml' => $hydration['total_water_ml'],
            'medication_adherence_percent' => $medication['adherence_percent'],
            'health_status' => $this->calculateHealthStatus(
                $nutrition['totals']['sodium_mg'],
                $hydration['total_water_ml'],
                $medication['adherence_percent']
            ),
        ];
    }

    private function nutritionTotals(string $userId, string $startDate, string $endDate): array
    {
        if (!Schema::hasTable('health_nutrition_logs')) {
            return [
                'totals' => [
                    'calories' => 0.0,
                    'protein_g' => 0.0,
                    'carbs_g' => 0.0,
                    'fat_g' => 0.0,
                    'sodium_mg' => 0.0,
                    'potassium_mg' => 0.0,
                    'phosphorus_mg' => 0.0,
                ],
                'ckd_warnings' => [
                    'high_sodium' => false,
                    'high_potassium' => false,
                    'high_phosphorus' => false,
                    'high_protein' => false,
                ],
            ];
        }

        $row = DB::table('health_nutrition_logs')
            ->where('user_id', $userId)
            ->whereBetween('meal_date', [$startDate, $endDate])
            ->selectRaw('
                COALESCE(SUM(calories), 0) as calories,
                COALESCE(SUM(COALESCE(protein_g, protein, 0)), 0) as protein_g,
                COALESCE(SUM(COALESCE(carbs_g, 0)), 0) as carbs_g,
                COALESCE(SUM(COALESCE(fat_g, 0)), 0) as fat_g,
                COALESCE(SUM(COALESCE(sodium_mg, sodium, 0)), 0) as sodium_mg,
                COALESCE(SUM(COALESCE(potassium_mg, potassium, 0)), 0) as potassium_mg,
                COALESCE(SUM(COALESCE(phosphorus_mg, phosphorus, 0)), 0) as phosphorus_mg
            ')
            ->first();

        return [
            'totals' => [
                'calories' => (float) $row->calories,
                'protein_g' => (float) $row->protein_g,
                'carbs_g' => (float) $row->carbs_g,
                'fat_g' => (float) $row->fat_g,
                'sodium_mg' => (float) $row->sodium_mg,
                'potassium_mg' => (float) $row->potassium_mg,
                'phosphorus_mg' => (float) $row->phosphorus_mg,
            ],
            'ckd_warnings' => [
                'high_sodium' => (float) $row->sodium_mg > 2000,
                'high_potassium' => (float) $row->potassium_mg > 2500,
                'high_phosphorus' => (float) $row->phosphorus_mg > 1000,
                'high_protein' => (float) $row->protein_g > 60,
            ],
        ];
    }

    private function hydrationTotals(string $userId, string $startDate, string $endDate): array
    {
        $total = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->sum('amount_ml');

        return [
            'total_water_ml' => (int) $total,
            'total_water_liters' => round($total / 1000, 2),
        ];
    }

    private function weightTrend(string $userId, string $startDate, string $endDate): array
    {
        $items = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->orderBy('log_date')
            ->get([
                'log_date',
                'weight_kg',
            ]);

        return [
            'items' => $items,
            'start_weight' => $items->first()->weight_kg ?? null,
            'latest_weight' => $items->last()->weight_kg ?? null,
            'change_kg' => $items->count() >= 2
                ? round($items->last()->weight_kg - $items->first()->weight_kg, 2)
                : null,
        ];
    }

    private function stepsTrend(string $userId, string $startDate, string $endDate): array
    {
        if (Schema::hasTable('health_step_logs')) {
            $items = DB::table('health_step_logs')
                ->where('user_id', $userId)
                ->whereBetween('log_date', [$startDate, $endDate])
                ->orderBy('log_date')
                ->get([
                    'log_date',
                    'steps',
                    'kilometers',
                    'calories_burned',
                ]);
        } elseif (Schema::hasTable('health_step_log')) {
            $items = DB::table('health_step_log')
                ->where('user_id', $userId)
                ->whereBetween('log_date', [$startDate, $endDate])
                ->orderBy('log_date')
                ->get([
                    'log_date',
                    'steps_count as steps',
                    'distance_km as kilometers',
                ]);
        } else {
            $items = collect();
        }

        return [
            'items' => $items,
            'total_steps' => (int) $items->sum('steps'),
            'average_steps' => $items->count() > 0 ? round($items->avg('steps')) : 0,
            'total_kilometers' => round((float) $items->sum('kilometers'), 2),
            'total_calories_burned' => (float) $items->sum('calories_burned'),
        ];
    }

    private function labResultsTrend(string $userId, string $startDate, string $endDate): array
    {
        $items = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->whereBetween('test_date', [$startDate, $endDate])
            ->orderBy('test_date')
            ->get([
                'test_date',
                'test_name',
                'result_value',
                'unit',
                'reference_range',
            ])
            ->map(function ($item) {
                $item->status = 'normal';
                return $item;
            });

        return [
            'items' => $items,
            'total_tests' => $items->count(),
            'abnormal_tests' => 0,
        ];
    }

    private function medicationAdherence(string $userId, string $startDate, string $endDate): array
    {
        $baseQuery = DB::table('health_medication_dose_logs')
            ->where('user_id', $userId)
            ->whereDate('scheduled_for', '>=', $startDate)
            ->whereDate('scheduled_for', '<=', $endDate);

        $totalDoses = (clone $baseQuery)->count();

        $takenDoses = (clone $baseQuery)
            ->where('status', 'taken')
            ->count();

        $missedDoses = (clone $baseQuery)
            ->where('status', 'missed')
            ->count();

        $adherencePercent = $totalDoses > 0
            ? round(($takenDoses / $totalDoses) * 100, 2)
            : 0;

        return [
            'total_doses' => $totalDoses,
            'taken_doses' => $takenDoses,
            'missed_doses' => $missedDoses,
            'adherence_percent' => $adherencePercent,
        ];
    }

    private function calculateHealthStatus(float $sodiumMg, int $waterMl, float $medicationAdherence): string
    {
        if ($sodiumMg > 2500 || $medicationAdherence < 60) {
            return 'Needs Attention';
        }

        if ($sodiumMg > 2000 || $waterMl < 1000 || $medicationAdherence < 80) {
            return 'Moderate';
        }

        return 'Good';
    }
}
