<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class ProjectTask extends Model
{
    use HasFactory;

    protected $table = 'nix_life_os.project_tasks';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'project_id',
        'title',
        'description',
        'priority',
        'status',
        'start_date',
        'due_date',
        'assigned_to',
        'notes',
        'task_order',
        'progress_percentage',
    ];

    protected $casts = [
        'id' => 'string',
        'user_id' => 'string',
        'project_id' => 'string',
        'start_date' => 'date',
        'due_date' => 'date',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($model) {
            if (empty($model->id)) {
                $model->id = (string) Str::uuid();
            }
        });
    }

    public function project()
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    public function steps()
    {
        return $this->hasMany(ProjectTaskStep::class, 'project_task_id', 'id');
    }
}