<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class HealthMedication extends Model
{
    use HasFactory;
    use HasUuids;
    use SoftDeletes;

    protected $table = 'public.health_medications';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'medication_name',
        'name',
        'dosage',
        'daily_dose',
        'daily_times',
        'frequency',
        'start_date',
        'end_date',
        'status',
        'prescribed_by',
        'doctor_name',
        'notes',
    ];

    protected $casts = [
        'id' => 'string',
        'user_id' => 'string',
        'daily_times' => 'integer',
        'start_date' => 'date:Y-m-d',
        'end_date' => 'date:Y-m-d',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public function times(): HasMany
    {
        return $this->hasMany(HealthMedicationTime::class, 'medication_id')
            ->orderBy('dosage_time');
    }
}
