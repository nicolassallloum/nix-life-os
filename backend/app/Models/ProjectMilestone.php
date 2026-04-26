<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProjectMilestone extends Model
{
    use HasUuids;

    protected $fillable = [
        'project_id',
        'milestone_name',
        'description',
        'target_date',
        'completed_date',
        'status',
        'progress_percentage',
        'weight',
        'metadata',
    ];

    protected $casts = [
        'target_date' => 'date',
        'completed_date' => 'date',
        'progress_percentage' => 'integer',
        'weight' => 'decimal:2',
        'metadata' => 'array',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }
}