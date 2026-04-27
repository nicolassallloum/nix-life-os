<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class AutomationTriggerLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'automation_rule_id',
        'user_id',
        'status',
        'evaluated_data',
        'message',
    ];

    protected $casts = [
        'evaluated_data' => 'array',
    ];

    public function rule()
    {
        return $this->belongsTo(AutomationRule::class, 'automation_rule_id');
    }
}