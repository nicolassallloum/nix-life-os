<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthMedicationReminder extends Model
{
    use HasUuids;

    protected $table = 'health_medication_reminders';

    protected $fillable = [
        'user_id',
        'medication_id',
        'reminder_time',
        'frequency_type',
        'days_of_week',
        'interval_hours',
        'timezone',
        'is_active',
        'notification_enabled',
    ];

    protected $casts = [
        'days_of_week' => 'array',
        'is_active' => 'boolean',
        'notification_enabled' => 'boolean',
        'interval_hours' => 'integer',
    ];

    public function medication(): BelongsTo
    {
        return $this->belongsTo(HealthMedication::class, 'medication_id');
    }
}