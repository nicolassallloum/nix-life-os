<?php

namespace App\Models;

use App\Enums\AccountType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FinanceAccount extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_account';
    protected $primaryKey = 'account_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'account_name',
        'account_type',
        'currency_code',
        'opening_balance',
        'current_balance',
        'description',
        'is_active',
    ];

    protected $casts = [
        'account_type' => AccountType::class,
        'opening_balance' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(AppUser::class, 'user_id', 'user_id');
    }

    public function outgoingTransactions(): HasMany
    {
        return $this->hasMany(FinanceTransaction::class, 'account_id', 'account_id');
    }

    public function incomingTransfers(): HasMany
    {
        return $this->hasMany(FinanceTransaction::class, 'transfer_account_id', 'account_id');
    }
}