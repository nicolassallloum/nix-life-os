

protected function schedule(Schedule $schedule): void
{
    $schedule->command('notifications:meal-reminders')->everyMinute();
    $schedule->command('notifications:weight-reminders')->everyMinute();
    $schedule->command('notifications:expense-reminders')->everyMinute();

    $schedule->command('notifications:finance-alerts')->dailyAt('21:30');
    $schedule->command('notifications:life-balance-alerts')->dailyAt('22:00');

    $schedule->command('ai:daily-insights')->dailyAt('23:55');
    $schedule->command('ai:weekly-report')->weeklyOn(0, '23:30');
}