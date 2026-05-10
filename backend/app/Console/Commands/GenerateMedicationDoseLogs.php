<?php

namespace App\Console\Commands;

use App\Models\HealthMedicationDoseLog;
use App\Models\HealthMedicationReminder;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Schema;

#[Signature('medications:generate-doses')]
#[Description('Generate daily medication dose logs from active reminders.')]
class GenerateMedicationDoseLogs extends Command
{
    public function handle(): int
    {
        if (
            ! Schema::hasTable('health_medication_reminders') ||
            ! Schema::hasTable('health_medication_dose_logs')
        ) {
            $this->warn('Medication reminder tables do not exist yet.');
            return self::SUCCESS;
        }
        $today = Carbon::today();
        $created = 0;

        $reminders = HealthMedicationReminder::query()
            ->with('medication')
            ->where('is_active', true)
            ->get();

        foreach ($reminders as $reminder) {
            if (! $reminder->medication) {
                continue;
            }

            if ($reminder->medication->status !== 'active') {
                continue;
            }

            if ($reminder->medication->start_date && Carbon::parse($reminder->medication->start_date)->greaterThan($today)) {
                continue;
            }

            if ($reminder->medication->end_date && Carbon::parse($reminder->medication->end_date)->lessThan($today)) {
                continue;
            }

            $scheduledFor = Carbon::parse($today->format('Y-m-d') . ' ' . $reminder->reminder_time);

            $log = HealthMedicationDoseLog::firstOrCreate(
                [
                    'user_id' => $reminder->user_id,
                    'medication_id' => $reminder->medication_id,
                    'reminder_id' => $reminder->id,
                    'scheduled_for' => $scheduledFor,
                ],
                [
                    'status' => 'pending',
                ]
            );

            if ($log->wasRecentlyCreated) {
                $created++;
            }
        }

        $this->info("Medication dose logs generated: {$created}");

        return self::SUCCESS;
    }
}