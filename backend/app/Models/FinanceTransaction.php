<?php

namespace App\Models;

use App\Enums\TransactionType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinanceTransaction extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_transaction';
    protected $primaryKey = 'transaction_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'transaction_type',
        'account_id',
        'transfer_account_id',
        'category_id',
        'amount',
        'transaction_date',
        'description',
        'reference_no',
        'metadata_json',
    ];

    protected $casts = [
        'transaction_type' => TransactionType::class,
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
        'metadata_json' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(AppUser::class, 'user_id', 'user_id');
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(FinanceAccount::class, 'account_id', 'account_id');
    }

    public function transferAccount(): BelongsTo
    {
        return $this->belongsTo(FinanceAccount::class, 'transfer_account_id', 'account_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(FinanceCategory::class, 'category_id', 'category_id');
    }
}