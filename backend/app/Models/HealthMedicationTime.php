<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthMedicationTime extends Model
{
    protected $table = 'public.health_medication_times';

    protected $primaryKey = 'id';

    public $incrementing = true;

    protected $keyType = 'int';

    protected $fillable = [
        'medication_id',
        'dosage_time',
        'dosage_note',
    ];

    protected $casts = [
        'id' => 'integer',
        'medication_id' => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];


    public function getDosageTimeAttribute($value): ?string
    {
        if ($value === null) {
            return null;
        }

        return substr((string) $value, 0, 5);
    }

    public function medication(): BelongsTo
    {
        return $this->belongsTo(HealthMedication::class, 'medication_id');
    }
}
