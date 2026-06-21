<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminPointIdeaController extends Controller
{
    private const LEVELS = [
        1 => 0,
        2 => 50000,
        3 => 125000,
        4 => 225000,
        5 => 350000,
        6 => 500000,
        7 => 650000,
        8 => 800000,
        9 => 950000,
        10 => 1000000,
    ];

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
            'level' => ['nullable', 'integer', 'min:1', 'max:10'],
        ]);

        $query = DB::table('admin_point_ideas');

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        if (!empty($validated['level'])) {
            $query->where('level', $validated['level']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Admin point ideas loaded successfully.',
            'data' => $query
                ->orderByRaw('CASE WHEN level IS NULL THEN 1 ELSE 0 END')
                ->orderBy('level')
                ->orderBy('target_points')
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());

        $id = (string) Str::uuid();

        DB::table('admin_point_ideas')->insert([
            'id' => $id,
            'user_id' => optional($request->user())->id,
            'name' => $validated['name'],
            'description' => $validated['description'] ?? null,
            'points' => (int) ($validated['points'] ?? 0),
            'target_points' => $validated['target_points'] ?? null,
            'level' => $validated['level'] ?? null,
            'status' => $validated['status'] ?? 'active',
            'metadata' => isset($validated['metadata']) ? json_encode($validated['metadata']) : null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Admin point idea created successfully.',
            'data' => DB::table('admin_point_ideas')->where('id', $id)->first(),
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate($this->rules(true));

        $update = [];

        foreach (['name', 'description', 'points', 'target_points', 'level', 'status'] as $field) {
            if (array_key_exists($field, $validated)) {
                $update[$field] = $validated[$field];
            }
        }

        if (array_key_exists('metadata', $validated)) {
            $update['metadata'] = $validated['metadata'] !== null ? json_encode($validated['metadata']) : null;
        }

        $update['updated_at'] = now();

        $updated = DB::table('admin_point_ideas')->where('id', $id)->update($update);

        if ($updated < 1) {
            return response()->json([
                'success' => false,
                'message' => 'Admin point idea not found or not updated.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Admin point idea updated successfully.',
            'data' => DB::table('admin_point_ideas')->where('id', $id)->first(),
        ]);
    }

    public function destroy(string $id): JsonResponse
    {
        DB::table('admin_point_ideas')->where('id', $id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Admin point idea deleted successfully.',
        ]);
    }

    public function levels(): JsonResponse
    {
        $levels = collect(self::LEVELS)
            ->map(fn (int $requiredPoints, int $level) => [
                'level' => $level,
                'required_points' => $requiredPoints,
                'label' => "Level {$level}",
            ])
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Admin point levels loaded successfully.',
            'data' => $levels,
        ]);
    }

    private function rules(bool $isUpdate = false): array
    {
        return [
            'name' => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'points' => ['nullable', 'integer', 'min:0'],
            'target_points' => ['nullable', 'integer', 'min:0'],
            'level' => ['nullable', 'integer', 'min:1', 'max:10'],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
