<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FinanceTransaction extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'finance_transactions';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'user_id',
        'account_id',
        'transaction_type',
        'category',
        'amount',
        'currency_code',
        'transaction_date',
        'description',
        'notes',
        'metadata_json',
        'transfer_account_id',
        'category_id',
        'reference_no',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
        'metadata_json' => 'array',
    ];

    public function account()
    {
        return $this->belongsTo(FinanceAccount::class, 'account_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}