<?php

use Illuminate\Support\Facades\Schedule;

Schedule::command('ai:daily-insights')
    ->dailyAt('23:55');

Schedule::command('ai:weekly-report')
    ->weeklyOn(7, '23:30');