<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthProfile extends Model
{
    use HasUuids;

    protected $table = 'health_profile';

    protected $fillable = [
        'user_id',
        'daily_steps_goal',
        'stride_length_cm',
        'distance_unit',
    ];

    protected $casts = [
        'daily_steps_goal' => 'integer',
        'stride_length_cm' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}