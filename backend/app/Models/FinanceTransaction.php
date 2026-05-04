<?php

namespace App\Models;

use App\Enums\TransactionType;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FinanceTransaction extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'finance_transactions';

    protected $fillable = [
        'id',
        'user_id',
        'transaction_type',
        'account_id',
        'transfer_account_id',
        'category_id',
        'category',
        'amount',
        'currency_code',
        'transaction_date',
        'description',
        'reference_no',
        'notes',
        'metadata_json',
    ];

    protected $casts = [
        'transaction_type' => TransactionType::class,
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
        'metadata_json' => 'array',
    ];

    public function account()
    {
        return $this->belongsTo(FinanceAccount::class, 'account_id');
    }

    public function transferAccount()
    {
        return $this->belongsTo(FinanceAccount::class, 'transfer_account_id');
    }

    public function category()
    {
        return $this->belongsTo(FinanceCategory::class, 'category_id');
    }
}