<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ProjectTask extends Model
{
    use HasFactory;

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

    public function project()
    {
        return $this->belongsTo(Project::class);
    }
}