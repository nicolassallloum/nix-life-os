🔹 STEP 21 — Notification System
NIX LIFE OS — Reminders + Alerts Backend + UI
In this step, we will build a full notification system for:


Meal reminders


Weight check reminders


Expense reminders


Finance alerts


Health alerts


Life Balance alerts


Read / unread notifications


Notification dashboard UI



1. What We Will Build
Backend
We will create:
notifications tablenotification_preferences tableNotificationControllerNotificationPreferenceControllerNotificationServiceScheduled notification commandsAPI routes
Frontend
We will create:
NotificationsView.vueNotificationBell.vueNotificationSettingsView.vue

2. Backend Database Design
2.1 Create Notifications Migration
Run:
cd /u01/nix-life-os/backendphp artisan make:migration create_life_notifications_table
Open the generated migration file and replace it with:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('life_notifications', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->string('notification_type', 80);            /*                meal_reminder                weight_reminder                expense_reminder                finance_alert                health_alert                productivity_alert                life_balance_alert                system_alert            */            $table->string('title', 255);            $table->text('message');            $table->string('severity', 30)->default('info');            /*                info                success                warning                danger            */            $table->string('source_module', 80)->nullable();            /*                finance                health                productivity                projects                life_balance                ai            */            $table->jsonb('metadata')->nullable();            $table->boolean('is_read')->default(false);            $table->timestamp('read_at')->nullable();            $table->timestamp('scheduled_for')->nullable();            $table->timestamp('triggered_at')->nullable();            $table->timestamps();            $table->index('user_id');            $table->index('notification_type');            $table->index('severity');            $table->index('is_read');            $table->index('scheduled_for');            $table->index(['user_id', 'is_read']);        });    }    public function down(): void    {        Schema::dropIfExists('life_notifications');    }};

2.2 Create Notification Preferences Migration
Run:
php artisan make:migration create_notification_preferences_table
Replace the file with:
<?phpuse Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;return new class extends Migration{    public function up(): void    {        Schema::create('notification_preferences', function (Blueprint $table) {            $table->uuid('id')->primary();            $table->uuid('user_id');            $table->boolean('meal_reminders_enabled')->default(true);            $table->time('breakfast_time')->nullable();            $table->time('lunch_time')->nullable();            $table->time('dinner_time')->nullable();            $table->boolean('weight_reminders_enabled')->default(true);            $table->time('weight_reminder_time')->nullable();            $table->boolean('expense_reminders_enabled')->default(true);            $table->time('expense_reminder_time')->nullable();            $table->boolean('finance_alerts_enabled')->default(true);            $table->boolean('health_alerts_enabled')->default(true);            $table->boolean('life_balance_alerts_enabled')->default(true);            $table->integer('daily_expense_warning_limit')->nullable();            $table->integer('life_balance_warning_score')->default(60);            $table->jsonb('metadata')->nullable();            $table->timestamps();            $table->unique('user_id');            $table->index('user_id');        });    }    public function down(): void    {        Schema::dropIfExists('notification_preferences');    }};

2.3 Run Migration
php artisan migrate

3. Backend Models
3.1 Create LifeNotification Model
Run:
php artisan make:model LifeNotification
Open:
app/Models/LifeNotification.php
Replace with:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Concerns\HasUuids;class LifeNotification extends Model{    use HasUuids;    protected $table = 'life_notifications';    protected $fillable = [        'user_id',        'notification_type',        'title',        'message',        'severity',        'source_module',        'metadata',        'is_read',        'read_at',        'scheduled_for',        'triggered_at',    ];    protected $casts = [        'metadata' => 'array',        'is_read' => 'boolean',        'read_at' => 'datetime',        'scheduled_for' => 'datetime',        'triggered_at' => 'datetime',    ];}

3.2 Create NotificationPreference Model
Run:
php artisan make:model NotificationPreference
Open:
app/Models/NotificationPreference.php
Replace with:
<?phpnamespace App\Models;use Illuminate\Database\Eloquent\Model;use Illuminate\Database\Eloquent\Concerns\HasUuids;class NotificationPreference extends Model{    use HasUuids;    protected $table = 'notification_preferences';    protected $fillable = [        'user_id',        'meal_reminders_enabled',        'breakfast_time',        'lunch_time',        'dinner_time',        'weight_reminders_enabled',        'weight_reminder_time',        'expense_reminders_enabled',        'expense_reminder_time',        'finance_alerts_enabled',        'health_alerts_enabled',        'life_balance_alerts_enabled',        'daily_expense_warning_limit',        'life_balance_warning_score',        'metadata',    ];    protected $casts = [        'meal_reminders_enabled' => 'boolean',        'weight_reminders_enabled' => 'boolean',        'expense_reminders_enabled' => 'boolean',        'finance_alerts_enabled' => 'boolean',        'health_alerts_enabled' => 'boolean',        'life_balance_alerts_enabled' => 'boolean',        'metadata' => 'array',    ];}

4. Notification Service
Create service folder if it does not exist:
mkdir -p app/Services
Create file:
nano app/Services/NotificationService.php
Add:
<?phpnamespace App\Services;use App\Models\LifeNotification;use App\Models\NotificationPreference;use Carbon\Carbon;class NotificationService{    public function createNotification(        string $userId,        string $type,        string $title,        string $message,        string $severity = 'info',        ?string $sourceModule = null,        ?array $metadata = null,        ?Carbon $scheduledFor = null    ): LifeNotification {        return LifeNotification::create([            'user_id' => $userId,            'notification_type' => $type,            'title' => $title,            'message' => $message,            'severity' => $severity,            'source_module' => $sourceModule,            'metadata' => $metadata,            'scheduled_for' => $scheduledFor,            'triggered_at' => now(),        ]);    }    public function getOrCreatePreferences(string $userId): NotificationPreference    {        return NotificationPreference::firstOrCreate(            ['user_id' => $userId],            [                'meal_reminders_enabled' => true,                'breakfast_time' => '08:00',                'lunch_time' => '13:00',                'dinner_time' => '19:00',                'weight_reminders_enabled' => true,                'weight_reminder_time' => '08:30',                'expense_reminders_enabled' => true,                'expense_reminder_time' => '21:00',                'finance_alerts_enabled' => true,                'health_alerts_enabled' => true,                'life_balance_alerts_enabled' => true,                'daily_expense_warning_limit' => 50,                'life_balance_warning_score' => 60,            ]        );    }    public function markAsRead(string $notificationId, string $userId): ?LifeNotification    {        $notification = LifeNotification::where('id', $notificationId)            ->where('user_id', $userId)            ->first();        if (!$notification) {            return null;        }        $notification->update([            'is_read' => true,            'read_at' => now(),        ]);        return $notification;    }    public function markAllAsRead(string $userId): int    {        return LifeNotification::where('user_id', $userId)            ->where('is_read', false)            ->update([                'is_read' => true,                'read_at' => now(),            ]);    }    public function unreadCount(string $userId): int    {        return LifeNotification::where('user_id', $userId)            ->where('is_read', false)            ->count();    }}

5. Backend Controllers
5.1 Create NotificationController
Run:
php artisan make:controller Api/V1/NotificationController
Open:
app/Http/Controllers/Api/V1/NotificationController.php
Replace with:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Models\LifeNotification;use App\Services\NotificationService;use Illuminate\Http\Request;class NotificationController extends Controller{    public function index(Request $request)    {        $userId = $request->user()->id;        $query = LifeNotification::where('user_id', $userId)            ->orderBy('created_at', 'desc');        if ($request->filled('is_read')) {            $query->where('is_read', filter_var($request->is_read, FILTER_VALIDATE_BOOLEAN));        }        if ($request->filled('type')) {            $query->where('notification_type', $request->type);        }        if ($request->filled('severity')) {            $query->where('severity', $request->severity);        }        return response()->json([            'success' => true,            'data' => $query->paginate(20),        ]);    }    public function unreadCount(Request $request, NotificationService $service)    {        return response()->json([            'success' => true,            'data' => [                'unread_count' => $service->unreadCount($request->user()->id),            ],        ]);    }    public function show(Request $request, string $id)    {        $notification = LifeNotification::where('id', $id)            ->where('user_id', $request->user()->id)            ->firstOrFail();        return response()->json([            'success' => true,            'data' => $notification,        ]);    }    public function markAsRead(Request $request, string $id, NotificationService $service)    {        $notification = $service->markAsRead($id, $request->user()->id);        if (!$notification) {            return response()->json([                'success' => false,                'message' => 'Notification not found.',            ], 404);        }        return response()->json([            'success' => true,            'message' => 'Notification marked as read.',            'data' => $notification,        ]);    }    public function markAllAsRead(Request $request, NotificationService $service)    {        $updated = $service->markAllAsRead($request->user()->id);        return response()->json([            'success' => true,            'message' => 'All notifications marked as read.',            'data' => [                'updated_count' => $updated,            ],        ]);    }    public function destroy(Request $request, string $id)    {        $notification = LifeNotification::where('id', $id)            ->where('user_id', $request->user()->id)            ->firstOrFail();        $notification->delete();        return response()->json([            'success' => true,            'message' => 'Notification deleted.',        ]);    }}

5.2 Create NotificationPreferenceController
Run:
php artisan make:controller Api/V1/NotificationPreferenceController
Open:
app/Http/Controllers/Api/V1/NotificationPreferenceController.php
Replace with:
<?phpnamespace App\Http\Controllers\Api\V1;use App\Http\Controllers\Controller;use App\Services\NotificationService;use Illuminate\Http\Request;class NotificationPreferenceController extends Controller{    public function show(Request $request, NotificationService $service)    {        $preferences = $service->getOrCreatePreferences($request->user()->id);        return response()->json([            'success' => true,            'data' => $preferences,        ]);    }    public function update(Request $request, NotificationService $service)    {        $preferences = $service->getOrCreatePreferences($request->user()->id);        $validated = $request->validate([            'meal_reminders_enabled' => ['nullable', 'boolean'],            'breakfast_time' => ['nullable', 'date_format:H:i'],            'lunch_time' => ['nullable', 'date_format:H:i'],            'dinner_time' => ['nullable', 'date_format:H:i'],            'weight_reminders_enabled' => ['nullable', 'boolean'],            'weight_reminder_time' => ['nullable', 'date_format:H:i'],            'expense_reminders_enabled' => ['nullable', 'boolean'],            'expense_reminder_time' => ['nullable', 'date_format:H:i'],            'finance_alerts_enabled' => ['nullable', 'boolean'],            'health_alerts_enabled' => ['nullable', 'boolean'],            'life_balance_alerts_enabled' => ['nullable', 'boolean'],            'daily_expense_warning_limit' => ['nullable', 'integer', 'min:1'],            'life_balance_warning_score' => ['nullable', 'integer', 'min:0', 'max:100'],        ]);        $preferences->update($validated);        return response()->json([            'success' => true,            'message' => 'Notification preferences updated.',            'data' => $preferences,        ]);    }}

6. Notification API Routes
Open:
routes/api.php
Add these imports at the top:
use App\Http\Controllers\Api\V1\NotificationController;use App\Http\Controllers\Api\V1\NotificationPreferenceController;
Inside your authenticated API group, add:
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {    Route::get('/notifications', [NotificationController::class, 'index']);    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);    Route::get('/notifications/{id}', [NotificationController::class, 'show']);    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);    Route::get('/notification-preferences', [NotificationPreferenceController::class, 'show']);    Route::put('/notification-preferences', [NotificationPreferenceController::class, 'update']);});
If you already have this:
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
Do not create another duplicate group. Just place the notification routes inside the existing group.

7. Scheduled Notification Commands
Now we create commands that generate reminders and alerts automatically.

7.1 Meal Reminder Command
Run:
php artisan make:command GenerateMealReminders
Open:
app/Console/Commands/GenerateMealReminders.php
Replace with:
<?phpnamespace App\Console\Commands;use App\Models\NotificationPreference;use App\Services\NotificationService;use Carbon\Carbon;use Illuminate\Console\Command;class GenerateMealReminders extends Command{    protected $signature = 'notifications:meal-reminders';    protected $description = 'Generate meal reminder notifications';    public function handle(NotificationService $notificationService): int    {        $now = Carbon::now()->format('H:i');        $preferences = NotificationPreference::where('meal_reminders_enabled', true)->get();        foreach ($preferences as $pref) {            if ($pref->breakfast_time === $now) {                $notificationService->createNotification(                    $pref->user_id,                    'meal_reminder',                    'Breakfast Reminder',                    'Time to log your breakfast meal.',                    'info',                    'health',                    ['meal_type' => 'breakfast']                );            }            if ($pref->lunch_time === $now) {                $notificationService->createNotification(                    $pref->user_id,                    'meal_reminder',                    'Lunch Reminder',                    'Time to log your lunch meal.',                    'info',                    'health',                    ['meal_type' => 'lunch']                );            }            if ($pref->dinner_time === $now) {                $notificationService->createNotification(                    $pref->user_id,                    'meal_reminder',                    'Dinner Reminder',                    'Time to log your dinner meal.',                    'info',                    'health',                    ['meal_type' => 'dinner']                );            }        }        $this->info('Meal reminders generated successfully.');        return self::SUCCESS;    }}

7.2 Weight Reminder Command
Run:
php artisan make:command GenerateWeightReminders
Open:
app/Console/Commands/GenerateWeightReminders.php
Replace with:
<?phpnamespace App\Console\Commands;use App\Models\NotificationPreference;use App\Services\NotificationService;use Carbon\Carbon;use Illuminate\Console\Command;class GenerateWeightReminders extends Command{    protected $signature = 'notifications:weight-reminders';    protected $description = 'Generate weight tracking reminder notifications';    public function handle(NotificationService $notificationService): int    {        $now = Carbon::now()->format('H:i');        $preferences = NotificationPreference::where('weight_reminders_enabled', true)            ->where('weight_reminder_time', $now)            ->get();        foreach ($preferences as $pref) {            $notificationService->createNotification(                $pref->user_id,                'weight_reminder',                'Weight Check Reminder',                'Do not forget to record your weight today.',                'info',                'health'            );        }        $this->info('Weight reminders generated successfully.');        return self::SUCCESS;    }}

7.3 Expense Reminder Command
Run:
php artisan make:command GenerateExpenseReminders
Open:
app/Console/Commands/GenerateExpenseReminders.php
Replace with:
<?phpnamespace App\Console\Commands;use App\Models\NotificationPreference;use App\Services\NotificationService;use Carbon\Carbon;use Illuminate\Console\Command;class GenerateExpenseReminders extends Command{    protected $signature = 'notifications:expense-reminders';    protected $description = 'Generate daily expense reminder notifications';    public function handle(NotificationService $notificationService): int    {        $now = Carbon::now()->format('H:i');        $preferences = NotificationPreference::where('expense_reminders_enabled', true)            ->where('expense_reminder_time', $now)            ->get();        foreach ($preferences as $pref) {            $notificationService->createNotification(                $pref->user_id,                'expense_reminder',                'Expense Reminder',                'Remember to log today’s expenses before the end of the day.',                'info',                'finance'            );        }        $this->info('Expense reminders generated successfully.');        return self::SUCCESS;    }}

8. Finance Alert Command
This command checks whether today’s spending crossed the user’s daily expense warning limit.
Run:
php artisan make:command GenerateFinanceAlerts
Open:
app/Console/Commands/GenerateFinanceAlerts.php
Replace with:
<?phpnamespace App\Console\Commands;use App\Models\NotificationPreference;use App\Services\NotificationService;use Illuminate\Console\Command;use Illuminate\Support\Facades\DB;class GenerateFinanceAlerts extends Command{    protected $signature = 'notifications:finance-alerts';    protected $description = 'Generate finance alert notifications';    public function handle(NotificationService $notificationService): int    {        $preferences = NotificationPreference::where('finance_alerts_enabled', true)->get();        foreach ($preferences as $pref) {            if (!$pref->daily_expense_warning_limit) {                continue;            }            $todayExpenses = DB::table('finance_transactions')                ->where('user_id', $pref->user_id)                ->whereDate('transaction_date', today())                ->where('transaction_type', 'expense')                ->sum('amount');            if ($todayExpenses >= $pref->daily_expense_warning_limit) {                $notificationService->createNotification(                    $pref->user_id,                    'finance_alert',                    'Daily Expense Alert',                    'You spent ' . number_format($todayExpenses, 2) . ' today. This reached your daily warning limit.',                    'warning',                    'finance',                    [                        'today_expenses' => $todayExpenses,                        'limit' => $pref->daily_expense_warning_limit,                    ]                );            }        }        $this->info('Finance alerts generated successfully.');        return self::SUCCESS;    }}
Important: if your finance table name is different, update this line:
DB::table('finance_transactions')
For example, if your table is schema-qualified:
DB::table('nix_life_os.finance_transactions')

9. Life Balance Alert Command
This command checks if the Life Balance score is below the warning threshold.
Run:
php artisan make:command GenerateLifeBalanceAlerts
Open:
app/Console/Commands/GenerateLifeBalanceAlerts.php
Replace with:
<?phpnamespace App\Console\Commands;use App\Models\NotificationPreference;use App\Services\NotificationService;use Illuminate\Console\Command;use Illuminate\Support\Facades\DB;class GenerateLifeBalanceAlerts extends Command{    protected $signature = 'notifications:life-balance-alerts';    protected $description = 'Generate Life Balance score alerts';    public function handle(NotificationService $notificationService): int    {        $preferences = NotificationPreference::where('life_balance_alerts_enabled', true)->get();        foreach ($preferences as $pref) {            $latestScore = DB::table('life_balance_scores')                ->where('user_id', $pref->user_id)                ->orderByDesc('score_date')                ->first();            if (!$latestScore) {                continue;            }            if ($latestScore->overall_score < $pref->life_balance_warning_score) {                $notificationService->createNotification(                    $pref->user_id,                    'life_balance_alert',                    'Life Balance Alert',                    'Your Life Balance score is ' . $latestScore->overall_score . '. Consider reviewing your health, finance, and productivity balance.',                    'warning',                    'life_balance',                    [                        'overall_score' => $latestScore->overall_score,                        'warning_score' => $pref->life_balance_warning_score,                    ]                );            }        }        $this->info('Life Balance alerts generated successfully.');        return self::SUCCESS;    }}
If your Step 20 table has a different name, update:
DB::table('life_balance_scores')
And if your score column has a different name, update:
$latestScore->overall_score

10. Register Commands in Laravel Scheduler
Open:
app/Console/Kernel.php
Inside:
protected function schedule(Schedule $schedule): void
Add:
$schedule->command('notifications:meal-reminders')->everyMinute();$schedule->command('notifications:weight-reminders')->everyMinute();$schedule->command('notifications:expense-reminders')->everyMinute();$schedule->command('notifications:finance-alerts')->dailyAt('21:30');$schedule->command('notifications:life-balance-alerts')->dailyAt('22:00');
Full example:
protected function schedule(Schedule $schedule): void{    $schedule->command('notifications:meal-reminders')->everyMinute();    $schedule->command('notifications:weight-reminders')->everyMinute();    $schedule->command('notifications:expense-reminders')->everyMinute();    $schedule->command('notifications:finance-alerts')->dailyAt('21:30');    $schedule->command('notifications:life-balance-alerts')->dailyAt('22:00');    $schedule->command('ai:daily-insights')->dailyAt('23:55');    $schedule->command('ai:weekly-report')->weeklyOn(0, '23:30');}
Then check:
php artisan schedule:list
You should see:
notifications:meal-remindersnotifications:weight-remindersnotifications:expense-remindersnotifications:finance-alertsnotifications:life-balance-alerts

11. Test Backend APIs
Use your token:
TOKEN="YOUR_TOKEN_HERE"
11.1 Get Preferences
curl http://127.0.0.1:8000/api/v1/notification-preferences \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

11.2 Update Preferences
curl -X PUT http://127.0.0.1:8000/api/v1/notification-preferences \  -H "Accept: application/json" \  -H "Content-Type: application/json" \  -H "Authorization: Bearer $TOKEN" \  -d '{    "meal_reminders_enabled": true,    "breakfast_time": "08:00",    "lunch_time": "13:00",    "dinner_time": "19:00",    "weight_reminders_enabled": true,    "weight_reminder_time": "08:30",    "expense_reminders_enabled": true,    "expense_reminder_time": "21:00",    "finance_alerts_enabled": true,    "health_alerts_enabled": true,    "life_balance_alerts_enabled": true,    "daily_expense_warning_limit": 50,    "life_balance_warning_score": 60  }'

11.3 Get Notifications
curl http://127.0.0.1:8000/api/v1/notifications \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

11.4 Get Unread Count
curl http://127.0.0.1:8000/api/v1/notifications/unread-count \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

11.5 Run Reminder Commands Manually
php artisan notifications:meal-remindersphp artisan notifications:weight-remindersphp artisan notifications:expense-remindersphp artisan notifications:finance-alertsphp artisan notifications:life-balance-alerts

12. Frontend API File
Create:
cd /u01/nix-life-os/frontendmkdir -p src/apinano src/api/notifications.js
Add:
import axios from "axios";const API_BASE_URL = "http://127.0.0.1:8000/api/v1";function authHeaders() {  const token = localStorage.getItem("token");  return {    Accept: "application/json",    Authorization: `Bearer ${token}`,  };}export async function getNotifications(params = {}) {  const response = await axios.get(`${API_BASE_URL}/notifications`, {    headers: authHeaders(),    params,  });  return response.data;}export async function getUnreadNotificationCount() {  const response = await axios.get(`${API_BASE_URL}/notifications/unread-count`, {    headers: authHeaders(),  });  return response.data;}export async function markNotificationAsRead(id) {  const response = await axios.patch(    `${API_BASE_URL}/notifications/${id}/read`,    {},    {      headers: authHeaders(),    }  );  return response.data;}export async function markAllNotificationsAsRead() {  const response = await axios.patch(    `${API_BASE_URL}/notifications/read-all`,    {},    {      headers: authHeaders(),    }  );  return response.data;}export async function deleteNotification(id) {  const response = await axios.delete(`${API_BASE_URL}/notifications/${id}`, {    headers: authHeaders(),  });  return response.data;}export async function getNotificationPreferences() {  const response = await axios.get(`${API_BASE_URL}/notification-preferences`, {    headers: authHeaders(),  });  return response.data;}export async function updateNotificationPreferences(payload) {  const response = await axios.put(    `${API_BASE_URL}/notification-preferences`,    payload,    {      headers: {        ...authHeaders(),        "Content-Type": "application/json",      },    }  );  return response.data;}

13. Notifications Page
Create:
mkdir -p src/views/notificationsnano src/views/notifications/NotificationsView.vue
Add:
<script setup>import { onMounted, ref } from "vue";import {  getNotifications,  markNotificationAsRead,  markAllNotificationsAsRead,  deleteNotification,} from "../../api/notifications";const notifications = ref([]);const loading = ref(false);const selectedFilter = ref("all");const loadNotifications = async () => {  loading.value = true;  try {    const params = {};    if (selectedFilter.value === "unread") {      params.is_read = false;    }    if (selectedFilter.value === "read") {      params.is_read = true;    }    const response = await getNotifications(params);    notifications.value = response.data.data;  } catch (error) {    console.error("Failed to load notifications", error);  } finally {    loading.value = false;  }};const handleMarkAsRead = async (id) => {  await markNotificationAsRead(id);  await loadNotifications();};const handleMarkAllAsRead = async () => {  await markAllNotificationsAsRead();  await loadNotifications();};const handleDelete = async (id) => {  await deleteNotification(id);  await loadNotifications();};const severityClass = (severity) => {  if (severity === "danger") {    return "bg-red-100 text-red-700 border-red-200";  }  if (severity === "warning") {    return "bg-yellow-100 text-yellow-700 border-yellow-200";  }  if (severity === "success") {    return "bg-green-100 text-green-700 border-green-200";  }  return "bg-blue-100 text-blue-700 border-blue-200";};onMounted(() => {  loadNotifications();});</script><template>  <div class="p-8 space-y-8">    <div class="flex items-center justify-between">      <div>        <h1 class="text-3xl font-bold text-gray-900">Notifications</h1>        <p class="text-gray-500 mt-1">          Manage reminders, alerts, and system messages.        </p>      </div>      <button        @click="handleMarkAllAsRead"        class="px-4 py-2 rounded-xl bg-gray-900 text-white hover:bg-gray-800"      >        Mark All as Read      </button>    </div>    <div class="flex gap-3">      <button        @click="selectedFilter = 'all'; loadNotifications()"        class="px-4 py-2 rounded-xl border"        :class="selectedFilter === 'all' ? 'bg-gray-900 text-white' : 'bg-white'"      >        All      </button>      <button        @click="selectedFilter = 'unread'; loadNotifications()"        class="px-4 py-2 rounded-xl border"        :class="selectedFilter === 'unread' ? 'bg-gray-900 text-white' : 'bg-white'"      >        Unread      </button>      <button        @click="selectedFilter = 'read'; loadNotifications()"        class="px-4 py-2 rounded-xl border"        :class="selectedFilter === 'read' ? 'bg-gray-900 text-white' : 'bg-white'"      >        Read      </button>    </div>    <div v-if="loading" class="text-gray-500">      Loading notifications...    </div>    <div v-else class="space-y-4">      <div        v-for="notification in notifications"        :key="notification.id"        class="bg-white border rounded-2xl p-5 shadow-sm"        :class="notification.is_read ? 'opacity-70' : 'border-gray-300'"      >        <div class="flex items-start justify-between gap-4">          <div class="space-y-2">            <div class="flex items-center gap-3">              <span                class="px-3 py-1 rounded-full text-xs font-semibold border"                :class="severityClass(notification.severity)"              >                {{ notification.severity }}              </span>              <span class="text-xs text-gray-400 uppercase">                {{ notification.notification_type }}              </span>              <span                v-if="!notification.is_read"                class="w-2 h-2 rounded-full bg-blue-600"              ></span>            </div>            <h2 class="text-lg font-bold text-gray-900">              {{ notification.title }}            </h2>            <p class="text-gray-600">              {{ notification.message }}            </p>            <p class="text-xs text-gray-400">              {{ new Date(notification.created_at).toLocaleString() }}            </p>          </div>          <div class="flex gap-2">            <button              v-if="!notification.is_read"              @click="handleMarkAsRead(notification.id)"              class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 hover:bg-blue-100 text-sm"            >              Read            </button>            <button              @click="handleDelete(notification.id)"              class="px-3 py-2 rounded-xl bg-red-50 text-red-700 hover:bg-red-100 text-sm"            >              Delete            </button>          </div>        </div>      </div>      <div        v-if="notifications.length === 0"        class="bg-white rounded-2xl border p-8 text-center text-gray-500"      >        No notifications found.      </div>    </div>  </div></template>

14. Notification Settings Page
Create:
nano src/views/notifications/NotificationSettingsView.vue
Add:
<script setup>import { onMounted, ref } from "vue";import {  getNotificationPreferences,  updateNotificationPreferences,} from "../../api/notifications";const loading = ref(false);const saving = ref(false);const form = ref({  meal_reminders_enabled: true,  breakfast_time: "08:00",  lunch_time: "13:00",  dinner_time: "19:00",  weight_reminders_enabled: true,  weight_reminder_time: "08:30",  expense_reminders_enabled: true,  expense_reminder_time: "21:00",  finance_alerts_enabled: true,  health_alerts_enabled: true,  life_balance_alerts_enabled: true,  daily_expense_warning_limit: 50,  life_balance_warning_score: 60,});const loadPreferences = async () => {  loading.value = true;  try {    const response = await getNotificationPreferences();    form.value = {      ...form.value,      ...response.data,    };  } catch (error) {    console.error("Failed to load preferences", error);  } finally {    loading.value = false;  }};const savePreferences = async () => {  saving.value = true;  try {    await updateNotificationPreferences(form.value);    alert("Notification settings saved successfully.");  } catch (error) {    console.error("Failed to save preferences", error);    alert("Failed to save settings.");  } finally {    saving.value = false;  }};onMounted(() => {  loadPreferences();});</script><template>  <div class="p-8 space-y-8">    <div>      <h1 class="text-3xl font-bold text-gray-900">Notification Settings</h1>      <p class="text-gray-500 mt-1">        Configure reminders and alert rules.      </p>    </div>    <div v-if="loading" class="text-gray-500">      Loading settings...    </div>    <form v-else @submit.prevent="savePreferences" class="space-y-6">      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">        <h2 class="text-xl font-bold text-gray-900">Meal Reminders</h2>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.meal_reminders_enabled" />          <span>Enable meal reminders</span>        </label>        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">          <div>            <label class="text-sm text-gray-500">Breakfast Time</label>            <input              type="time"              v-model="form.breakfast_time"              class="w-full mt-1 border rounded-xl px-4 py-2"            />          </div>          <div>            <label class="text-sm text-gray-500">Lunch Time</label>            <input              type="time"              v-model="form.lunch_time"              class="w-full mt-1 border rounded-xl px-4 py-2"            />          </div>          <div>            <label class="text-sm text-gray-500">Dinner Time</label>            <input              type="time"              v-model="form.dinner_time"              class="w-full mt-1 border rounded-xl px-4 py-2"            />          </div>        </div>      </section>      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">        <h2 class="text-xl font-bold text-gray-900">Weight Reminder</h2>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.weight_reminders_enabled" />          <span>Enable weight reminder</span>        </label>        <div>          <label class="text-sm text-gray-500">Reminder Time</label>          <input            type="time"            v-model="form.weight_reminder_time"            class="w-full mt-1 border rounded-xl px-4 py-2"          />        </div>      </section>      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">        <h2 class="text-xl font-bold text-gray-900">Expense Reminder</h2>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.expense_reminders_enabled" />          <span>Enable expense reminder</span>        </label>        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">          <div>            <label class="text-sm text-gray-500">Reminder Time</label>            <input              type="time"              v-model="form.expense_reminder_time"              class="w-full mt-1 border rounded-xl px-4 py-2"            />          </div>          <div>            <label class="text-sm text-gray-500">Daily Expense Warning Limit</label>            <input              type="number"              v-model="form.daily_expense_warning_limit"              class="w-full mt-1 border rounded-xl px-4 py-2"            />          </div>        </div>      </section>      <section class="bg-white border rounded-2xl p-6 shadow-sm space-y-4">        <h2 class="text-xl font-bold text-gray-900">Smart Alerts</h2>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.finance_alerts_enabled" />          <span>Enable finance alerts</span>        </label>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.health_alerts_enabled" />          <span>Enable health alerts</span>        </label>        <label class="flex items-center gap-3">          <input type="checkbox" v-model="form.life_balance_alerts_enabled" />          <span>Enable Life Balance alerts</span>        </label>        <div>          <label class="text-sm text-gray-500">Life Balance Warning Score</label>          <input            type="number"            min="0"            max="100"            v-model="form.life_balance_warning_score"            class="w-full mt-1 border rounded-xl px-4 py-2"          />        </div>      </section>      <button        type="submit"        class="px-6 py-3 rounded-xl bg-gray-900 text-white hover:bg-gray-800"        :disabled="saving"      >        {{ saving ? "Saving..." : "Save Settings" }}      </button>    </form>  </div></template>

15. Notification Bell Component
Create:
mkdir -p src/components/notificationsnano src/components/notifications/NotificationBell.vue
Add:
<script setup>import { onMounted, ref } from "vue";import { RouterLink } from "vue-router";import { getUnreadNotificationCount } from "../../api/notifications";const unreadCount = ref(0);const loadUnreadCount = async () => {  try {    const response = await getUnreadNotificationCount();    unreadCount.value = response.data.unread_count;  } catch (error) {    console.error("Failed to load unread notification count", error);  }};onMounted(() => {  loadUnreadCount();  setInterval(() => {    loadUnreadCount();  }, 60000);});</script><template>  <RouterLink    to="/notifications"    class="relative inline-flex items-center justify-center w-11 h-11 rounded-xl bg-white border hover:bg-gray-50"  >    <span class="text-xl">🔔</span>    <span      v-if="unreadCount > 0"      class="absolute -top-1 -right-1 min-w-5 h-5 px-1 rounded-full bg-red-600 text-white text-xs flex items-center justify-center"    >      {{ unreadCount }}    </span>  </RouterLink></template>

16. Frontend Router Update
Open:
src/router/index.js
Add imports:
import NotificationsView from "../views/notifications/NotificationsView.vue";import NotificationSettingsView from "../views/notifications/NotificationSettingsView.vue";
Add routes:
{  path: "/notifications",  name: "notifications",  component: NotificationsView,},{  path: "/notifications/settings",  name: "notification-settings",  component: NotificationSettingsView,},
Example:
const routes = [  {    path: "/notifications",    name: "notifications",    component: NotificationsView,  },  {    path: "/notifications/settings",    name: "notification-settings",    component: NotificationSettingsView,  },];

17. Update App.vue Sidebar
Open:
src/App.vue
Add notification links inside your sidebar:
<RouterLink  to="/notifications"  class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100">  Notifications</RouterLink><RouterLink  to="/notifications/settings"  class="block rounded-xl px-4 py-2 text-gray-700 hover:bg-gray-100">  Notification Settings</RouterLink>
If you want the notification bell in the top-right area, import it:
<script setup>import { RouterLink, RouterView } from "vue-router";import NotificationBell from "./components/notifications/NotificationBell.vue";</script>
Then place it in the header:
<header class="flex items-center justify-between mb-6">  <div>    <h2 class="text-xl font-bold text-gray-900">Dashboard</h2>  </div>  <NotificationBell /></header>

18. Quick Manual Test Notification
To quickly insert a notification without waiting for scheduler, run:
php artisan tinker
Then:
\App\Models\LifeNotification::create([    'user_id' => '019d7c17-adcf-713f-b853-328a2fb65e57',    'notification_type' => 'system_alert',    'title' => 'Test Notification',    'message' => 'This is a test notification from NIX LIFE OS.',    'severity' => 'info',    'source_module' => 'system',    'metadata' => ['test' => true],    'triggered_at' => now(),]);
Then test:
curl http://127.0.0.1:8000/api/v1/notifications \  -H "Accept: application/json" \  -H "Authorization: Bearer $TOKEN"

19. Common Fixes
Problem: Route not found
Run:
php artisan route:clearphp artisan config:clearphp artisan cache:clearphp artisan route:list | grep notifications

Problem: UUID foreign key error
Do not use:
$table->foreignId('user_id');
Use:
$table->uuid('user_id');
Because your project uses UUID user IDs.

Problem: Command not visible
Run:
php artisan optimize:clearphp artisan list | grep notifications

Problem: Scheduler not running
Make sure cron exists:
crontab -e
Add:
* * * * * cd /u01/nix-life-os/backend && php artisan schedule:run >> /dev/null 2>&1
Check schedule:
php artisan schedule:list

20. Final Step 21 Checklist
You should now have:
Backend✅ life_notifications table✅ notification_preferences table✅ LifeNotification model✅ NotificationPreference model✅ NotificationService✅ NotificationController✅ NotificationPreferenceController✅ API routes✅ Reminder commands✅ Alert commands✅ Laravel scheduler integrationFrontend✅ notifications.js API file✅ NotificationsView.vue✅ NotificationSettingsView.vue✅ NotificationBell.vue✅ Router links✅ Sidebar links

Recommended Next Step
After Step 21, the best next module is:
🔹 STEP 22 — AI Recommendation Engine
Build personalized recommendations from:
Finance scoreHealth scoreProductivity scoreLife Balance IndexNotificationsDaily insights
Example output:
"Your expenses are higher than usual this week.""You skipped weight tracking for 3 days.""Your Life Balance score dropped because health activity is low.""Recommended action: walk 20 minutes today and reduce non-essential spending."