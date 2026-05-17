<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiReport extends Model
{
    use HasUuids;

    protected $table = 'ai_reports';

    protected $fillable = [
        'user_id',
        'report_type',
        'period_start',
        'period_end',
        'title',
        'summary',
        'finance_summary',
        'health_summary',
        'project_summary',
        'recommendations',
        'raw_metrics',
        'overall_score',
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'finance_summary' => 'array',
        'health_summary' => 'array',
        'project_summary' => 'array',
        'recommendations' => 'array',
        'raw_metrics' => 'array',
        'overall_score' => 'decimal:2',
    ];
}