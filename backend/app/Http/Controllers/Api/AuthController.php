<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();
        $email = strtolower(trim($validated['email']));

        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            if ($user && Schema::hasColumn('users', 'failed_login_attempts')) {
                $user->increment('failed_login_attempts');
            }

            return response()->json([
                'success' => false,
                'message' => 'Invalid login credentials.',
            ], 401);
        }

        if (Schema::hasColumn('users', 'is_active') && ! (bool) $user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Your account is inactive.',
            ], 403);
        }

        if (
            Schema::hasColumn('users', 'status')
            && ! in_array(strtoupper((string) $user->status), ['ACTIVE'], true)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Your account is not active.',
            ], 403);
        }

        // Keep one active API token per user for a clean PWA session.
        $user->tokens()->delete();

        $token = $user->createToken('nixlifeos')->plainTextToken;

        $updates = [];

        if (Schema::hasColumn('users', 'last_login_at')) {
            $updates['last_login_at'] = now();
        }

        if (Schema::hasColumn('users', 'last_login_ip')) {
            $updates['last_login_ip'] = $request->ip();
        }

        if (Schema::hasColumn('users', 'failed_login_attempts')) {
            $updates['failed_login_attempts'] = 0;
        }

        if (! empty($updates)) {
            $user->forceFill($updates)->save();
        }

        $user->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => [
                'user' => $this->formatUser($user),
                'token' => $token,
                'token_type' => 'Bearer',
                'expires_in_minutes' => 1440,
            ],
        ]);
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $email = strtolower(trim($validated['email']));

        $user = new User();

        // Only set a UUID manually when the users.id column is actually UUID/string based.
        // Do NOT set id for normal bigint auto-increment IDs.
        if ($this->userIdNeedsUuid()) {
            $user->id = (string) Str::uuid();
        }

        $user->forceFill([
            'name' => trim($validated['name']),
            'email' => $email,
            'password' => Hash::make($validated['password']),
        ]);

        if (Schema::hasColumn('users', 'phone')) {
            $user->phone = $validated['phone'] ?? null;
        }

        if (Schema::hasColumn('users', 'status')) {
            $user->status = 'ACTIVE';
        }

        if (Schema::hasColumn('users', 'is_active')) {
            $user->is_active = true;
        }

        if (Schema::hasColumn('users', 'role')) {
            $user->role = 'user';
        }

        $user->save();

        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole('user');
            } catch (\Throwable $e) {
                // Keep registration working even if roles are not seeded yet.
            }
        }

        $token = $user->createToken('nixlifeos')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful.',
            'data' => [
                'user' => $this->formatUser($user->fresh()),
                'token' => $token,
                'token_type' => 'Bearer',
                'expires_in_minutes' => 1440,
            ],
        ], 201);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Authenticated user loaded successfully.',
            'data' => [
                'user' => $this->formatUser($request->user()),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $token = $request->user()?->currentAccessToken();

        if ($token) {
            $token->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logout successful.',
        ]);
    }

    private function userIdNeedsUuid(): bool
    {
        if (! Schema::hasColumn('users', 'id')) {
            return false;
        }

        try {
            $type = Schema::getColumnType('users', 'id');
        } catch (\Throwable $e) {
            return false;
        }

        return in_array($type, ['uuid', 'string', 'char'], true);
    }

    private function formatUser(?User $user): array
    {
        if (! $user) {
            return [];
        }

        $roles = [];
        $permissions = [];

        if (method_exists($user, 'getRoleNames')) {
            $roles = $user->getRoleNames()->values()->toArray();
        }

        if (method_exists($user, 'getAllPermissions')) {
            $permissions = $user->getAllPermissions()->pluck('name')->values()->toArray();
        }

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'roles' => $roles,
            'permissions' => $permissions,
        ];
    }
}
