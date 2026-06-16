<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthMoodLog extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'nix_life_os.health_mood_logs';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'mood_date',
        'mood_label',
        'mood_score',
        'notes',
        'tags',
    ];

    protected $casts = [
        'id' => 'string',
        'user_id' => 'string',
        'mood_date' => 'date',
        'mood_score' => 'integer',
        'tags' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
