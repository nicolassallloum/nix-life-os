<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FinanceBudgetLine extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'finance_budget_lines';

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

    public function budget()
    {
        return $this->belongsTo(FinanceBudget::class, 'budget_id', 'id');
    }

    public function account()
    {
        return $this->belongsTo(FinanceAccount::class, 'account_id', 'id');
    }
}