<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class HealthLabTestController extends Controller
{
    public function index(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab tests loaded successfully.',
            'data' => [],
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'test_date' => ['required', 'date'],
            'test_name' => ['required', 'string', 'max:255'],
            'result_value' => ['required', 'string', 'max:100'],
            'unit' => ['nullable', 'string', 'max:50'],
            'reference_range' => ['nullable', 'string', 'max:100'],
            'lab_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lab test validation passed. Database table implementation is next.',
            'data' => $validated,
        ], 201);
    }

    public function show(string $id)
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab test detail placeholder.',
            'data' => [
                'id' => $id,
            ],
        ]);
    }

    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'test_date' => ['sometimes', 'date'],
            'test_name' => ['sometimes', 'string', 'max:255'],
            'result_value' => ['sometimes', 'string', 'max:100'],
            'unit' => ['nullable', 'string', 'max:50'],
            'reference_range' => ['nullable', 'string', 'max:100'],
            'lab_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lab test update validation passed. Database table implementation is next.',
            'data' => array_merge(['id' => $id], $validated),
        ]);
    }

    public function destroy(string $id)
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab test delete placeholder.',
            'data' => [
                'id' => $id,
            ],
        ]);
    }
}