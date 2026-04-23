STEP 4 — Authentication System
Size:1,093,328,896 bytes
DB Size:10119 kB

1) Install Sanctum

Run:

composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate

For API token auth, Sanctum issues personal access tokens and supports token abilities/scopes, which fits well for future role or permission expansion.

2) Users table design

Use a role-ready schema with one primary role column first. You can later evolve into roles and user_roles tables without breaking the auth flow.

Create migration:

php artisan make:migration create_users_table
database/migrations/xxxx_xx_xx_xxxxxx_create_users_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name', 150);
            $table->string('email', 190)->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('role', 50)->default('user'); // role-ready
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->rememberToken();
            $table->timestamps();

            $table->index(['role', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};

Laravel migrations support standard indexes and unique constraints, and Eloquent expects a single unique primary key, so a UUID primary key is a solid fit here.

3) Update User model
app/Models/User.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable, HasUuids;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
        'last_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'is_active' => 'boolean',
            'password' => 'hashed',
        ];
    }
}

'password' => 'hashed' lets Laravel hash automatically when assigning passwords through the model, using the configured hashing driver. Laravel’s hashing system supports Bcrypt and Argon2id.

4) Configure auth
config/auth.php

Make sure the API guard uses Sanctum:

'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],

    'sanctum' => [
        'driver' => 'sanctum',
        'provider' => 'users',
    ],
],
5) Create request validation classes
php artisan make:request RegisterRequest
php artisan make:request LoginRequest
app/Http/Requests/RegisterRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => [
                'required',
                'confirmed',
                Password::min(10)
                    ->letters()
                    ->mixedCase()
                    ->numbers()
                    ->symbols(),
            ],
        ];
    }
}
app/Http/Requests/LoginRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ];
    }
}
6) Create AuthController
php artisan make:controller Api/AuthController
app/Http/Controllers/Api/AuthController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->string('name')->toString(),
            'email' => strtolower($request->string('email')->toString()),
            'password' => $request->string('password')->toString(),
            'role' => 'user',
            'is_active' => true,
        ]);

        $token = $user->createToken(
            $request->userAgent() ?: 'api-client',
            ['*']
        )->plainTextToken;

        return response()->json([
            'message' => 'User registered successfully.',
            'token_type' => 'Bearer',
            'access_token' => $token,
            'user' => $user,
        ], 201);
    }

    /**
     * @throws ValidationException
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $email = strtolower($request->string('email')->toString());

        /** @var User|null $user */
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($request->string('password')->toString(), $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (! $user->is_active) {
            return response()->json([
                'message' => 'This account is inactive.',
            ], 403);
        }

        $user->update([
            'last_login_at' => now(),
        ]);

        $deviceName = $request->input('device_name', $request->userAgent() ?: 'api-client');

        $token = $user->createToken($deviceName, ['*'])->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'token_type' => 'Bearer',
            'access_token' => $token,
            'user' => $user,
        ]);
    }

    public function me(): JsonResponse
    {
        return response()->json([
            'user' => request()->user(),
        ]);
    }

    public function logout(): JsonResponse
    {
        /** @var User $user */
        $user = request()->user();

        $currentToken = $user->currentAccessToken();

        if ($currentToken) {
            $currentToken->delete();
        }

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }

    public function logoutAll(): JsonResponse
    {
        /** @var User $user */
        $user = request()->user();

        $user->tokens()->delete();

        return response()->json([
            'message' => 'Logged out from all devices successfully.',
        ]);
    }
}

This uses Hash::check() for verification and Sanctum tokens for API authentication. Laravel documents Hash as the standard hashing interface, and Sanctum as the first-party lightweight token system.

7) API routes
routes/api.php
<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
    });
});
8) Optional admin middleware for role-ready access

Create middleware:

php artisan make:middleware EnsureUserHasRole
app/Http/Middleware/EnsureUserHasRole.php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRole
{
    /**
     * @param  array<int, string>  ...$roles
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        if (! in_array($user->role, $roles, true)) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        return $next($request);
    }
}

Register it in bootstrap/app.php or middleware registration area depending on your Laravel structure.

Example usage:

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin/dashboard', function () {
        return response()->json(['message' => 'Welcome admin']);
    });
});
9) Example JSON requests
Register

POST /api/v1/auth/register

{
  "name": "Nix",
  "email": "nix@example.com",
  "password": "StrongPass#2026",
  "password_confirmation": "StrongPass#2026"
}
Login

POST /api/v1/auth/login

{
  "email": "nix@example.com",
  "password": "StrongPass#2026",
  "device_name": "postman"
}
Me

GET /api/v1/auth/me

Header:

Authorization: Bearer YOUR_TOKEN
Accept: application/json
Logout

POST /api/v1/auth/logout

Header:

Authorization: Bearer YOUR_TOKEN
Accept: application/json
10) Testing steps
A. Database + migration
php artisan migrate
B. Start server
php artisan serve
C. Test with cURL
----I'M Here 
Register
curl -X POST http://127.0.0.1:8000/api/v1/auth/register \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nix",
    "email": "nix@example.com",
    "password": "StrongPass#2026",
    "password_confirmation": "StrongPass#2026"
  }'

{"message":"User registered successfully.","token_type":"Bearer","access_token":"2|4qgcTajo3kb9vjvog7TKU4JuPWROS7hojjC9hVdY2131a73a","user":{"name":"Nix","email":"nix@example.com","role":"user","is_active":true,"id":"019d7b31-3d0b-7177-acb6-7959f90a3a7a","updated_at":"2026-04-11T06:18:37.000000Z","created_at":"2026-04-11T06:18:37.000000Z"


Login
curl -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nix@example.com",
    "password": "StrongPass#2026",
    "device_name": "cli"
  }'

{"message":"Login successful.","token_type":"Bearer","access_token":"3|PRgtT1d6Vfkhj9d1JHc2hkxKqBS9DQXSdz5dDEGZ6f32cc59","user":{"id":"019d7b31-3d0b-7177-acb6-7959f90a3a7a","name":"Nix","email":"nix@example.com","email_verified_at":null,"role":"user","is_active":true,"last_login_at":"2026-04-11T06:18:44.000000Z","created_at":"2026-04-11T0n

Me
curl -X GET http://127.0.0.1:8000/api/v1/auth/me \
  -H "Accept: application/json" \
  -H "Authorization: Bearer PRgtT1d6Vfkhj9d1JHc2hkxKqBS9DQXSdz5dDEGZ6f32cc59"
Logout
curl -X POST http://127.0.0.1:8000/api/v1/auth/logout \
  -H "Accept: application/json" \
  -H "Authorization: Bearer PRgtT1d6Vfkhj9d1JHc2hkxKqBS9DQXSdz5dDEGZ6f32cc59"
11) Add feature tests

Create tests:

php artisan make:test AuthApiTest
tests/Feature/AuthApiTest.php
<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Nix',
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
            'password_confirmation' => 'StrongPass#2026',
        ]);

        $response
            ->assertCreated()
            ->assertJsonStructure([
                'message',
                'token_type',
                'access_token',
                'user' => ['id', 'name', 'email', 'role', 'is_active'],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'nix@example.com',
            'role' => 'user',
        ]);
    }

    public function test_user_can_login(): void
    {
        $user = User::factory()->create([
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
            'role' => 'user',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
            'device_name' => 'phpunit',
        ]);

        $response
            ->assertOk()
            ->assertJsonStructure([
                'message',
                'token_type',
                'access_token',
                'user' => ['id', 'name', 'email', 'role'],
            ]);
    }

    public function test_user_cannot_login_with_wrong_password(): void
    {
        User::factory()->create([
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nix@example.com',
            'password' => 'WrongPassword#2026',
        ]);

        $response->assertStatus(422);
    }

    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('phpunit')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/auth/me');

        $response
            ->assertOk()
            ->assertJsonPath('user.email', $user->email);
    }

    public function test_authenticated_user_can_logout(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('phpunit')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
            'Accept' => 'application/json',
        ])->postJson('/api/v1/auth/logout');

        $response->assertOk();
    }
}

Run tests:

php artisan test

Laravel’s factories are the standard way to create model test data in current Laravel.

12) Security recommendations

Use these in production:

Force HTTPS in production.
Rate-limit login and register endpoints.
Keep passwords hashed only, never encrypted or logged.
Revoke tokens on suspicious activity or password reset.
Add email verification before enabling sensitive actions.
Add password reset flow next.
Prefer short-lived tokens plus refresh strategy if your architecture requires stricter session control.
Add audit logging for login success/failure and logout events.

Laravel’s auth stack includes broader authentication and authorization facilities, while Sanctum is specifically the lightweight choice for tokens/session-backed API auth.

13) Best choice: JWT or Sanctum?

For your Laravel backend, I recommend:

Use Sanctum unless you specifically need third-party OAuth2-style JWT flows.

Why:

first-party Laravel package
simpler setup
secure for SPA, mobile, and internal APIs
supports token abilities
less maintenance than adding a separate JWT package

Laravel’s own docs explicitly position Sanctum as the simpler choice for API tokens, and Passport for OAuth2 use cases.

14) Minimal endpoint list

Your final auth API surface:

POST /api/v1/auth/register
POST /api/v1/auth/login
GET /api/v1/auth/me
POST /api/v1/auth/logout
POST /api/v1/auth/logout-all
15) Folder summary
app/
 ├── Http/
 │    ├── Controllers/
 │    │    └── Api/
 │    │         └── AuthController.php
 │    ├── Middleware/
 │    │    └── EnsureUserHasRole.php
 │    └── Requests/
 │         ├── LoginRequest.php
 │         └── RegisterRequest.php
 └── Models/
      └── User.php

database/
 └── migrations/
      └── create_users_table.php

routes/
 └── api.php

tests/
 └── Feature/
      └── AuthApiTest.php