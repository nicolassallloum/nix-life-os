<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FinanceBudget extends Model
{
    protected $table = 'finance_budgets';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'user_id',
        'budget_name',
        'category',
        'budget_amount',
        'spent_amount',
        'budget_month',
        'currency_code',
        'is_active',
        'notes',
        'metadata_json',
    ];

    protected $casts = [
        'budget_amount' => 'decimal:2',
        'spent_amount' => 'decimal:2',
        'is_active' => 'boolean',
        'metadata_json' => 'array',
    ];

    public function lines(): HasMany
    {
        return $this->hasMany(FinanceBudgetLine::class, 'budget_id', 'id');
    }
}
