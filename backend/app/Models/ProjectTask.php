<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ProjectTask extends Model
{
    use HasFactory;
    protected $table = 'nix_life_os.project_tasks';

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
    ];
    protected $casts = [
        'user_id' => 'string',
        'project_id' => 'string',
        'start_date' => 'date',
        'due_date' => 'date',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }
}