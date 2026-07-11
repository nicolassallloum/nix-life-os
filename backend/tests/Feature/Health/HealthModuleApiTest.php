<?php

namespace Tests\Feature\Health;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HealthModuleApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['height_cm' => 170]);
        Sanctum::actingAs($this->user);
    }

    public function test_steps_weight_hydration_and_dashboard_summaries(): void
    {
        $step = $this->postJson('/api/v1/health/steps', [
            'log_date' => '2026-07-11',
            'steps' => 8000,
            'source' => 'manual',
        ]);
        $step->assertCreated()
            ->assertJsonPath('data.steps', 8000);

        $weight = $this->postJson('/api/v1/health/weight', [
            'log_date' => '2026-07-11',
            'weight_kg' => 64,
            'height_cm' => 170,
        ]);
        $weight->assertCreated()
            ->assertJsonPath('success', true);

        $hydration = $this->postJson('/api/v1/health/hydration', [
            'hydration_type' => 'Water',
            'quantity_ml' => 500,
            'log_date' => '2026-07-11',
        ]);
        $hydration->assertCreated()
            ->assertJsonPath('success', true);

        $this->getJson('/api/v1/health/steps/summary?from=2026-07-11&to=2026-07-11')
            ->assertOk()->assertJsonPath('success', true);
        $this->getJson('/api/v1/health/weight/summary?from_date=2026-07-11&to_date=2026-07-11')
            ->assertOk()->assertJsonPath('data.total_logs', 1);
        $this->getJson('/api/v1/health/hydration/summary?date=2026-07-11')
            ->assertOk()->assertJsonPath('success', true);
        $this->getJson('/api/v1/health/dashboard')
            ->assertOk()->assertJsonPath('success', true);
    }

    public function test_nutrition_crud_and_summary_calculation(): void
    {
        $create = $this->postJson('/api/v1/health/nutrition', [
            'meal_date' => '2026-07-11',
            'meal_type' => 'lunch',
            'food_name' => 'Rice meal',
            'quantity' => 1,
            'unit' => 'plate',
            'calories' => 450,
            'protein_g' => 12,
            'carbs_g' => 70,
            'fat_g' => 8,
            'sodium_mg' => 300,
            'potassium_mg' => 250,
            'phosphorus_mg' => 180,
        ]);
        $create->assertCreated()->assertJsonPath('data.food_name', 'Rice meal');
        $id = $create->json('data.id');

        $this->getJson('/api/v1/health/nutrition/summary?date=2026-07-11')
            ->assertOk()
            ->assertJsonPath('data.total_calories', 450)
            ->assertJsonPath('data.total_protein', 12)
            ->assertJsonPath('data.total_sodium', 300);

        $this->patchJson("/api/v1/health/nutrition/{$id}", ['calories' => 500])
            ->assertOk()->assertJsonPath('data.calories', '500.00');
        $this->deleteJson("/api/v1/health/nutrition/{$id}")->assertOk();
        $this->assertDatabaseMissing('health_nutrition_logs', ['id' => $id]);
    }

    public function test_sleep_mood_and_sport_crud(): void
    {
        $sleep = $this->postJson('/api/v1/health/sleep', [
            'sleep_date' => '2026-07-10',
            'bed_time' => '22:30',
            'wake_time' => '06:30',
            'quality' => 'good',
        ]);
        $sleep->assertCreated()->assertJsonPath('success', true);
        $sleepId = $sleep->json('data.id');

        $mood = $this->postJson('/api/v1/health/mood', [
            'mood_date' => '2026-07-11',
            'mood_label' => 'Good',
            'mood_score' => 8,
            'notes' => 'Productive day',
        ]);
        $mood->assertCreated()->assertJsonPath('success', true);
        $moodId = $mood->json('data.id');

        $sport = $this->postJson('/api/v1/health/sports', [
            'sport_type' => 'Walking',
            'calories_burned' => 180,
            'duration_minutes' => 35,
            'activity_date' => '2026-07-11',
        ]);
        $sport->assertCreated()->assertJsonPath('data.sport_type', 'Walking');
        $sportId = $sport->json('data.id');

        $this->getJson('/api/v1/health/sleep/summary')->assertOk()->assertJsonPath('success', true);
        $this->getJson('/api/v1/health/mood/summary')->assertOk()->assertJsonPath('success', true);
        $this->getJson('/api/v1/health/sports')->assertOk()->assertJsonPath('data.records.0.id', $sportId);

        $this->patchJson("/api/v1/health/sports/{$sportId}", ['duration_minutes' => 45])
            ->assertOk()->assertJsonPath('data.duration_minutes', 45);

        $this->deleteJson("/api/v1/health/sleep/{$sleepId}")->assertOk();
        $this->deleteJson("/api/v1/health/mood/{$moodId}")->assertOk();
        $this->deleteJson("/api/v1/health/sports/{$sportId}")->assertOk();
    }

    public function test_validation_user_isolation_reports_and_unauthenticated_access(): void
    {
        $this->postJson('/api/v1/health/weight', ['log_date' => 'bad', 'weight_kg' => 1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['log_date', 'weight_kg']);
        $this->postJson('/api/v1/health/sports', ['sport_type' => 'Invalid'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sport_type', 'calories_burned', 'duration_minutes', 'activity_date']);

        $step = $this->postJson('/api/v1/health/steps', ['log_date' => '2026-07-11', 'steps' => 1234]);
        $stepId = $step->json('data.id');

        $other = User::factory()->create();
        Sanctum::actingAs($other);
        $this->getJson("/api/v1/health/steps/{$stepId}")->assertNotFound();
        $this->getJson('/api/v1/health/reports/daily?date=2026-07-11')
            ->assertOk()->assertJsonPath('success', true);

        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/health/dashboard')->assertUnauthorized();
    }
}
