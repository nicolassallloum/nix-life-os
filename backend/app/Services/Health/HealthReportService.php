<?php

namespace App\Services\Health;

use Carbon\Carbon;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
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

    public function dateRangeReport(string $userId, string $fromDate, string $toDate): array
    {
        [$startDate, $endDate] = $this->normalizeDateRange($fromDate, $toDate);

        return [
            'period' => [
                'type' => 'date_range',
                'from_date' => $startDate,
                'to_date' => $endDate,
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

    public function exportPreview(
        string $userId,
        string $period,
        string $date,
        string $month,
        ?string $startDate = null,
        ?string $endDate = null
    ): array {
        if (in_array($period, ['date_range', 'range', 'custom'], true) || $startDate || $endDate) {
            $report = $this->dateRangeReport(
                $userId,
                $startDate ?: $date,
                $endDate ?: ($startDate ?: $date)
            );
        } elseif ($period === 'daily') {
            $report = $this->dailyReport($userId, $date);
        } elseif ($period === 'weekly') {
            $report = $this->weeklyReport(
                $userId,
                $startDate ?: Carbon::parse($date)->startOfWeek()->toDateString(),
                $endDate ?: Carbon::parse($date)->endOfWeek()->toDateString()
            );
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


    private function normalizeDateRange(string $fromDate, string $toDate): array
    {
        $start = Carbon::parse($fromDate ?: now()->startOfMonth()->toDateString())->toDateString();
        $end = Carbon::parse($toDate ?: $start)->toDateString();

        if ($start > $end) {
            return [$end, $start];
        }

        return [$start, $end];
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
        $defaults = [
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

        if (! Schema::hasTable('health_nutrition_logs')) {
            return $defaults;
        }

        $baseQuery = DB::table('health_nutrition_logs');
        $this->applyUserFilter($baseQuery, 'health_nutrition_logs', $userId);
        $this->applyDateRange($baseQuery, 'health_nutrition_logs', ['meal_date', 'log_date', 'date', 'created_at'], $startDate, $endDate);

        $totals = [
            'calories' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['calories', 'calories_kcal', 'energy_kcal']),
            'protein_g' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['protein_g', 'protein']),
            'carbs_g' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['carbs_g', 'carbohydrates_g', 'carbs']),
            'fat_g' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['fat_g', 'fat']),
            'sodium_mg' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['sodium_mg', 'sodium']),
            'potassium_mg' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['potassium_mg', 'potassium']),
            'phosphorus_mg' => $this->sumFirstAvailable($baseQuery, 'health_nutrition_logs', ['phosphorus_mg', 'phosphorus']),
        ];

        return [
            'totals' => $totals,
            'ckd_warnings' => [
                'high_sodium' => $totals['sodium_mg'] > 2000,
                'high_potassium' => $totals['potassium_mg'] > 2500,
                'high_phosphorus' => $totals['phosphorus_mg'] > 1000,
                'high_protein' => $totals['protein_g'] > 60,
            ],
        ];
    }

    private function hydrationTotals(string $userId, string $startDate, string $endDate): array
    {
        if (! Schema::hasTable('health_hydration_logs')) {
            return [
                'total_water_ml' => 0,
                'total_water_liters' => 0,
            ];
        }

        $baseQuery = DB::table('health_hydration_logs');
        $this->applyUserFilter($baseQuery, 'health_hydration_logs', $userId);
        $this->applyDateRange($baseQuery, 'health_hydration_logs', ['log_date', 'hydration_date', 'date', 'created_at'], $startDate, $endDate);

        $total = $this->sumFirstAvailable($baseQuery, 'health_hydration_logs', ['amount_ml', 'water_ml', 'quantity_ml', 'ml']);

        return [
            'total_water_ml' => (int) $total,
            'total_water_liters' => round($total / 1000, 2),
        ];
    }

    private function weightTrend(string $userId, string $startDate, string $endDate): array
    {
        if (! Schema::hasTable('health_weight_logs')) {
            return [
                'items' => collect(),
                'start_weight' => null,
                'latest_weight' => null,
                'change_kg' => null,
            ];
        }

        $dateColumn = $this->firstExistingColumn('health_weight_logs', ['log_date', 'weight_date', 'date', 'created_at']);
        $weightColumn = $this->firstExistingColumn('health_weight_logs', ['weight_kg', 'weight']);

        if (! $weightColumn) {
            return [
                'items' => collect(),
                'start_weight' => null,
                'latest_weight' => null,
                'change_kg' => null,
            ];
        }

        $query = DB::table('health_weight_logs');
        $this->applyUserFilter($query, 'health_weight_logs', $userId);

        if ($dateColumn) {
            $query->whereDate($dateColumn, '>=', $startDate)
                ->whereDate($dateColumn, '<=', $endDate)
                ->orderBy($dateColumn);
        }

        $items = $query
            ->get([
                $dateColumn ? DB::raw($dateColumn . ' as log_date') : DB::raw('NULL as log_date'),
                DB::raw($weightColumn . ' as weight_kg'),
            ]);

        return [
            'items' => $items,
            'start_weight' => $items->first()->weight_kg ?? null,
            'latest_weight' => $items->last()->weight_kg ?? null,
            'change_kg' => $items->count() >= 2
                ? round((float) $items->last()->weight_kg - (float) $items->first()->weight_kg, 2)
                : null,
        ];
    }

    private function stepsTrend(string $userId, string $startDate, string $endDate): array
    {
        $table = $this->firstExistingTable(['health_step_logs', 'health_steps_logs', 'health_step_log']);

        if (! $table) {
            return [
                'items' => collect(),
                'total_steps' => 0,
                'average_steps' => 0,
                'total_kilometers' => 0.0,
                'total_calories_burned' => 0.0,
            ];
        }

        $dateColumn = $this->firstExistingColumn($table, ['log_date', 'steps_date', 'date', 'created_at']);
        $stepsColumn = $this->firstExistingColumn($table, ['steps', 'steps_count']);
        $distanceColumn = $this->firstExistingColumn($table, ['kilometers', 'distance_km', 'distance']);
        $caloriesColumn = $this->firstExistingColumn($table, ['calories_burned', 'burned_calories']);

        $query = DB::table($table);
        $this->applyUserFilter($query, $table, $userId);

        if ($dateColumn) {
            $query->whereDate($dateColumn, '>=', $startDate)
                ->whereDate($dateColumn, '<=', $endDate)
                ->orderBy($dateColumn);
        }

        $items = $query->get([
            $dateColumn ? DB::raw($dateColumn . ' as log_date') : DB::raw('NULL as log_date'),
            $stepsColumn ? DB::raw($stepsColumn . ' as steps') : DB::raw('0 as steps'),
            $distanceColumn ? DB::raw($distanceColumn . ' as kilometers') : DB::raw('0 as kilometers'),
            $caloriesColumn ? DB::raw($caloriesColumn . ' as calories_burned') : DB::raw('0 as calories_burned'),
        ]);

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
        if (! Schema::hasTable('health_lab_tests')) {
            return [
                'items' => collect(),
                'total_tests' => 0,
                'abnormal_tests' => 0,
            ];
        }

        $dateColumn = $this->firstExistingColumn('health_lab_tests', ['test_date', 'created_at']);
        $statusColumn = $this->firstExistingColumn('health_lab_tests', ['status', 'ai_status']);

        $query = DB::table('health_lab_tests');
        $this->applyUserFilter($query, 'health_lab_tests', $userId);

        if ($dateColumn) {
            $query->whereDate($dateColumn, '>=', $startDate)
                ->whereDate($dateColumn, '<=', $endDate)
                ->orderBy($dateColumn);
        }

        $items = $query
            ->get($this->selectAliases('health_lab_tests', [
                'test_date' => ['test_date', 'created_at'],
                'test_name' => ['test_name', 'name', 'category'],
                'result_value' => ['result_value', 'value'],
                'unit' => ['unit'],
                'reference_range' => ['reference_range', 'reference_text'],
                'status' => ['status', 'ai_status'],
            ]))
            ->map(function ($item) use ($statusColumn) {
                $item->status = $item->status ?: 'normal';

                return $item;
            });

        $abnormalTests = $items->filter(function ($item) {
            return in_array(strtolower((string) $item->status), ['abnormal', 'high', 'low', 'critical'], true);
        })->count();

        return [
            'items' => $items,
            'total_tests' => $items->count(),
            'abnormal_tests' => $abnormalTests,
        ];
    }

    private function medicationAdherence(string $userId, string $startDate, string $endDate): array
    {
        if (! Schema::hasTable('health_medication_dose_logs')) {
            return [
                'total_doses' => 0,
                'taken_doses' => 0,
                'missed_doses' => 0,
                'adherence_percent' => 0,
            ];
        }

        $dateColumn = $this->firstExistingColumn('health_medication_dose_logs', ['scheduled_for', 'dose_date', 'scheduled_at', 'taken_at', 'created_at']);
        $statusColumn = $this->firstExistingColumn('health_medication_dose_logs', ['status']);

        $baseQuery = DB::table('health_medication_dose_logs');
        $this->applyUserFilter($baseQuery, 'health_medication_dose_logs', $userId);

        if ($dateColumn) {
            $baseQuery->whereDate($dateColumn, '>=', $startDate)
                ->whereDate($dateColumn, '<=', $endDate);
        }

        $totalDoses = (clone $baseQuery)->count();

        if (! $statusColumn) {
            return [
                'total_doses' => $totalDoses,
                'taken_doses' => 0,
                'missed_doses' => 0,
                'adherence_percent' => 0,
            ];
        }

        $takenDoses = (clone $baseQuery)
            ->whereIn($statusColumn, ['taken', 'completed'])
            ->count();

        $missedDoses = (clone $baseQuery)
            ->whereIn($statusColumn, ['missed', 'skipped'])
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

    private function applyUserFilter(Builder $query, string $table, string $userId): void
    {
        if (Schema::hasColumn($table, 'user_id')) {
            $query->where('user_id', $userId);
        }
    }

    private function applyDateRange(Builder $query, string $table, array $candidates, string $startDate, string $endDate): void
    {
        $dateColumn = $this->firstExistingColumn($table, $candidates);

        if ($dateColumn) {
            $query->whereDate($dateColumn, '>=', $startDate)
                ->whereDate($dateColumn, '<=', $endDate);
        }
    }

    private function sumFirstAvailable(Builder $query, string $table, array $candidates): float
    {
        $column = $this->firstExistingColumn($table, $candidates);

        if (! $column) {
            return 0.0;
        }

        return (float) (clone $query)->sum($column);
    }

    private function selectAliases(string $table, array $aliases): array
    {
        $select = [];

        foreach ($aliases as $alias => $candidates) {
            foreach ($candidates as $column) {
                if (Schema::hasColumn($table, $column)) {
                    $select[] = DB::raw($column . ' as ' . $alias);
                    continue 2;
                }
            }

            $select[] = DB::raw('NULL as ' . $alias);
        }

        return $select;
    }

    private function firstExistingTable(array $tables): ?string
    {
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                return $table;
            }
        }

        return null;
    }

    private function firstExistingColumn(string $table, array $columns): ?string
    {
        foreach ($columns as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return null;
    }
}
