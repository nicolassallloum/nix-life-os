<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthLabTest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'category',
        'test_date',
        'test_name',
        'result_value',
        'unit',
        'reference_range',
        'lab_name',
        'doctor_name',
        'doctor_notes',
        'file_path',
        'attachment_path',
        'file_type',
        'source_type',
        'ai_status',
        'status',
        'notes',
        'extracted_payload',
        'approved_at',
    ];

    protected $casts = [
        'test_date' => 'date',
        'approved_at' => 'datetime',
        'extracted_payload' => 'array',
    ];

    public function category()
    {
        return $this->belongsTo(HealthTestCategory::class, 'category_id');
    }

    public function results()
    {
        return $this->hasMany(HealthLabTestResult::class, 'lab_test_id');
    }
}
