<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class HealthMedication extends Model
{
    use HasFactory;
    use HasUuids;
    use SoftDeletes;

    protected $table = 'nix_life_os.health_medications';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'medication_name',
        'dosage',
        'daily_dose',
        'dose_times',
        'frequency',
        'start_date',
        'end_date',
        'status',
        'prescribed_by',
        'notes',
    ];

    protected $casts = [
        'id' => 'string',
        'user_id' => 'string',
        'dose_times' => 'array',
        'start_date' => 'date',
        'end_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];
}
