<?php

namespace App\Http\Resources;

use Carbon\CarbonInterface;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthStepLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $steps = (int) ($this->steps ?? $this->steps_count ?? 0);
        $kilometers = (float) ($this->kilometers ?? $this->distance_km ?? 0);
        $caloriesBurned = (int) ($this->calories_burned ?? $this->calories ?? 0);

        $goalSteps = (int) ($this->goal_steps ?? 10000);
        $goalPercentage = $goalSteps > 0
            ? round(min(100, ($steps / $goalSteps) * 100), 2)
            : 0;

        $logDate = $this->log_date ?? $this->date ?? null;

        if ($logDate instanceof CarbonInterface) {
            $logDate = $logDate->format('Y-m-d');
        }

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,

            'log_date' => $logDate,
            'date' => $logDate,

            // Canonical production fields
            'steps' => $steps,
            'kilometers' => round($kilometers, 3),
            'calories_burned' => $caloriesBurned,

            // Backward-compatible frontend aliases
            'steps_count' => $steps,
            'distance_km' => round($kilometers, 3),
            'calories' => $caloriesBurned,

            'goal_steps' => $goalSteps,
            'goal_percentage' => (float) ($this->goal_percentage ?? $goalPercentage),
            'goal_completed' => (bool) ($this->goal_completed ?? ($goalSteps > 0 && $steps >= $goalSteps)),

            'source' => $this->source ?? 'manual',
            'notes' => $this->notes,

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
