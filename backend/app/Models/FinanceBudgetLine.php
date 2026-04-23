<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceBudgetLine extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_budget_line';
    protected $primaryKey = 'budget_line_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'budget_id',
        'user_id',
        'category_id',
        'account_id',
        'planned_amount',
        'warning_percentage',
        'exceeded_percentage',
        'line_notes',
        'metadata_json',
    ];

    protected $casts = [
        'planned_amount' => 'decimal:2',
        'warning_percentage' => 'decimal:2',
        'exceeded_percentage' => 'decimal:2',
        'metadata_json' => 'array',
    ];

    public function budget()
    {
        return $this->belongsTo(FinanceBudget::class, 'budget_id', 'budget_id');
    }
}