<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthWeightLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'log_date' => optional($this->log_date)->format('Y-m-d'),
            'weight_kg' => (float) $this->weight_kg,
            'height_cm' => $this->height_cm !== null ? (float) $this->height_cm : null,
            'length_cm' => $this->length_cm !== null ? (float) $this->length_cm : null,
            'body_fat_percentage' => $this->body_fat_percentage !== null ? (float) $this->body_fat_percentage : null,
            'muscle_mass_kg' => $this->muscle_mass_kg !== null ? (float) $this->muscle_mass_kg : null,
            'bmi' => $this->bmi !== null ? (float) $this->bmi : null,
            'notes' => $this->notes,
            'created_at' => optional($this->created_at)->toISOString(),
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}