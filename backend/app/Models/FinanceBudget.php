<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FinanceBudget extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'finance_budgets';

    protected $fillable = [
        'id',
        'user_id',
        'budget_name',
        'budget_month',
        'currency_code',
        'is_active',
        'notes',
        'metadata_json',
    ];

    protected $casts = [
        'budget_month' => 'date',
        'is_active' => 'boolean',
        'metadata_json' => 'array',
    ];

    public function lines()
    {
        return $this->hasMany(FinanceBudgetLine::class, 'budget_id', 'id');
    }
}