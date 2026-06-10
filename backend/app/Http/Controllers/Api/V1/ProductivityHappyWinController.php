<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProductivityHappyWin;
use Illuminate\Http\Request;

class ProductivityHappyWinController extends Controller
{
    public function index(Request $request)
    {
        $query = ProductivityHappyWin::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('win_date')
            ->orderByDesc('created_at');

        if ($request->filled('mood')) {
            $query->where('mood', (string) $request->input('mood'));
        }

        if ($request->filled('from')) {
            $query->whereDate('win_date', '>=', $request->input('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('win_date', '<=', $request->input('to'));
        }

        if ($request->filled('search')) {
            $search = (string) $request->input('search');

            $query->where(function ($subQuery) use ($search) {
                $subQuery
                    ->where('title', 'ILIKE', "%{$search}%")
                    ->orWhere('description', 'ILIKE', "%{$search}%")
                    ->orWhere('mood', 'ILIKE', "%{$search}%");
            });
        }

        return response()->json([
            'success' => true,
            'message' => 'Happy wins loaded successfully.',
            'data' => $query->get(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateHappyWin($request);

        $happyWin = ProductivityHappyWin::query()->create([
            'user_id' => $request->user()->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'win_date' => $validated['win_date'] ?? now()->toDateString(),
            'mood' => $validated['mood'] ?? null,
            'score' => $validated['score'] ?? 1,
            'metadata' => $validated['metadata'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Happy win created successfully.',
            'data' => $happyWin->fresh(),
        ], 201);
    }

    public function show(Request $request, ProductivityHappyWin $happyWin)
    {
        $this->authorizeHappyWin($request, $happyWin);

        return response()->json([
            'success' => true,
            'message' => 'Happy win loaded successfully.',
            'data' => $happyWin->fresh(),
        ]);
    }

    public function update(Request $request, ProductivityHappyWin $happyWin)
    {
        $this->authorizeHappyWin($request, $happyWin);

        $validated = $this->validateHappyWin($request, false);

        $happyWin->fill([
            'title' => $validated['title'] ?? $happyWin->title,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : $happyWin->description,
            'win_date' => $validated['win_date'] ?? $happyWin->win_date,
            'mood' => array_key_exists('mood', $validated) ? $validated['mood'] : $happyWin->mood,
            'score' => $validated['score'] ?? $happyWin->score,
            'metadata' => array_key_exists('metadata', $validated) ? $validated['metadata'] : $happyWin->metadata,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Happy win updated successfully.',
            'data' => $happyWin->fresh(),
        ]);
    }

    public function destroy(Request $request, ProductivityHappyWin $happyWin)
    {
        $this->authorizeHappyWin($request, $happyWin);

        $happyWin->delete();

        return response()->json([
            'success' => true,
            'message' => 'Happy win deleted successfully.',
        ]);
    }

    private function validateHappyWin(Request $request, bool $creating = true): array
    {
        return $request->validate([
            'title' => [$creating ? 'required' : 'sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'win_date' => ['nullable', 'date'],
            'mood' => ['nullable', 'string', 'max:80'],
            'score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'metadata' => ['nullable', 'array'],
        ]);
    }

    private function authorizeHappyWin(Request $request, ProductivityHappyWin $happyWin): void
    {
        abort_if($happyWin->user_id !== $request->user()->id, 403, 'This happy win does not belong to the current user.');
    }
}
