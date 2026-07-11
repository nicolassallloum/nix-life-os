<?php

namespace Tests\Feature\Todo;

use App\Models\TodoProject;
use App\Models\TodoTask;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TodoModuleApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_project_crud_and_project_task_listing(): void
    {
        $create = $this->postJson('/api/v1/todo/projects', [
            'name' => 'Bundle 7 Project',
            'description' => 'Production readiness tests',
            'status' => TodoProject::STATUS_ACTIVE,
            'start_date' => '2026-07-11',
            'end_date' => '2026-07-31',
        ]);

        $create
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Bundle 7 Project')
            ->assertJsonPath('data.total_tasks', 0)
            ->assertJsonPath('data.completion_percentage', 0);

        $projectId = $create->json('data.id');

        $task = TodoTask::query()->create([
            'user_id' => $this->user->id,
            'project_id' => $projectId,
            'title' => 'Project task',
            'task_type' => TodoTask::TYPE_WEEKLY,
            'status' => TodoTask::STATUS_PENDING,
            'priority' => TodoTask::PRIORITY_HIGH,
            'points' => 25,
            'sort_order' => 1,
        ]);

        $this->getJson("/api/v1/todo/projects/{$projectId}")
            ->assertOk()
            ->assertJsonPath('data.total_tasks', 1)
            ->assertJsonPath('data.tasks.0.id', $task->id)
            ->assertJsonPath('data.tasks.0.title', 'Project task');

        $this->patchJson("/api/v1/todo/projects/{$projectId}", [
            'name' => 'Updated Bundle 7 Project',
            'status' => TodoProject::STATUS_COMPLETED,
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Bundle 7 Project')
            ->assertJsonPath('data.status', TodoProject::STATUS_COMPLETED);

        $this->deleteJson("/api/v1/todo/projects/{$projectId}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('todo_projects', ['id' => $projectId]);
        $this->assertDatabaseHas('todo_tasks', [
            'id' => $task->id,
            'project_id' => null,
        ]);
    }

    public function test_task_crud_finish_and_reopen_rules(): void
    {
        $create = $this->postJson('/api/v1/todo/tasks', [
            'title' => 'Finish me',
            'task_type' => TodoTask::TYPE_DAILY,
            'priority' => TodoTask::PRIORITY_MEDIUM,
            'points' => 40,
        ]);

        $create
            ->assertCreated()
            ->assertJsonPath('data.status', TodoTask::STATUS_PENDING)
            ->assertJsonPath('data.task_type', TodoTask::TYPE_DAILY)
            ->assertJsonPath('data.points', 40);

        $taskId = $create->json('data.id');

        $this->patchJson("/api/v1/todo/tasks/{$taskId}", [
            'title' => 'Finish me now',
            'priority' => TodoTask::PRIORITY_HIGH,
        ])
            ->assertOk()
            ->assertJsonPath('data.title', 'Finish me now')
            ->assertJsonPath('data.priority', TodoTask::PRIORITY_HIGH);

        $finish = $this->patchJson("/api/v1/todo/tasks/{$taskId}/status", [
            'status' => TodoTask::STATUS_FINISHED,
        ]);

        $finish
            ->assertOk()
            ->assertJsonPath('data.status', TodoTask::STATUS_FINISHED);

        $this->assertNotNull($finish->json('data.completed_at'));

        $reopen = $this->patchJson("/api/v1/todo/tasks/{$taskId}/status", [
            'status' => TodoTask::STATUS_PENDING,
        ]);

        $reopen
            ->assertOk()
            ->assertJsonPath('data.status', TodoTask::STATUS_PENDING)
            ->assertJsonPath('data.completed_at', null);

        $this->deleteJson("/api/v1/todo/tasks/{$taskId}")
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('todo_tasks', ['id' => $taskId]);
    }

    public function test_move_and_reorder_persist_correctly(): void
    {
        $first = TodoTask::query()->create([
            'user_id' => $this->user->id,
            'title' => 'First',
            'task_type' => TodoTask::TYPE_GENERAL,
            'status' => TodoTask::STATUS_PENDING,
            'priority' => TodoTask::PRIORITY_MEDIUM,
            'points' => 10,
            'sort_order' => 1,
        ]);

        $second = TodoTask::query()->create([
            'user_id' => $this->user->id,
            'title' => 'Second',
            'task_type' => TodoTask::TYPE_GENERAL,
            'status' => TodoTask::STATUS_PENDING,
            'priority' => TodoTask::PRIORITY_MEDIUM,
            'points' => 20,
            'sort_order' => 2,
        ]);

        $this->patchJson("/api/v1/todo/tasks/{$first->id}/move", [
            'task_type' => TodoTask::TYPE_WEEKLY,
            'sort_order' => 5,
        ])
            ->assertOk()
            ->assertJsonPath('data.task_type', TodoTask::TYPE_WEEKLY)
            ->assertJsonPath('data.sort_order', 5);

        $this->patchJson('/api/v1/todo/tasks/reorder', [
            'tasks' => [
                ['id' => $first->id, 'sort_order' => 2],
                ['id' => $second->id, 'sort_order' => 1],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.0.id', $second->id)
            ->assertJsonPath('data.0.sort_order', 1)
            ->assertJsonPath('data.1.id', $first->id)
            ->assertJsonPath('data.1.sort_order', 2);

        $this->assertDatabaseHas('todo_tasks', [
            'id' => $first->id,
            'task_type' => TodoTask::TYPE_WEEKLY,
            'sort_order' => 2,
        ]);
    }

    public function test_dashboard_points_counts_and_project_progress_are_correct(): void
    {
        $project = TodoProject::query()->create([
            'user_id' => $this->user->id,
            'name' => 'Dashboard Project',
            'status' => TodoProject::STATUS_ACTIVE,
        ]);

        TodoTask::query()->create([
            'user_id' => $this->user->id,
            'project_id' => $project->id,
            'title' => 'Finished daily',
            'task_type' => TodoTask::TYPE_DAILY,
            'status' => TodoTask::STATUS_FINISHED,
            'priority' => TodoTask::PRIORITY_HIGH,
            'points' => 30,
            'completed_at' => now(),
            'sort_order' => 1,
        ]);

        TodoTask::query()->create([
            'user_id' => $this->user->id,
            'project_id' => $project->id,
            'title' => 'Pending weekly',
            'task_type' => TodoTask::TYPE_WEEKLY,
            'status' => TodoTask::STATUS_PENDING,
            'priority' => TodoTask::PRIORITY_MEDIUM,
            'points' => 50,
            'sort_order' => 1,
        ]);

        TodoTask::query()->create([
            'user_id' => $this->user->id,
            'title' => 'In progress monthly',
            'task_type' => TodoTask::TYPE_MONTHLY,
            'status' => TodoTask::STATUS_IN_PROGRESS,
            'priority' => TodoTask::PRIORITY_LOW,
            'points' => 100,
            'sort_order' => 1,
        ]);

        $this->getJson('/api/v1/todo/dashboard')
            ->assertOk()
            ->assertJsonPath('data.total_tasks', 3)
            ->assertJsonPath('data.finished_tasks', 1)
            ->assertJsonPath('data.pending_tasks', 1)
            ->assertJsonPath('data.in_progress_tasks', 1)
            ->assertJsonPath('data.completion_percentage', 33.33)
            ->assertJsonPath('data.total_points', 30)
            ->assertJsonPath('data.daily_points', 30)
            ->assertJsonPath('data.weekly_points', 0)
            ->assertJsonPath('data.daily_tasks', 1)
            ->assertJsonPath('data.weekly_tasks', 1)
            ->assertJsonPath('data.monthly_tasks', 1)
            ->assertJsonPath('data.active_projects', 1)
            ->assertJsonPath('data.project_progress_summary.0.total_tasks', 2)
            ->assertJsonPath('data.project_progress_summary.0.finished_tasks', 1)
            ->assertJsonPath('data.project_progress_summary.0.completion_percentage', 50)
            ->assertJsonPath('data.project_progress_summary.0.project_points', 30);
    }

    public function test_project_endpoint_calculates_finished_points_only(): void
    {
        $project = TodoProject::query()->create([
            'user_id' => $this->user->id,
            'name' => 'Points Project',
            'status' => TodoProject::STATUS_ACTIVE,
        ]);

        foreach ([
            [TodoTask::STATUS_FINISHED, 25],
            [TodoTask::STATUS_PENDING, 75],
        ] as $index => [$status, $points]) {
            TodoTask::query()->create([
                'user_id' => $this->user->id,
                'project_id' => $project->id,
                'title' => "Task {$index}",
                'task_type' => TodoTask::TYPE_GENERAL,
                'status' => $status,
                'priority' => TodoTask::PRIORITY_MEDIUM,
                'points' => $points,
                'completed_at' => $status === TodoTask::STATUS_FINISHED ? now() : null,
                'sort_order' => $index + 1,
            ]);
        }

        $this->getJson("/api/v1/todo/projects/{$project->id}")
            ->assertOk()
            ->assertJsonPath('data.total_tasks', 2)
            ->assertJsonPath('data.finished_tasks', 1)
            ->assertJsonPath('data.completion_percentage', 50)
            ->assertJsonPath('data.total_project_points', 25);
    }

    public function test_user_cannot_access_or_modify_another_users_records(): void
    {
        $other = User::factory()->create();

        $project = TodoProject::query()->create([
            'user_id' => $other->id,
            'name' => 'Private project',
            'status' => TodoProject::STATUS_ACTIVE,
        ]);

        $task = TodoTask::query()->create([
            'user_id' => $other->id,
            'project_id' => $project->id,
            'title' => 'Private task',
            'task_type' => TodoTask::TYPE_GENERAL,
            'status' => TodoTask::STATUS_PENDING,
            'priority' => TodoTask::PRIORITY_MEDIUM,
            'points' => 10,
            'sort_order' => 1,
        ]);

        $this->getJson("/api/v1/todo/projects/{$project->id}")->assertNotFound();
        $this->patchJson("/api/v1/todo/projects/{$project->id}", ['name' => 'Hacked'])->assertNotFound();
        $this->deleteJson("/api/v1/todo/projects/{$project->id}")->assertNotFound();

        $this->getJson("/api/v1/todo/tasks/{$task->id}")->assertNotFound();
        $this->patchJson("/api/v1/todo/tasks/{$task->id}/status", [
            'status' => TodoTask::STATUS_FINISHED,
        ])->assertNotFound();
        $this->deleteJson("/api/v1/todo/tasks/{$task->id}")->assertNotFound();

        $this->assertDatabaseHas('todo_projects', ['id' => $project->id, 'name' => 'Private project']);
        $this->assertDatabaseHas('todo_tasks', ['id' => $task->id, 'status' => TodoTask::STATUS_PENDING]);
    }

    public function test_validation_rejects_invalid_project_and_task_payloads(): void
    {
        $this->postJson('/api/v1/todo/projects', [
            'name' => '',
            'status' => 'invalid',
            'start_date' => '2026-07-20',
            'end_date' => '2026-07-10',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'status', 'end_date']);

        $this->postJson('/api/v1/todo/tasks', [
            'title' => '',
            'task_type' => 'yearly',
            'status' => 'done',
            'priority' => 'urgent',
            'points' => -1,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['title', 'task_type', 'status', 'priority', 'points']);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        app('auth')->forgetGuards();

        $this->getJson('/api/v1/todo/dashboard')->assertUnauthorized();
        $this->getJson('/api/v1/todo/projects')->assertUnauthorized();
        $this->getJson('/api/v1/todo/tasks')->assertUnauthorized();
    }
}
