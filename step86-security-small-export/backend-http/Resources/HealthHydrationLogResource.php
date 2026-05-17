<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthHydrationLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            
            'date' => optional($this->log_date)->format('Y-m-d'),
            'log_date' => optional($this->log_date)->format('Y-m-d'),
            'log_time' => $this->log_time,
            'drink_type' => $this->drink_type,
            'water_ml' => (float) $this->amount_ml,
            'amount_ml' => (float) $this->amount_ml,
            'is_ckd_safe' => (bool) $this->is_ckd_safe,
            'source' => $this->source,
            'notes' => $this->notes,
            'created_at' => optional($this->created_at)->toISOString(),
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}