<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceAnomalyLog extends Model
{
    use HasUuids;

    protected $table = 'finance_anomaly_log';
    protected $primaryKey = 'anomaly_log_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'transaction_id',
        'anomaly_type',
        'anomaly_score',
        'severity',
        'title',
        'explanation',
        'baseline_amount',
        'observed_amount',
        'detected_at',
        'status',
        'extra_data_json',
    ];

    protected $casts = [
        'anomaly_score' => 'decimal:2',
        'baseline_amount' => 'decimal:2',
        'observed_amount' => 'decimal:2',
        'detected_at' => 'datetime',
        'extra_data_json' => 'array',
    ];
}