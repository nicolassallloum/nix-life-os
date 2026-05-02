<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceAccount extends Model
{
    use HasUuids;

    protected $table = 'finance_accounts';

    protected $fillable = [
        'user_id',
        'account_name',
        'account_type',
        'currency',
        'initial_balance',
        'current_balance',
        'is_active',
        'metadata',
    ];

    protected $casts = [
        'initial_balance' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
        'metadata' => 'array',
    ];
}