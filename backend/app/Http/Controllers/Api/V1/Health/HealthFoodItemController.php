<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthFoodItemResource;
use App\Models\HealthFoodItem;
use Illuminate\Http\Request;

class HealthFoodItemController extends Controller
{
    public function index(Request $request)
    {
        $query = HealthFoodItem::query()
            ->where('is_active', true)
            ->where(function ($q) use ($request) {
                $q->whereNull('user_id')
                  ->orWhere('user_id', $request->user()->id);
            });

        if ($request->filled('search')) {
            $query->where('food_name', 'ILIKE', '%' . $request->search . '%');
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->boolean('ckd_friendly')) {
            $query->where('is_ckd_friendly', true);
        }

        $foods = $query->orderBy('food_name')->paginate(20);

        return HealthFoodItemResource::collection($foods);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'food_name' => ['required', 'string', 'max:255'],
            'brand_name' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],

            'calories_per_100g' => ['required', 'numeric', 'min:0'],
            'protein_per_100g' => ['required', 'numeric', 'min:0'],
            'carbs_per_100g' => ['required', 'numeric', 'min:0'],
            'fat_per_100g' => ['required', 'numeric', 'min:0'],

            'sodium_per_100g_mg' => ['required', 'numeric', 'min:0'],
            'potassium_per_100g_mg' => ['required', 'numeric', 'min:0'],
            'phosphorus_per_100g_mg' => ['required', 'numeric', 'min:0'],

            'is_ckd_friendly' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        $food = HealthFoodItem::create([
            ...$data,
            'user_id' => $request->user()->id,
            'is_custom' => true,
            'is_ckd_friendly' => $data['is_ckd_friendly'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Food item created successfully.',
            'data' => new HealthFoodItemResource($food),
        ], 201);
    }

    public function show(Request $request, HealthFoodItem $healthFoodItem)
    {
        abort_if(
            $healthFoodItem->user_id !== null && $healthFoodItem->user_id !== $request->user()->id,
            403
        );

        return new HealthFoodItemResource($healthFoodItem);
    }
}