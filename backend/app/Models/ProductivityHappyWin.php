<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProductivityHappyWin extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'win_date',
        'mood',
        'score',
        'metadata',
    ];

    protected $casts = [
        'win_date' => 'date',
        'score' => 'integer',
        'metadata' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
