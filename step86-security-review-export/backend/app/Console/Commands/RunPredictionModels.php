<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class RunPredictionModels extends Command
{
    protected $signature = 'ai:predictions
                            {--user-id= : User UUID}
                            {--type=all : Prediction type: weight, finance, all}
                            {--days-ahead=30 : Days ahead for weight prediction}
                            {--month= : Forecast month YYYY-MM}';

    protected $description = 'Run AI prediction models for weight and financial forecast';

    public function handle(): int
    {
        $userId = $this->option('user-id');
        $type = $this->option('type');
        $daysAhead = $this->option('days-ahead');
        $month = $this->option('month');

        if (!$userId) {
            $this->error('Missing --user-id option.');
            return self::FAILURE;
        }

        $aiEnginePath = base_path('../ai-engine');

        $command = [
            $aiEnginePath . '/venv/bin/python',
            $aiEnginePath . '/run_predictions.py',
            '--user-id=' . $userId,
            '--type=' . $type,
            '--days-ahead=' . $daysAhead,
        ];

        if ($month) {
            $command[] = '--month=' . $month;
        }

        $process = new Process($command, $aiEnginePath);
        $process->setTimeout(300);

        $this->info('Running prediction models...');

        $process->run();

        if (!$process->isSuccessful()) {
            $this->error($process->getErrorOutput());
            return self::FAILURE;
        }

        $this->info($process->getOutput());

        return self::SUCCESS;
    }
}