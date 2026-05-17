<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinanceBudgetLine extends Model
{
    protected $table = 'finance_budget_lines';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'budget_id',
        'user_id',
        'account_id',
        'category_id',
        'category',
        'planned_amount',
        'actual_amount',
        'spent_amount',
        'warning_percentage',
        'exceeded_percentage',
        'line_notes',
        'notes',
        'metadata_json',
    ];

    protected $casts = [
        'planned_amount' => 'decimal:2',
        'actual_amount' => 'decimal:2',
        'spent_amount' => 'decimal:2',
        'warning_percentage' => 'decimal:2',
        'exceeded_percentage' => 'decimal:2',
        'metadata_json' => 'array',
    ];

    public function budget(): BelongsTo
    {
        return $this->belongsTo(FinanceBudget::class, 'budget_id', 'id');
    }
}
