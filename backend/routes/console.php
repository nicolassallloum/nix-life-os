<?php

use Illuminate\Support\Facades\Schedule;
use App\Jobs\CheckMedicationRemindersJob;
use App\Jobs\CheckHydrationRemindersJob;
use App\Jobs\CheckTaskRemindersJob;
use App\Jobs\CheckBudgetAlertsJob;
use App\Jobs\CheckHealthWarningsJob;
Schedule::command('health:generate-alerts')->hourly();
Schedule::command('ai:daily-insights')
    ->dailyAt('23:55');

Schedule::command('ai:weekly-report')
    ->weeklyOn(7, '23:30');
Schedule::command('ai:predictions --user-id=019d7c17-adcf-713f-b853-328a2fb65e57 --type=all --days-ahead=30')
    ->dailyAt('23:45');

Schedule::command('notifications:meal-reminders')->everyMinute();
Schedule::command('notifications:weight-reminders')->everyMinute();
Schedule::command('notifications:expense-reminders')->everyMinute();

Schedule::command('notifications:finance-alerts')->dailyAt('21:30');
Schedule::command('notifications:life-balance-alerts')->dailyAt('22:00');
Schedule::command('automation:run')
    ->everyFifteenMinutes()
    ->withoutOverlapping();


Schedule::command('system:health-check')->everyFifteenMinutes();
Schedule::command('medications:generate-doses')
    ->dailyAt('00:05')
    ->withoutOverlapping();

Schedule::command('medications:process-missed')
    ->everyFiveMinutes()
    ->withoutOverlapping();

Schedule::command('medications:send-reminders')
    ->everyMinute()
    ->withoutOverlapping();

Schedule::job(new CheckMedicationRemindersJob)->everyMinute();
Schedule::job(new CheckHydrationRemindersJob)->everyFiveMinutes();
Schedule::job(new CheckTaskRemindersJob)->everyFiveMinutes();
Schedule::job(new CheckBudgetAlertsJob)->everyTenMinutes();
Schedule::job(new CheckHealthWarningsJob)->hourly();