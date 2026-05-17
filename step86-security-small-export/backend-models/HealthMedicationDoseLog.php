<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthMedicationDoseLog extends Model
{
    use HasUuids;

    protected $table = 'health_medication_dose_logs';

    protected $fillable = [
        'user_id',
        'medication_id',
        'reminder_id',
        'scheduled_for',
        'taken_at',
        'status',
        'skip_reason',
        'notes',
        'notification_sent_at',
    ];

    protected $casts = [
        'scheduled_for' => 'datetime',
        'taken_at' => 'datetime',
        'notification_sent_at' => 'datetime',
    ];

    public function medication(): BelongsTo
    {
        return $this->belongsTo(HealthMedication::class, 'medication_id');
    }

    public function reminder(): BelongsTo
    {
        return $this->belongsTo(HealthMedicationReminder::class, 'reminder_id');
    }
}