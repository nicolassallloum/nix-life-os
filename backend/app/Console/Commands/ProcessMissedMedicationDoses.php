<?php

namespace App\Console\Commands;

use App\Models\HealthMedicationDoseLog;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Schema;

#[Signature('medications:process-missed')]
#[Description('Mark pending medication doses as missed after grace period.')]
class ProcessMissedMedicationDoses extends Command
{
    public function handle(): int
    {
        if (! Schema::hasTable('health_medication_dose_logs')) {
            $this->warn('health_medication_dose_logs table does not exist yet.');
            return self::SUCCESS;
        }
        $graceMinutes = 60;

        $missedBefore = Carbon::now()->subMinutes($graceMinutes);

        $updated = HealthMedicationDoseLog::query()
            ->where('status', 'pending')
            ->where('scheduled_for', '<', $missedBefore)
            ->update([
                'status' => 'missed',
                'updated_at' => now(),
            ]);

        $this->info("Medication doses marked as missed: {$updated}");

        return self::SUCCESS;
    }
}