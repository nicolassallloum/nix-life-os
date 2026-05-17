<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiPrediction extends Model
{
    use HasUuids;

    protected $table = 'ai_predictions';

    protected $fillable = [
        'user_id',
        'prediction_type',
        'prediction_date',
        'target_date',
        'current_value',
        'predicted_value',
        'change_value',
        'change_percentage',
        'input_summary',
        'prediction_payload',
        'confidence_level',
        'notes',
    ];

    protected $casts = [
        'prediction_date' => 'date',
        'target_date' => 'date',
        'current_value' => 'decimal:2',
        'predicted_value' => 'decimal:2',
        'change_value' => 'decimal:2',
        'change_percentage' => 'decimal:2',
        'input_summary' => 'array',
        'prediction_payload' => 'array',
    ];
}