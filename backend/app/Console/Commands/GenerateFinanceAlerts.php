<?php

namespace App\Console\Commands;

use App\Models\NotificationPreference;
use App\Services\NotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class GenerateFinanceAlerts extends Command
{
    protected $signature = 'notifications:finance-alerts';

    protected $description = 'Generate finance alert notifications';

    public function handle(NotificationService $notificationService): int
    {
        $preferences = NotificationPreference::where('finance_alerts_enabled', true)->get();

        foreach ($preferences as $pref) {
            if (!$pref->daily_expense_warning_limit) {
                continue;
            }

            $todayExpenses = DB::table('nix_life_os.finance_transaction')
                ->where('user_id', $pref->user_id)
                ->whereDate('transaction_date', today())
                ->where('transaction_type', 'expense')
                ->sum('amount');

            if ($todayExpenses >= $pref->daily_expense_warning_limit) {
                $notificationService->createNotification(
                    $pref->user_id,
                    'finance_alert',
                    'Daily Expense Alert',
                    'You spent ' . number_format($todayExpenses, 2) . ' today. This reached your daily warning limit.',
                    'warning',
                    'finance',
                    [
                        'today_expenses' => $todayExpenses,
                        'limit' => $pref->daily_expense_warning_limit,
                    ]
                );
            }
        }

        $this->info('Finance alerts generated successfully.');

        return self::SUCCESS;
    }
}