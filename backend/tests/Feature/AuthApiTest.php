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
