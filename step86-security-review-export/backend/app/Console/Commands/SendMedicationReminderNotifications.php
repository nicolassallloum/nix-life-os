<?php

namespace App\Console\Commands;

use App\Models\HealthMedicationDoseLog;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Schema;

#[Signature('medications:send-reminders')]
#[Description('Mark medication reminders as notification-ready when due.')]
class SendMedicationReminderNotifications extends Command
{
    public function handle(): int
    {
        if (! Schema::hasTable('health_medication_dose_logs')) {
            $this->warn('health_medication_dose_logs table does not exist yet.');
            return self::SUCCESS;
        }
        $now = Carbon::now();
        $windowStart = $now->copy()->subMinute();
        $windowEnd = $now->copy()->addMinutes(5);

        $doses = HealthMedicationDoseLog::query()
            ->with('medication')
            ->where('status', 'pending')
            ->whereNull('notification_sent_at')
            ->whereBetween('scheduled_for', [$windowStart, $windowEnd])
            ->get();

        foreach ($doses as $dose) {
            $dose->update([
                'notification_sent_at' => now(),
            ]);
        }

        $this->info("Medication reminder notifications processed: {$doses->count()}");

        return self::SUCCESS;
    }
}