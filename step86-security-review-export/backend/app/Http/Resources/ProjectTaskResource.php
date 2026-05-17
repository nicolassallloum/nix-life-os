<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectTaskResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'project_id' => $this->project_id,
            'user_id' => $this->user_id,

            'task_title' => $this->task_title,
            'task_description' => $this->task_description,

            'status' => $this->status,
            'priority' => $this->priority,
            'task_order' => $this->task_order,

            'start_date' => optional($this->start_date)->format('Y-m-d'),
            'due_date' => optional($this->due_date)->format('Y-m-d'),
            'completed_date' => optional($this->completed_date)->format('Y-m-d'),

            'progress_percentage' => $this->progress_percentage,
            'is_overdue' => $this->is_overdue,

            'metadata' => $this->metadata,

            'project' => new ProjectResource($this->whenLoaded('project')),

            'created_at' => optional($this->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => optional($this->updated_at)->format('Y-m-d H:i:s'),
        ];
    }
}
