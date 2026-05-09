<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Role::firstOrCreate([
            'name' => 'user',
            'guard_name' => 'web',
        ]);
    }

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
                'success',
                'message',
                'data' => [
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'roles',
                        'permissions',
                    ],
                    'token',
                    'token_type',
                ],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'nix@example.com')
            ->assertJsonPath('data.token_type', 'Bearer');

        $this->assertDatabaseHas('users', [
            'email' => 'nix@example.com',
        ]);
    }

    public function test_user_can_login(): void
    {
        $user = User::factory()->create([
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
        ]);

        $user->assignRole('user');

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nix@example.com',
            'password' => 'StrongPass#2026',
        ]);

        $response
            ->assertOk()
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'roles',
                        'permissions',
                    ],
                    'token',
                    'token_type',
                ],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'nix@example.com')
            ->assertJsonPath('data.token_type', 'Bearer');
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
        $user->assignRole('user');

        $token = $user->createToken('phpunit')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/auth/me');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', $user->email);
    }

    public function test_authenticated_user_can_logout(): void
    {
        $user = User::factory()->create();
        $user->assignRole('user');

        $token = $user->createToken('phpunit')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
            'Accept' => 'application/json',
        ])->postJson('/api/v1/auth/logout');

        $response
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}