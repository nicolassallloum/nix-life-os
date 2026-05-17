<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProductivityHabitCheckIn extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'habit_id',
        'check_in_date',
        'status',
        'count',
        'notes',
        'metadata',
    ];

    protected $casts = [
        'check_in_date' => 'date',
        'count' => 'integer',
        'metadata' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function habit()
    {
        return $this->belongsTo(ProductivityHabit::class, 'habit_id');
    }
}
