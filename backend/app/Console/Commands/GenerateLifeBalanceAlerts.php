<?php

namespace App\Console\Commands;

use App\Models\NotificationPreference;
use App\Services\NotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class GenerateLifeBalanceAlerts extends Command
{
    protected $signature = 'notifications:life-balance-alerts';

    protected $description = 'Generate Life Balance score alerts';

    public function handle(NotificationService $notificationService): int
    {
        $preferences = NotificationPreference::where('life_balance_alerts_enabled', true)->get();

        foreach ($preferences as $pref) {
            $latestScore = DB::table('life_balance_scores')
                ->where('user_id', $pref->user_id)
                ->orderByDesc('score_date')
                ->first();

            if (!$latestScore) {
                continue;
            }

            if ($latestScore->overall_score < $pref->life_balance_warning_score) {
                $notificationService->createNotification(
                    $pref->user_id,
                    'life_balance_alert',
                    'Life Balance Alert',
                    'Your Life Balance score is ' . $latestScore->overall_score . '. Consider reviewing your health, finance, and productivity balance.',
                    'warning',
                    'life_balance',
                    [
                        'overall_score' => $latestScore->overall_score,
                        'warning_score' => $pref->life_balance_warning_score,
                    ]
                );
            }
        }

        $this->info('Life Balance alerts generated successfully.');

        return self::SUCCESS;
    }
}