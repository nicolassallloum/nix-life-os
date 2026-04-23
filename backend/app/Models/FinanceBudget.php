<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceBudget extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_budget';
    protected $primaryKey = 'budget_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
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
        return $this->hasMany(FinanceBudgetLine::class, 'budget_id', 'budget_id');
    }
}