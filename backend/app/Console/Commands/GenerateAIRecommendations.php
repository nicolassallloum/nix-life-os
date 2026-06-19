<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AI\RecommendationRuleService;
use App\Services\AI\RecommendationScoringService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class GenerateAIRecommendations extends Command
{
    protected $signature = 'ai:generate-recommendations {--user_id=} {--date=}';

    protected $description = 'Generate AI scores and recommendations for one user or all active users';

    public function handle(
        RecommendationRuleService $recommendationRuleService,
        RecommendationScoringService $recommendationScoringService
    ): int {
        $userId = $this->option('user_id');
        $date = $this->option('date') ? now()->parse($this->option('date')) : now();

        $users = User::query()
            ->when($userId, fn ($query) => $query->where('id', $userId))
            ->where(function ($query) {
                $query->whereNull('status')
                    ->orWhere('status', 'active');
            })
            ->orderBy('id')
            ->get();

        if ($users->isEmpty()) {
            $this->warn('No users found for AI recommendation generation.');
            return self::SUCCESS;
        }

        $totalGenerated = 0;
        $totalSkipped = 0;
        $totalFailed = 0;

        foreach ($users as $user) {
            try {
                $this->info("Generating AI recommendations for user {$user->id}");

                $result = DB::transaction(function () use ($user, $date, $recommendationRuleService, $recommendationScoringService) {
                    $recommendationScoringService->calculateAndStoreForUser($user, $date);

                    return $recommendationRuleService->generateForUser($user, $date);
                });

                $generated = (int) ($result['generated_count'] ?? 0);
                $skipped = (int) ($result['skipped_count'] ?? 0);
                $failed = (int) ($result['failed_count'] ?? 0);

                $totalGenerated += $generated;
                $totalSkipped += $skipped;
                $totalFailed += $failed;

                $this->info("User {$user->id}: generated={$generated}, skipped={$skipped}, failed={$failed}");
            } catch (Throwable $e) {
                $totalFailed++;

                report($e);

                $this->error("User {$user->id}: AI generation failed - {$e->getMessage()}");
            }
        }

        $this->info("AI recommendation generation completed. users={$users->count()}, generated={$totalGenerated}, skipped={$totalSkipped}, failed={$totalFailed}");

        return $totalFailed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
