<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class LifeBalanceController extends Controller
{
    /**
     * GET /api/v1/life-balance/summary
     */
    public function summary(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'message' => 'Unauthenticated.',
                ], 401);
            }

            $userId = $user->id;

            $financeScore = $this->calculateFinanceScore($userId);
            $healthScore = $this->calculateHealthScore($userId);
            $projectsScore = $this->calculateProjectsScore($userId);
            $productivityScore = $this->calculateProductivityScore($userId);
            $consistencyScore = $this->calculateConsistencyScore($userId);

            $overallScore = (int) round((
                $financeScore +
                $healthScore +
                $projectsScore +
                $productivityScore +
                $consistencyScore
            ) / 5);

            return response()->json([
                'success' => true,
                'message' => 'Life balance summary loaded successfully.',
                'data' => [
                    'overall_score' => $overallScore,
                    'finance_score' => $financeScore,
                    'health_score' => $healthScore,
                    'projects_score' => $projectsScore,
                    'productivity_score' => $productivityScore,
                    'consistency_score' => $consistencyScore,
                    'recommendations' => $this->buildRecommendations(
                        $financeScore,
                        $healthScore,
                        $projectsScore,
                        $productivityScore,
                        $consistencyScore
                    ),
                ],
            ]);
        } catch (Throwable $exception) {
            Log::error('Life balance summary failed.', [
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Life balance summary could not be loaded.',
                'error' => app()->environment('local')
                    ? $exception->getMessage()
                    : 'Server Error',
                'data' => [
                    'overall_score' => 0,
                    'finance_score' => 0,
                    'health_score' => 0,
                    'projects_score' => 0,
                    'productivity_score' => 0,
                    'consistency_score' => 0,
                    'recommendations' => [],
                ],
            ], 500);
        }
    }

    private function calculateFinanceScore(string $userId): int
    {
        try {
            $accountsCount = $this->safeCount('finance_accounts', $userId);
            $transactionsCount = $this->safeCount('finance_transactions', $userId);
            $budgetsCount = $this->safeCount('finance_budgets', $userId);

            $score = 0;

            if ($accountsCount > 0) {
                $score += 30;
            }

            if ($transactionsCount > 0) {
                $score += 30;
            }

            if ($budgetsCount > 0) {
                $score += 20;
            }

            if ($transactionsCount >= 5) {
                $score += 20;
            }

            return $this->clampScore($score);
        } catch (Throwable $exception) {
            return 70;
        }
    }

    private function calculateHealthScore(string $userId): int
    {
        try {
            $stepsCount = $this->safeCount('health_step_logs', $userId);
            $weightCount = $this->safeCount('health_weight_logs', $userId);
            $nutritionCount = $this->safeCount('health_nutrition_logs', $userId);
            $hydrationCount = $this->safeCount('health_hydration_logs', $userId);

            $score = 0;

            if ($stepsCount > 0) {
                $score += 25;
            }

            if ($weightCount > 0) {
                $score += 25;
            }

            if ($nutritionCount > 0) {
                $score += 25;
            }

            if ($hydrationCount > 0) {
                $score += 25;
            }

            return $this->clampScore($score);
        } catch (Throwable $exception) {
            return 75;
        }
    }

    private function calculateProjectsScore(string $userId): int
    {
        try {
            $projectsCount = $this->safeCount('projects', $userId);
            $tasksCount = $this->safeCount('project_tasks', $userId);
            $milestonesCount = $this->safeCount('project_milestones', $userId);

            $score = 0;

            if ($projectsCount > 0) {
                $score += 40;
            }

            if ($tasksCount > 0) {
                $score += 35;
            }

            if ($milestonesCount > 0) {
                $score += 25;
            }

            return $this->clampScore($score);
        } catch (Throwable $exception) {
            return 100;
        }
    }

    private function calculateProductivityScore(string $userId): int
    {
        try {
            $tasksCount = $this->safeCount('project_tasks', $userId);
            $statusUpdatesCount = $this->safeCount('project_status_updates', $userId);
            $notificationsCount = $this->safeCount('notifications', $userId);

            $score = 0;

            if ($tasksCount > 0) {
                $score += 45;
            }

            if ($statusUpdatesCount > 0) {
                $score += 30;
            }

            if ($notificationsCount > 0) {
                $score += 25;
            }

            return $this->clampScore($score);
        } catch (Throwable $exception) {
            return 100;
        }
    }

    private function calculateConsistencyScore(string $userId): int
    {
        try {
            $financeCount = $this->safeCount('finance_transactions', $userId);
            $healthCount = $this->safeCount('health_step_logs', $userId);
            $projectsCount = $this->safeCount('project_tasks', $userId);

            $activeAreas = 0;

            if ($financeCount > 0) {
                $activeAreas++;
            }

            if ($healthCount > 0) {
                $activeAreas++;
            }

            if ($projectsCount > 0) {
                $activeAreas++;
            }

            return match ($activeAreas) {
                3 => 75,
                2 => 60,
                1 => 40,
                default => 0,
            };
        } catch (Throwable $exception) {
            return 75;
        }
    }

    private function safeCount(string $table, string $userId): int
    {
        try {
            if (!DB::getSchemaBuilder()->hasTable($table)) {
                return 0;
            }

            if (!DB::getSchemaBuilder()->hasColumn($table, 'user_id')) {
                return 0;
            }

            return (int) DB::table($table)
                ->where('user_id', $userId)
                ->count();
        } catch (Throwable $exception) {
            return 0;
        }
    }

    private function buildRecommendations(
        int $financeScore,
        int $healthScore,
        int $projectsScore,
        int $productivityScore,
        int $consistencyScore
    ): array {
        $recommendations = [];

        if ($financeScore >= 70) {
            $recommendations[] = 'Finance balance looks stable.';
        } else {
            $recommendations[] = 'Add more finance accounts, transactions, and budgets to improve financial visibility.';
        }

        if ($healthScore >= 70) {
            $recommendations[] = 'Health tracking is improving.';
        } else {
            $recommendations[] = 'Track steps, weight, nutrition, and hydration more consistently.';
        }

        if ($projectsScore >= 70) {
            $recommendations[] = 'Project activity looks healthy.';
        } else {
            $recommendations[] = 'Create more project tasks and milestones to improve project balance.';
        }

        if ($productivityScore < 70) {
            $recommendations[] = 'Increase daily task updates to improve productivity scoring.';
        }

        if ($consistencyScore < 70) {
            $recommendations[] = 'Try to update finance, health, and project data every day for better consistency.';
        }

        return $recommendations;
    }

    private function clampScore(int|float $score): int
    {
        return max(0, min(100, (int) round($score)));
    }
}
