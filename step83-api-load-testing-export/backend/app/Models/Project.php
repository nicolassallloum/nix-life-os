<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'project_name',
        'project_code',
        'description',
        'status',
        'priority',
        'start_date',
        'target_end_date',
        'actual_end_date',
        'progress_percentage',
        'metadata',
    ];

    protected $casts = [
        'start_date' => 'date',
        'target_end_date' => 'date',
        'actual_end_date' => 'date',
        'progress_percentage' => 'decimal:2',
        'metadata' => 'array',
    ];

    public function tasks()
    {
        return $this->hasMany(ProjectTask::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }


    public function milestones()
    {
        return $this->hasMany(ProjectMilestone::class);
    }

    public function statusUpdates()
    {
        return $this->hasMany(ProjectStatusUpdate::class);
    }
}