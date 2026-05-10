<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthLabTest extends Model
{
    protected $table = 'health_lab_tests';

    protected $fillable = [
        'user_id',
        'test_date',
        'test_name',
        'category',
        'result_value',
        'unit',
        'reference_range',
        'lab_name',

        'creatinine',
        'urea',
        'egfr',
        'hemoglobin',
        'sodium',
        'potassium',
        'phosphorus',

        'source_type',
        'attachment_path',
        'notes',
        'doctor_notes',

        'is_abnormal',
        'abnormal_reason',
        'comparison_status',
        'previous_result_id',
    ];

    protected $casts = [
        'test_date' => 'date:Y-m-d',
        'creatinine' => 'decimal:2',
        'urea' => 'decimal:2',
        'egfr' => 'decimal:2',
        'hemoglobin' => 'decimal:2',
        'sodium' => 'decimal:2',
        'potassium' => 'decimal:2',
        'phosphorus' => 'decimal:2',
        'is_abnormal' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function previousResult(): BelongsTo
    {
        return $this->belongsTo(self::class, 'previous_result_id');
    }
}