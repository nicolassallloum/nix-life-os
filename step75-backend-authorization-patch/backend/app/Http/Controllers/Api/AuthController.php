<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Models\Role;

class AuthController extends Controller
{
    private const DEFAULT_TOKEN_EXPIRATION_MINUTES = 1440;

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'min:2',
                'max:150',
                "regex:/^[\\pL\\pM\\pN\\s.'-]+$/u",
            ],
            'email' => ['required', 'string', 'email:rfc', 'max:190', 'unique:users,email'],
            'password' => [
                'required',
                'confirmed',
                Password::min(8)->letters()->mixedCase()->numbers()->symbols(),
            ],
        ], [
            'name.regex' => 'The name may only contain letters, numbers, spaces, dots, apostrophes, and hyphens.',
        ]);

        $user = User::create([
            'name' => trim($validated['name']),
            'email' => mb_strtolower(trim($validated['email'])),
            'password' => $validated['password'],
            'role' => 'user',
            'is_active' => true,
        ]);

        $this->assignDefaultRole($user);

        $token = $this->createApiToken($user, $request);

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully.',
            'data' => [
                'user' => $this->userPayload($user->fresh()),
                'token' => $token,
                'token_type' => 'Bearer',
                'expires_in_minutes' => $this->tokenExpirationMinutes(),
            ],
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email:rfc'],
            'password' => ['required', 'string'],
        ]);

        $email = mb_strtolower(trim($validated['email']));
        $throttleKey = $this->throttleKey($email, $request);

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            return response()->json([
                'success' => false,
                'message' => 'Too many login attempts. Please try again later.',
            ], 429)->header('Retry-After', (string) RateLimiter::availableIn($throttleKey));
        }

        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            RateLimiter::hit($throttleKey, 60);

            return response()->json([
                'success' => false,
                'message' => 'Invalid login credentials.',
            ], 401);
        }

        if (property_exists($user, 'is_active') || array_key_exists('is_active', $user->getAttributes())) {
            if (! $user->is_active) {
                return response()->json([
                    'success' => false,
                    'message' => 'This account is inactive.',
                ], 403);
            }
        }

        RateLimiter::clear($throttleKey);

        $user->forceFill([
            'last_login_at' => now(),
        ])->save();

        $token = $this->createApiToken($user, $request);

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => [
                'user' => $this->userPayload($user->fresh()),
                'token' => $token,
                'token_type' => 'Bearer',
                'expires_in_minutes' => $this->tokenExpirationMinutes(),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Authenticated user loaded successfully.',
            'data' => [
                'user' => $this->userPayload($request->user()),
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
            'message' => 'Logged out successfully.',
        ]);
    }

    private function createApiToken(User $user, Request $request): string
    {
        $expiresAt = now()->addMinutes($this->tokenExpirationMinutes());
        $deviceName = $request->userAgent()
            ? 'api-token-' . Str::limit(sha1($request->userAgent()), 12, '')
            : 'api-token';

        return $user->createToken($deviceName, ['*'], $expiresAt)->plainTextToken;
    }

    private function tokenExpirationMinutes(): int
    {
        return (int) env('AUTH_TOKEN_EXPIRATION_MINUTES', self::DEFAULT_TOKEN_EXPIRATION_MINUTES);
    }

    private function assignDefaultRole(User $user): void
    {
        try {
            if (class_exists(Role::class) && Role::where('name', 'user')->where('guard_name', 'web')->exists()) {
                $user->assignRole('user');
            }
        } catch (\Throwable $e) {
            Log::warning('Default role assignment failed during registration.', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function userPayload(User $user): array
    {
        $payload = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ];

        if (method_exists($user, 'getRoleNames')) {
            $payload['roles'] = $user->getRoleNames()->values()->all();
        } else {
            $payload['roles'] = [$user->role ?? 'user'];
        }

        if (method_exists($user, 'getAllPermissions')) {
            $payload['permissions'] = $user->getAllPermissions()->pluck('name')->values()->all();
        } else {
            $payload['permissions'] = [];
        }

        return $payload;
    }

    private function throttleKey(string $email, Request $request): string
    {
        return Str::transliterate($email . '|' . $request->ip());
    }
}
