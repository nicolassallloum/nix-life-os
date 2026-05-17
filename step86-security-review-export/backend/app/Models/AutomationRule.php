<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class AutomationRule extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'rule_name',
        'module',
        'trigger_type',
        'conditions',
        'action_type',
        'action_payload',
        'is_active',
        'last_triggered_at',
    ];

    protected $casts = [
        'conditions' => 'array',
        'action_payload' => 'array',
        'is_active' => 'boolean',
        'last_triggered_at' => 'datetime',
    ];

    public function logs()
    {
        return $this->hasMany(AutomationTriggerLog::class);
    }
}