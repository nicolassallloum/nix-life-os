<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProjectStatusUpdate extends Model
{
    use HasUuids;

    protected $fillable = [
        'project_id',
        'task_id',
        'milestone_id',
        'update_title',
        'update_description',
        'old_status',
        'new_status',
        'old_progress_percentage',
        'new_progress_percentage',
        'update_type',
        'metadata',
    ];

    protected $casts = [
        'old_progress_percentage' => 'integer',
        'new_progress_percentage' => 'integer',
        'metadata' => 'array',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function milestone()
    {
        return $this->belongsTo(ProjectMilestone::class, 'milestone_id');
    }
}