<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthStepLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'log_date' => $this->log_date?->format('Y-m-d'),
            'steps_count' => $this->steps_count,
            'distance_km' => $this->distance_km,
            'goal_steps' => $this->goal_steps,
            'goal_percentage' => $this->goal_percentage,
            'goal_completed' => $this->goal_completed,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString(),
        ];
    }
}