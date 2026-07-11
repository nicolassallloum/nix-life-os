Below is STEP 13 — Project System Backend for NIX LIFE OS.
This module includes:


Projects table


Project steps/tasks system


Status tracking


CRUD APIs


Laravel Models


Resources


Controllers


Routes


Curl testing commands



🔹 STEP 13 — Project System Backend
1. Create Files
Run these commands from:
cd /u01/nix-life-os/backend
php artisan make:model Project -mphp artisan make:model ProjectTask -mphp artisan make:controller Api/V1/ProjectController --apiphp artisan make:controller Api/V1/ProjectTaskController --apiphp artisan make:resource ProjectResourcephp artisan make:resource ProjectTaskResource

2. Migration — projects Table
Open the generated project migration:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_projects_table.php
Replace it with:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('projects', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->string('project_name');            $table->string('project_code')->nullable();            $table->text('description')->nullable();            $table->string('status')->default('not_started');            /*                not_started                in_progress                on_hold                completed                cancelled            */            $table->string('priority')->default('medium');            /*                low                medium                high                critical            */            $table->date('start_date')->nullable();            $table->date('target_end_date')->nullable();            $table->date('actual_end_date')->nullable();            $table->decimal('progress_percentage', 5, 2)->default(0);            $table->jsonb('metadata')->nullable();            $table->timestamps();            $table->foreign('user_id')                ->references('id')                ->on('users')                ->cascadeOnDelete();            $table->index(['user_id', 'status']);            $table->index(['user_id', 'priority']);            $table->index(['start_date']);            $table->index(['target_end_date']);        });    }    public function down(): void    {        Schema::dropIfExists('projects');    }};

3. Migration — project_tasks Table
Open the generated migration:
nano database/migrations/xxxx_xx_xx_xxxxxx_create_project_tasks_table.php
Replace it with:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('project_tasks', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('project_id');            $table->uuid('user_id');            $table->string('task_title');            $table->text('task_description')->nullable();            $table->string('status')->default('todo');            /*                todo                in_progress                blocked                completed                cancelled            */            $table->string('priority')->default('medium');            /*                low                medium                high                critical            */            $table->integer('task_order')->default(1);            $table->date('start_date')->nullable();            $table->date('due_date')->nullable();            $table->date('completed_date')->nullable();            $table->decimal('progress_percentage', 5, 2)->default(0);            $table->jsonb('metadata')->nullable();            $table->timestamps();            $table->foreign('project_id')                ->references('id')                ->on('projects')                ->cascadeOnDelete();            $table->foreign('user_id')                ->references('id')                ->on('users')                ->cascadeOnDelete();            $table->index(['project_id', 'status']);            $table->index(['user_id', 'status']);            $table->index(['due_date']);            $table->index(['priority']);        });    }    public function down(): void    {        Schema::dropIfExists('project_tasks');    }};

4. Model — Project.php
Open:
nano app/Models/Project.php
Replace with:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Concerns\HasUuids;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Factories\HasFactory;class Project extends Model{    use HasFactory, HasUuids;    protected $fillable = [        'user_id',        'project_name',        'project_code',        'description',        'status',        'priority',        'start_date',        'target_end_date',        'actual_end_date',        'progress_percentage',        'metadata',    ];    protected $casts = [        'start_date' => 'date',        'target_end_date' => 'date',        'actual_end_date' => 'date',        'progress_percentage' => 'decimal:2',        'metadata' => 'array',    ];    public function tasks()    {        return $this->hasMany(ProjectTask::class);    }    public function user()    {        return $this->belongsTo(User::class);    }}

5. Model — ProjectTask.php
Open:
nano app/Models/ProjectTask.php
Replace with:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Concerns\HasUuids;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Factories\HasFactory;class ProjectTask extends Model{    use HasFactory, HasUuids;    protected $fillable = [        'project_id',        'user_id',        'task_title',        'task_description',        'status',        'priority',        'task_order',        'start_date',        'due_date',        'completed_date',        'progress_percentage',        'metadata',    ];    protected $casts = [        'start_date' => 'date',        'due_date' => 'date',        'completed_date' => 'date',        'progress_percentage' => 'decimal:2',        'metadata' => 'array',    ];    public function project()    {        return $this->belongsTo(Project::class);    }    public function user()    {        return $this->belongsTo(User::class);    }}

6. Resource — ProjectResource.php
Open:
nano app/Http/Resources/ProjectResource.php
Replace with:
<?phpnamespace App\Http\Resources;use Illuminate\Http\Request;use Illuminate\Http\Resources\Json\JsonResource;class ProjectResource extends JsonResource{    public function toArray(Request $request): array    {        return [            'id' => $this->id,            'user_id' => $this->user_id,            'project_name' => $this->project_name,            'project_code' => $this->project_code,            'description' => $this->description,            'status' => $this->status,            'priority' => $this->priority,            'start_date' => optional($this->start_date)->format('Y-m-d'),            'target_end_date' => optional($this->target_end_date)->format('Y-m-d'),            'actual_end_date' => optional($this->actual_end_date)->format('Y-m-d'),            'progress_percentage' => $this->progress_percentage,            'metadata' => $this->metadata,            'tasks_count' => $this->whenCounted('tasks'),            'tasks' => ProjectTaskResource::collection($this->whenLoaded('tasks')),            'created_at' => optional($this->created_at)->format('Y-m-d H:i:s'),            'updated_at' => optional($this->updated_at)->format('Y-m-d H:i:s'),        ];    }}

7. Resource — ProjectTaskResource.php
Open:
nano app/Http/Resources/ProjectTaskResource.php
Replace with:
<?phpnamespace App\Http\Resources;use Illuminate\Http\Request;use Illuminate\Http\Resources\Json\JsonResource;class ProjectTaskResource extends JsonResource{    public function toArray(Request $request): array    {        return [            'id' => $this->id,            'project_id' => $this->project_id,            'user_id' => $this->user_id,            'task_title' => $this->task_title,            'task_description' => $this->task_description,            'status' => $this->status,            'priority' => $this->priority,            'task_order' => $this->task_order,            'start_date' => optional($this->start_date)->format('Y-m-d'),            'due_date' => optional($this->due_date)->format('Y-m-d'),            'completed_date' => optional($this->completed_date)->format('Y-m-d'),            'progress_percentage' => $this->progress_percentage,            'metadata' => $this->metadata,            'created_at' => optional($this->created_at)->format('Y-m-d H:i:s'),            'updated_at' => optional($this->updated_at)->format('Y-m-d H:i:s'),        ];    }}

8. Controller — ProjectController.php
Open:
nano app/Http/Controllers/Api/V1/ProjectController.php
Replace with:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Http\Resources\ProjectResource;use App\Models\Project;use Illuminate\Http\Request;use Illuminate\Validation\Rule;class ProjectController extends Controller{    public function index(Request $request)    {        $projects = Project::query()            ->where('user_id', $request->user()->id)            ->withCount('tasks')            ->when($request->status, fn ($query) => $query->where('status', $request->status))            ->when($request->priority, fn ($query) => $query->where('priority', $request->priority))            ->latest()            ->paginate($request->get('per_page', 15));        return ProjectResource::collection($projects);    }    public function store(Request $request)    {        $validated = $request->validate([            'project_name' => ['required', 'string', 'max:255'],            'project_code' => ['nullable', 'string', 'max:100'],            'description' => ['nullable', 'string'],            'status' => [                'nullable',                Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled']),            ],            'priority' => [                'nullable',                Rule::in(['low', 'medium', 'high', 'critical']),            ],            'start_date' => ['nullable', 'date'],            'target_end_date' => ['nullable', 'date'],            'actual_end_date' => ['nullable', 'date'],            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],            'metadata' => ['nullable', 'array'],        ]);        $validated['user_id'] = $request->user()->id;        $validated['status'] = $validated['status'] ?? 'not_started';        $validated['priority'] = $validated['priority'] ?? 'medium';        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;        $project = Project::create($validated);        return response()->json([            'success' => true,            'message' => 'Project created successfully.',            'data' => new ProjectResource($project),        ], 201);    }    public function show(Request $request, Project $project)    {        $this->authorizeProject($request, $project);        $project->load(['tasks' => function ($query) {            $query->orderBy('task_order')->orderBy('created_at');        }]);        return response()->json([            'success' => true,            'data' => new ProjectResource($project),        ]);    }    public function update(Request $request, Project $project)    {        $this->authorizeProject($request, $project);        $validated = $request->validate([            'project_name' => ['sometimes', 'required', 'string', 'max:255'],            'project_code' => ['nullable', 'string', 'max:100'],            'description' => ['nullable', 'string'],            'status' => [                'sometimes',                Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled']),            ],            'priority' => [                'sometimes',                Rule::in(['low', 'medium', 'high', 'critical']),            ],            'start_date' => ['nullable', 'date'],            'target_end_date' => ['nullable', 'date'],            'actual_end_date' => ['nullable', 'date'],            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],            'metadata' => ['nullable', 'array'],        ]);        if (($validated['status'] ?? null) === 'completed') {            $validated['progress_percentage'] = 100;            $validated['actual_end_date'] = $validated['actual_end_date'] ?? now()->toDateString();        }        $project->update($validated);        return response()->json([            'success' => true,            'message' => 'Project updated successfully.',            'data' => new ProjectResource($project->fresh()),        ]);    }    public function destroy(Request $request, Project $project)    {        $this->authorizeProject($request, $project);        $project->delete();        return response()->json([            'success' => true,            'message' => 'Project deleted successfully.',        ]);    }    private function authorizeProject(Request $request, Project $project): void    {        abort_if($project->user_id !== $request->user()->id, 403, 'Unauthorized project access.');    }}

9. Controller — ProjectTaskController.php
Open:
nano app/Http/Controllers/Api/V1/ProjectTaskController.php
Replace with:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Http\Resources\ProjectTaskResource;use App\Models\Project;use App\Models\ProjectTask;use Illuminate\Http\Request;use Illuminate\Validation\Rule;class ProjectTaskController extends Controller{    public function index(Request $request)    {        $tasks = ProjectTask::query()            ->where('user_id', $request->user()->id)            ->when($request->project_id, fn ($query) => $query->where('project_id', $request->project_id))            ->when($request->status, fn ($query) => $query->where('status', $request->status))            ->when($request->priority, fn ($query) => $query->where('priority', $request->priority))            ->orderBy('task_order')            ->latest()            ->paginate($request->get('per_page', 15));        return ProjectTaskResource::collection($tasks);    }    public function store(Request $request)    {        $validated = $request->validate([            'project_id' => ['required', 'uuid', 'exists:projects,id'],            'task_title' => ['required', 'string', 'max:255'],            'task_description' => ['nullable', 'string'],            'status' => [                'nullable',                Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled']),            ],            'priority' => [                'nullable',                Rule::in(['low', 'medium', 'high', 'critical']),            ],            'task_order' => ['nullable', 'integer', 'min:1'],            'start_date' => ['nullable', 'date'],            'due_date' => ['nullable', 'date'],            'completed_date' => ['nullable', 'date'],            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],            'metadata' => ['nullable', 'array'],        ]);        $project = Project::where('id', $validated['project_id'])            ->where('user_id', $request->user()->id)            ->firstOrFail();        $validated['user_id'] = $request->user()->id;        $validated['status'] = $validated['status'] ?? 'todo';        $validated['priority'] = $validated['priority'] ?? 'medium';        $validated['task_order'] = $validated['task_order'] ?? 1;        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;        $task = ProjectTask::create($validated);        $this->refreshProjectProgress($project);        return response()->json([            'success' => true,            'message' => 'Project task created successfully.',            'data' => new ProjectTaskResource($task),        ], 201);    }    public function show(Request $request, ProjectTask $projectTask)    {        $this->authorizeTask($request, $projectTask);        return response()->json([            'success' => true,            'data' => new ProjectTaskResource($projectTask),        ]);    }    public function update(Request $request, ProjectTask $projectTask)    {        $this->authorizeTask($request, $projectTask);        $validated = $request->validate([            'task_title' => ['sometimes', 'required', 'string', 'max:255'],            'task_description' => ['nullable', 'string'],            'status' => [                'sometimes',                Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled']),            ],            'priority' => [                'sometimes',                Rule::in(['low', 'medium', 'high', 'critical']),            ],            'task_order' => ['nullable', 'integer', 'min:1'],            'start_date' => ['nullable', 'date'],            'due_date' => ['nullable', 'date'],            'completed_date' => ['nullable', 'date'],            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],            'metadata' => ['nullable', 'array'],        ]);        if (($validated['status'] ?? null) === 'completed') {            $validated['progress_percentage'] = 100;            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();        }        $projectTask->update($validated);        $this->refreshProjectProgress($projectTask->project);        return response()->json([            'success' => true,            'message' => 'Project task updated successfully.',            'data' => new ProjectTaskResource($projectTask->fresh()),        ]);    }    public function destroy(Request $request, ProjectTask $projectTask)    {        $this->authorizeTask($request, $projectTask);        $project = $projectTask->project;        $projectTask->delete();        $this->refreshProjectProgress($project);        return response()->json([            'success' => true,            'message' => 'Project task deleted successfully.',        ]);    }    private function authorizeTask(Request $request, ProjectTask $projectTask): void    {        abort_if($projectTask->user_id !== $request->user()->id, 403, 'Unauthorized task access.');    }    private function refreshProjectProgress(Project $project): void    {        $tasks = $project->tasks()->get();        if ($tasks->count() === 0) {            $project->update([                'progress_percentage' => 0,                'status' => 'not_started',            ]);            return;        }        $avgProgress = round($tasks->avg('progress_percentage'), 2);        $completedTasks = $tasks->where('status', 'completed')->count();        if ($completedTasks === $tasks->count()) {            $status = 'completed';            $actualEndDate = $project->actual_end_date ?? now()->toDateString();        } elseif ($tasks->where('status', 'in_progress')->count() > 0) {            $status = 'in_progress';            $actualEndDate = $project->actual_end_date;        } elseif ($tasks->where('status', 'blocked')->count() > 0) {            $status = 'on_hold';            $actualEndDate = $project->actual_end_date;        } else {            $status = 'not_started';            $actualEndDate = $project->actual_end_date;        }        $project->update([            'progress_percentage' => $avgProgress,            'status' => $status,            'actual_end_date' => $actualEndDate,        ]);    }}

10. Add Routes — api.php
Open:
nano routes/api.php
Add these imports at the top:
use App\Http\Controllers\Api\V1\ProjectController;use App\Http\Controllers\Api\V1\ProjectTaskController;
Inside your protected Sanctum group:
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {    Route::apiResource('projects', ProjectController::class);    Route::apiResource('project-tasks', ProjectTaskController::class);});
If your file already has:
Route::prefix('v1')->group(function () {
Then put the project routes only inside the existing protected section.

11. Run Migration
php artisan migrate
If you want to check only these migrations first:
php artisan migrate:status

12. Clear Cache
php artisan optimize:clearcomposer dump-autoload

13. Test API — Create Project
Use your token:
TOKEN="REDACTED_TOKEN"
  Task_id : 019dc843-f8bc-7379-ae64-2711d9ea44e0
  Project_id =019dc843-0add-73c8-bede-07761feba805

Create project:
curl -X POST http://127.0.0.1:8000/api/v1/projects \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "project_name": "NIX LIFE OS",    "project_code": "NIX-OS",    "description": "Personal operating system including finance, health, projects, and AI modules.",    "status": "in_progress",    "priority": "critical",    "start_date": "2026-04-26",    "target_end_date": "2026-12-31",    "progress_percentage": 0,    "metadata": {      "module": "Projects",      "phase": "Step 13"    }  }'
Expected response:
{  "success": true,  "message": "Project created successfully.",  "data": {    "id": "...",    "project_name": "NIX LIFE OS",    "status": "in_progress"  }}
Copy the returned project id.

14. List Projects
curl http://127.0.0.1:8000/api/v1/projects \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Filter by status:
curl "http://127.0.0.1:8000/api/v1/projects?status=in_progress" \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

15. Create Task / Step
Replace PROJECT_ID_HERE with your project ID.
curl -X POST http://127.0.0.1:8000/api/v1/project-tasks \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "project_id": "PROJECT_ID_HERE",    "task_title": "Build Project System Backend",    "task_description": "Create projects table, tasks table, status tracking, and CRUD APIs.",    "status": "in_progress",    "priority": "high",    "task_order": 1,    "start_date": "2026-04-26",    "due_date": "2026-04-27",    "progress_percentage": 40,    "metadata": {      "step": 13,      "module": "Projects Backend"    }  }'

16. List Tasks
curl http://127.0.0.1:8000/api/v1/project-tasks \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Filter by project:
curl "http://127.0.0.1:8000/api/v1/project-tasks?project_id=PROJECT_ID_HERE" \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

17. Update Task Status
Replace TASK_ID_HERE.
curl -X PUT http://127.0.0.1:8000/api/v1/project-tasks/TASK_ID_HERE \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "status": "completed",    "progress_percentage": 100  }'
This will automatically:


Mark the task as completed


Set completed_date


Recalculate project progress


Update project status if all tasks are completed



18. Show Project With Tasks
curl http://127.0.0.1:8000/api/v1/projects/PROJECT_ID_HERE \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

19. Update Project
curl -X PUT http://127.0.0.1:8000/api/v1/projects/PROJECT_ID_HERE \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "project_name": "NIX LIFE OS - Intelligent Personal Operating System",    "priority": "critical",    "status": "in_progress",    "progress_percentage": 25  }'

20. Delete Task
curl -X DELETE http://127.0.0.1:8000/api/v1/project-tasks/TASK_ID_HERE \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

21. Delete Project
curl -X DELETE http://127.0.0.1:8000/api/v1/projects/PROJECT_ID_HERE \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"
Deleting a project will also delete its tasks because of:
->cascadeOnDelete()

22. API Endpoints Summary
Projects
MethodEndpointPurposeGET/api/v1/projectsList projectsPOST/api/v1/projectsCreate projectGET/api/v1/projects/{id}Show project with tasksPUT/PATCH/api/v1/projects/{id}Update projectDELETE/api/v1/projects/{id}Delete project
Project Tasks
MethodEndpointPurposeGET/api/v1/project-tasksList tasksPOST/api/v1/project-tasksCreate taskGET/api/v1/project-tasks/{id}Show taskPUT/PATCH/api/v1/project-tasks/{id}Update taskDELETE/api/v1/project-tasks/{id}Delete task

23. Status Values
Project Status
not_startedin_progresson_holdcompletedcancelled
Task Status
todoin_progressblockedcompletedcancelled
Priority Values
lowmediumhighcritical

24. Important Check
After adding everything, run:
php artisan route:list | grep project
You should see routes like:
GET|HEAD   api/v1/projectsPOST       api/v1/projectsGET|HEAD   api/v1/projects/{project}PUT|PATCH  api/v1/projects/{project}DELETE     api/v1/projects/{project}GET|HEAD   api/v1/project-tasksPOST       api/v1/project-tasksGET|HEAD   api/v1/project-tasks/{project_task}PUT|PATCH  api/v1/project-tasks/{project_task}DELETE     api/v1/project-tasks/{project_task}

25. If Route Model Binding Fails
If this route does not work:
/api/v1/project-tasks/{id}
because Laravel expects {project_task}, keep the route as generated by apiResource.
The controller variable is correct:
ProjectTask $projectTask
Laravel automatically maps:
project-tasks/{project_task}
to:
ProjectTask $projectTask

26. Step 13 Completion Checklist
You can consider STEP 13 complete when:
php artisan migrate
passes successfully.
php artisan route:list | grep project
shows all project routes.
You can successfully run:
POST /api/v1/projectsGET /api/v1/projectsPOST /api/v1/project-tasksGET /api/v1/projects/{id}PUT /api/v1/project-tasks/{id}
And the project progress updates automatically when task progress/status changes.