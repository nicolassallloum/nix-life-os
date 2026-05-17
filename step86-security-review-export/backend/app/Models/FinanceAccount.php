<?php

namespace App\Models;

use App\Enums\AccountType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FinanceAccount extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'finance_accounts';

    protected $fillable = [
        'id',
        'user_id',
        'account_name',
        'account_type',
        'currency_code',
        'opening_balance',
        'current_balance',
        'description',
        'notes',
        'is_active',
    ];

    protected $casts = [
        'account_type' => AccountType::class,
        'opening_balance' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
    ];
}