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
        'test_date',
        'lab_name',
        'doctor_name',
        'file_path',
        'file_type',
        'ai_status',
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
