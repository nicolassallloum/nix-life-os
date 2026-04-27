<?php

use Illuminate\Support\Facades\Schedule;

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


