<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\NutritionCustomFood;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class NutritionCustomFoodController extends Controller
{
    public function index(Request $request)
    {
        $userId = Auth::id();

        $query = NutritionCustomFood::query()
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('is_global', true);
            });

        if ($request->filled('search')) {
            $search = strtolower($request->search);

            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(brand) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(category) LIKE ?', ["%{$search}%"]);
            });
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        $foods = $query
            ->orderBy('name')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'message' => 'Custom foods loaded successfully.',
            'data' => $foods,
        ]);
    }

    public function store(Request $request)
    {
        $userId = Auth::id();

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:150',
                Rule::unique('nutrition_custom_foods')
                    ->where('user_id', $userId)
                    ->where('brand', $request->brand)
                    ->whereNull('deleted_at'),
            ],
            'brand' => ['nullable', 'string', 'max:150'],
            'category' => ['nullable', 'string', 'max:100'],

            'serving_size' => ['required', 'numeric', 'min:0.01', 'max:10000'],
            'serving_unit' => ['required', 'string', 'max:50'],

            'calories' => ['required', 'numeric', 'min:0', 'max:5000'],
            'protein_g' => ['required', 'numeric', 'min:0', 'max:500'],
            'carbs_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'fat_g' => ['nullable', 'numeric', 'min:0', 'max:500'],

            'sodium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'potassium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'phosphorus_mg' => ['required', 'numeric', 'min:0', 'max:10000'],

            'is_personal' => ['boolean'],
            'is_global' => ['boolean'],
        ]);

        $food = NutritionCustomFood::create([
            ...$validated,
            'user_id' => $validated['is_global'] ?? false ? null : $userId,
            'is_personal' => !($validated['is_global'] ?? false),
            'is_global' => $validated['is_global'] ?? false,
            'is_ai_recommended' => false,
            'ai_metadata' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Custom food created successfully.',
            'data' => $food,
        ], 201);
    }

    public function show(string $id)
    {
        $food = $this->findAccessibleFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Custom food loaded successfully.',
            'data' => $food,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $food = $this->findOwnedFood($id);
        $userId = Auth::id();

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:150',
                Rule::unique('nutrition_custom_foods')
                    ->ignore($food->id)
                    ->where('user_id', $userId)
                    ->where('brand', $request->brand)
                    ->whereNull('deleted_at'),
            ],
            'brand' => ['nullable', 'string', 'max:150'],
            'category' => ['nullable', 'string', 'max:100'],

            'serving_size' => ['required', 'numeric', 'min:0.01', 'max:10000'],
            'serving_unit' => ['required', 'string', 'max:50'],

            'calories' => ['required', 'numeric', 'min:0', 'max:5000'],
            'protein_g' => ['required', 'numeric', 'min:0', 'max:500'],
            'carbs_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'fat_g' => ['nullable', 'numeric', 'min:0', 'max:500'],

            'sodium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'potassium_mg' => ['required', 'numeric', 'min:0', 'max:10000'],
            'phosphorus_mg' => ['required', 'numeric', 'min:0', 'max:10000'],

            'is_personal' => ['boolean'],
            'is_global' => ['boolean'],
        ]);

        $food->update([
            ...$validated,
            'user_id' => $validated['is_global'] ?? false ? null : $userId,
            'is_personal' => !($validated['is_global'] ?? false),
            'is_global' => $validated['is_global'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Custom food updated successfully.',
            'data' => $food->fresh(),
        ]);
    }

    public function destroy(string $id)
    {
        $food = $this->findOwnedFood($id);

        $food->delete();

        return response()->json([
            'success' => true,
            'message' => 'Custom food deleted successfully.',
        ]);
    }

    private function findAccessibleFood(string $id): NutritionCustomFood
    {
        $userId = Auth::id();

        return NutritionCustomFood::where('id', $id)
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('is_global', true);
            })
            ->firstOrFail();
    }

    private function findOwnedFood(string $id): NutritionCustomFood
    {
        $userId = Auth::id();

        return NutritionCustomFood::where('id', $id)
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhereNull('user_id');
            })
            ->firstOrFail();
    }
}