<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\UserPointService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function __construct(
        private readonly UserPointService $userPointService
    ) {
    }

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $points = $this->safePointSummary((string) $user->id);

        return response()->json([
            'success' => true,
            'message' => 'Profile loaded successfully.',
            'data' => [
                'user' => $this->formatUser($user),
                'points' => $points,
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $rules = [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => [
                'sometimes',
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'phone' => ['sometimes', 'nullable', 'string', 'max:50'],
        ];

        $validated = $request->validate($rules);

        $allowed = [];
        foreach (['name', 'email', 'phone'] as $field) {
            if (array_key_exists($field, $validated) && Schema::hasColumn('users', $field)) {
                $allowed[$field] = $validated[$field];
            }
        }

        if (! empty($allowed)) {
            $allowed['updated_at'] = now();

            DB::table('users')
                ->where('id', $user->id)
                ->update($allowed);
        }

        $freshUser = DB::table('users')->where('id', $user->id)->first();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data' => [
                'user' => $this->formatUser($freshUser),
                'points' => $this->safePointSummary((string) $user->id),
            ],
        ]);
    }

    public function points(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Profile points loaded successfully.',
            'data' => $this->safePointSummary((string) $request->user()->id),
        ]);
    }

    public function pointLogs(Request $request): JsonResponse
    {
        $limit = min(100, max(1, (int) $request->query('limit', 30)));

        return response()->json([
            'success' => true,
            'message' => 'Profile point logs loaded successfully.',
            'data' => $this->userPointService->logs((string) $request->user()->id, $limit),
        ]);
    }


    private function safePointSummary(string $userId): array
    {
        try {
            if (! Schema::hasTable('user_points')) {
                return $this->defaultPointSummary();
            }

            return $this->userPointService->summary($userId);
        } catch (\Throwable $e) {
            return $this->defaultPointSummary();
        }
    }

    private function defaultPointSummary(): array
    {
        return [
            'level' => 1,
            'total_points' => 0,
            'current_level_points' => 0,
            'next_level_points' => 100,
            'progress_percentage' => 0,
        ];
    }

    private function formatUser(object $user): array
    {
        return [
            'id' => (string) ($user->id ?? ''),
            'name' => $user->name ?? '',
            'email' => $user->email ?? '',
            'phone' => $user->phone ?? null,
            'status' => $user->status ?? null,
            'avatar_url' => $this->avatarUrl($user),
            'created_at' => $user->created_at ?? null,
            'updated_at' => $user->updated_at ?? null,
        ];
    }

    private function avatarUrl(object $user): string
    {
        $name = urlencode((string) ($user->name ?? 'Nix User'));

        return "https://ui-avatars.com/api/?name={$name}&background=2563eb&color=fff";
    }
}
