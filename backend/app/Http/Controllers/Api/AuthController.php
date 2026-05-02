<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],

            /*
             |--------------------------------------------------------------------------
             | Password Handling
             |--------------------------------------------------------------------------
             | Your project currently uses password_hash for login verification.
             | We store both:
             | - password: Laravel hashed cast support
             | - password_hash: your existing login field
             */
            'password' => $validated['password'],
            
        ]);

        /*
         |--------------------------------------------------------------------------
         | Default Role
         |--------------------------------------------------------------------------
         | Every newly registered user receives the normal "user" role.
         | Admin role is still handled by your SecurityRolePermissionSeeder.
         */
        if (method_exists($user, 'assignRole')) {
            $user->assignRole('user');
        }

        $token = $user->createToken('api-token')->plainTextToken;

        $user->load('roles', 'permissions');

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully.',
            'data' => [
                'user' => $this->formatUserSecurityResponse($user),
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid login credentials.'],
            ]);
        }

        /*
         |--------------------------------------------------------------------------
         | Optional Security Hardening
         |--------------------------------------------------------------------------
         | Delete old tokens so one login = one active API token.
         | Comment this line if you want multi-device login.
         */
        // $user->tokens()->delete();

        $token = $user->createToken('api-token')->plainTextToken;

        $user->load('roles', 'permissions');

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => [
                'user' => $this->formatUserSecurityResponse($user),
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        $user->load('roles', 'permissions');

        return response()->json([
            'success' => true,
            'message' => 'Authenticated user loaded successfully.',
            'data' => [
                'user' => $this->formatUserSecurityResponse($user),
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();

        if ($token) {
            $token->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }

    public function logoutAll(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out from all devices successfully.',
        ]);
    }

    private function formatUserSecurityResponse(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,

            /*
             |--------------------------------------------------------------------------
             | Security Data for Vue Frontend
             |--------------------------------------------------------------------------
             | These are used by:
             | - Vue Router Guards
             | - Sidebar Menu Visibility
             | - Button-Level Permissions
             */
            'roles' => $user->getRoleNames()->values(),
            'permissions' => $user->getAllPermissions()
                ->pluck('name')
                ->values(),
        ];
    }
}