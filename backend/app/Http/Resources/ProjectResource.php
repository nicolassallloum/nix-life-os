<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,

            'project_name' => $this->project_name,
            'project_code' => $this->project_code,
            'description' => $this->description,

            'status' => $this->status,
            'priority' => $this->priority,

            'start_date' => optional($this->start_date)->format('Y-m-d'),
            'target_end_date' => optional($this->target_end_date)->format('Y-m-d'),
            'actual_end_date' => optional($this->actual_end_date)->format('Y-m-d'),

            'progress_percentage' => $this->progress_percentage,

            'metadata' => $this->metadata,

            'tasks_count' => $this->whenCounted('tasks'),
            'tasks' => ProjectTaskResource::collection($this->whenLoaded('tasks')),

            'created_at' => optional($this->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => optional($this->updated_at)->format('Y-m-d H:i:s'),
        ];
    }
}