<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthLabTestResult extends Model
{
    use HasFactory;

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
        'result_value' => 'decimal:4',
        'reference_min' => 'decimal:4',
        'reference_max' => 'decimal:4',
        'result_date' => 'date',
        'user_approved' => 'boolean',
    ];

    public function labTest()
    {
        return $this->belongsTo(HealthLabTest::class, 'lab_test_id');
    }
}
