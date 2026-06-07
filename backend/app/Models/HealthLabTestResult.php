<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthLabTestResult extends Model
{
    protected $table = 'health_lab_test_results';

    protected $fillable = [
        'lab_test_id',
        'test_name',
        'result_value',
        'unit',
        'reference_min',
        'reference_max',
        'reference_text',
        'status',
        'result_date',
        'doctor_name',
        'ai_confidence',
        'user_approved',
    ];

    protected $casts = [
        'result_date' => 'date',
        'ai_confidence' => 'decimal:2',
        'user_approved' => 'boolean',
    ];

    public function labTest(): BelongsTo
    {
        return $this->belongsTo(HealthLabTest::class, 'lab_test_id');
    }
}
