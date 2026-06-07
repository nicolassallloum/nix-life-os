<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthMedicationTime extends Model
{
    protected $table = 'health_medication_times';

    protected $fillable = [
        'medication_id',
        'dosage_time',
        'dosage_note',
    ];

    public function medication(): BelongsTo
    {
        return $this->belongsTo(HealthMedication::class, 'medication_id');
    }
}
