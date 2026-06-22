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
        $summary = $this->safePointSummary((string) $user->id);
        $history = $this->safePointLogs((string) $user->id, 30);

        $payload = [
            'user' => $this->formatUser($user),
            'points' => $summary,
            'level' => $summary['level_summary'] ?? $this->defaultPointSummary()['level_summary'],
            'achievements' => $summary['achievements'] ?? [],
            'history' => $history,
        ];

        return response()->json([
            'success' => true,
            'message' => 'Profile loaded successfully.',
            'data' => $payload,
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
        $summary = $this->safePointSummary((string) $user->id);
        $history = $this->safePointLogs((string) $user->id, 30);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data' => [
                'user' => $this->formatUser($freshUser),
                'points' => $summary,
                'level' => $summary['level_summary'] ?? $this->defaultPointSummary()['level_summary'],
                'achievements' => $summary['achievements'] ?? [],
                'history' => $history,
            ],
        ]);
    }

    public function points(Request $request): JsonResponse
    {
        $summary = $this->safePointSummary((string) $request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Profile points loaded successfully.',
            'data' => $summary,
        ]);
    }

    public function pointLogs(Request $request): JsonResponse
    {
        $limit = min(100, max(1, (int) $request->query('limit', 30)));

        return response()->json([
            'success' => true,
            'message' => 'Profile point logs loaded successfully.',
            'data' => $this->safePointLogs((string) $request->user()->id, $limit),
        ]);
    }

    private function safePointSummary(string $userId): array
    {
        try {
            return $this->userPointService->summary($userId);
        } catch (\Throwable $e) {
            report($e);

            return $this->defaultPointSummary();
        }
    }

    private function safePointLogs(string $userId, int $limit): array
    {
        try {
            return $this->userPointService->logs($userId, $limit);
        } catch (\Throwable $e) {
            report($e);

            return [];
        }
    }

    private function defaultPointSummary(): array
    {
        return [
            'current_points' => 0,
            'points' => 0,
            'level' => 1,
            'current_level' => 1,
            'total_points' => 0,
            'current_threshold' => 0,
            'next_level' => 2,
            'next_threshold' => 50000,
            'next_level_points' => 50000,
            'points_to_next_level' => 50000,
            'remaining_points' => 50000,
            'progress_percent' => 0,
            'progress_percentage' => 0,
            'level_label' => 'Level 1',
            'level_summary' => [
                'current_level' => 1,
                'current_threshold' => 0,
                'next_level' => 2,
                'next_threshold' => 50000,
                'remaining_points' => 50000,
                'progress_percent' => 0,
                'label' => 'Level 1',
            ],
            'achievements' => [
                [
                    'key' => 'first_points',
                    'title' => 'First Points',
                    'description' => 'Earn your first points.',
                    'unlocked' => false,
                ],
                [
                    'key' => 'level_2',
                    'title' => 'Level 2',
                    'description' => 'Reach Level 2.',
                    'unlocked' => false,
                ],
                [
                    'key' => 'level_5',
                    'title' => 'Level 5',
                    'description' => 'Reach Level 5.',
                    'unlocked' => false,
                ],
                [
                    'key' => 'points_500',
                    'title' => '500 Points Club',
                    'description' => 'Earn 500 total points.',
                    'unlocked' => false,
                ],
                [
                    'key' => 'points_1000',
                    'title' => '1,000 Points Club',
                    'description' => 'Earn 1,000 total points.',
                    'unlocked' => false,
                ],
            ],
            'earning_ideas' => [],
        ];
    }

    private function formatUser(object $user): array
    {
        return [
            'id' => (string) ($user->id ?? ''),
            'name' => $user->name ?? '',
            'email' => $user->email ?? '',
            'phone' => $user->phone ?? null,
            'role' => $user->role ?? 'Application Owner / User',
            'status' => $user->status ?? 'active',
            'plan' => $user->plan ?? 'Personal OS',
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
